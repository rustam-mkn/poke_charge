#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/ps/IOPowerSources.h>

#include <errno.h>
#include <signal.h>
#include <spawn.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

extern char **environ;

typedef enum {
    POWER_UNKNOWN = 0,
    POWER_BATTERY,
    POWER_AC,
    POWER_UPS
} PowerState;

typedef struct {
    PowerState previous_state;
    const char *action_path;
} MonitorContext;

static volatile sig_atomic_t g_action_running = 0;
static volatile sig_atomic_t g_action_pid = 0;

static const char *state_name(PowerState state) {
    switch (state) {
        case POWER_BATTERY:
            return "battery";
        case POWER_AC:
            return "ac";
        case POWER_UPS:
            return "ups";
        case POWER_UNKNOWN:
        default:
            return "unknown";
    }
}

static void log_message(const char *format, ...) {
    time_t now = time(NULL);
    struct tm local_time;
    char timestamp[32] = "unknown-time";

    if (localtime_r(&now, &local_time) != NULL) {
        strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", &local_time);
    }

    fprintf(stdout, "[%s] ", timestamp);

    va_list args;
    va_start(args, format);
    vfprintf(stdout, format, args);
    va_end(args);

    fputc('\n', stdout);
    fflush(stdout);
}

static PowerState read_power_state(void) {
    CFTypeRef snapshot = IOPSCopyPowerSourcesInfo();
    if (snapshot == NULL) {
        return POWER_UNKNOWN;
    }

    CFStringRef source_type = IOPSGetProvidingPowerSourceType(snapshot);
    PowerState state = POWER_UNKNOWN;

    if (source_type != NULL) {
        if (CFStringCompare(source_type, CFSTR(kIOPMACPowerKey), 0) == kCFCompareEqualTo) {
            state = POWER_AC;
        } else if (CFStringCompare(source_type, CFSTR(kIOPMBatteryPowerKey), 0) == kCFCompareEqualTo) {
            state = POWER_BATTERY;
        } else if (CFStringCompare(source_type, CFSTR(kIOPMUPSPowerKey), 0) == kCFCompareEqualTo) {
            state = POWER_UPS;
        }
    }

    CFRelease(snapshot);
    return state;
}

static void reap_action(int signal_number) {
    (void)signal_number;

    int saved_errno = errno;
    pid_t pid;

    while ((pid = waitpid(-1, NULL, WNOHANG)) > 0) {
        if ((sig_atomic_t)pid == g_action_pid) {
            g_action_pid = 0;
            g_action_running = 0;
        }
    }

    errno = saved_errno;
}

static int install_signal_handlers(void) {
    struct sigaction action;
    memset(&action, 0, sizeof(action));
    action.sa_handler = reap_action;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_RESTART;

    if (sigaction(SIGCHLD, &action, NULL) != 0) {
        fprintf(stderr, "failed to install SIGCHLD handler: %s\n", strerror(errno));
        return 1;
    }

    return 0;
}

static void start_action(const char *action_path) {
    if (g_action_running) {
        log_message("action is still running; skipping duplicate trigger");
        return;
    }

    if (access(action_path, X_OK) != 0) {
        log_message("action is not executable: %s (%s)", action_path, strerror(errno));
        return;
    }

    sigset_t blocked_signals;
    sigset_t previous_signals;
    sigemptyset(&blocked_signals);
    sigaddset(&blocked_signals, SIGCHLD);

    if (sigprocmask(SIG_BLOCK, &blocked_signals, &previous_signals) != 0) {
        log_message("failed to block SIGCHLD before spawning action: %s", strerror(errno));
        return;
    }

    pid_t pid = 0;
    char *const argv[] = {(char *)action_path, NULL};
    int spawn_status = posix_spawn(&pid, action_path, NULL, NULL, argv, environ);

    if (spawn_status == 0) {
        g_action_pid = (sig_atomic_t)pid;
        g_action_running = 1;
        log_message("started action: %s (pid %ld)", action_path, (long)pid);
    } else {
        log_message("failed to start action: %s (%s)", action_path, strerror(spawn_status));
    }

    if (sigprocmask(SIG_SETMASK, &previous_signals, NULL) != 0) {
        log_message("failed to restore signal mask after spawning action: %s", strerror(errno));
    }
}

static void handle_power_change(void *context) {
    MonitorContext *monitor = context;
    PowerState current_state = read_power_state();

    if (current_state == POWER_UNKNOWN) {
        log_message("power state changed but current state is unknown; previous state remains %s",
                    state_name(monitor->previous_state));
        return;
    }

    if (current_state != monitor->previous_state) {
        log_message("power state: %s -> %s",
                    state_name(monitor->previous_state),
                    state_name(current_state));
    }

    if (current_state == POWER_AC &&
        monitor->previous_state != POWER_AC &&
        monitor->previous_state != POWER_UNKNOWN) {
        start_action(monitor->action_path);
    }

    monitor->previous_state = current_state;
}

static void print_usage(FILE *stream, const char *program_name) {
    fprintf(stream,
            "Usage:\n"
            "  %s --once\n"
            "  %s --action /absolute/path/to/play_gif_and_sound.sh\n",
            program_name,
            program_name);
}

int main(int argc, char **argv) {
    bool once = false;
    const char *action_path = NULL;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--once") == 0) {
            once = true;
        } else if (strcmp(argv[i], "--action") == 0) {
            if (i + 1 >= argc) {
                print_usage(stderr, argv[0]);
                return 64;
            }
            action_path = argv[++i];
        } else if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            print_usage(stdout, argv[0]);
            return 0;
        } else {
            fprintf(stderr, "unknown argument: %s\n", argv[i]);
            print_usage(stderr, argv[0]);
            return 64;
        }
    }

    if (once) {
        PowerState state = read_power_state();
        puts(state_name(state));
        return state == POWER_UNKNOWN ? 2 : 0;
    }

    if (action_path == NULL) {
        print_usage(stderr, argv[0]);
        return 64;
    }

    if (install_signal_handlers() != 0) {
        return 1;
    }

    MonitorContext context = {
        .previous_state = read_power_state(),
        .action_path = action_path,
    };

    log_message("monitor started; initial power state is %s; action is %s",
                state_name(context.previous_state),
                action_path);

    CFRunLoopSourceRef source = IOPSNotificationCreateRunLoopSource(handle_power_change, &context);
    if (source == NULL) {
        fprintf(stderr, "failed to create IOKit power-source notification source\n");
        return 1;
    }

    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    CFRelease(source);

    CFRunLoopRun();
    log_message("monitor stopped");
    return 0;
}
