CC ?= clang
CFLAGS ?= -std=c17 -Wall -Wextra -Wpedantic -O2
FRAMEWORKS := -framework CoreFoundation -framework IOKit

LABEL := com.user.chargeSoundAndGif
BUILD_DIR := build
SRC := src/poke_charge_monitor.c
BIN := $(BUILD_DIR)/poke-charge-monitor
ACTION_SCRIPT := $(abspath play_gif_and_sound.sh)
LAUNCH_AGENT := $(HOME)/Library/LaunchAgents/$(LABEL).plist
LOG_PATH := $(HOME)/Library/Logs/poke_charge.log
USER_ID := $(shell id -u)

.PHONY: all check clean install uninstall

all: $(BIN)

$(BIN): $(SRC) | $(BUILD_DIR)
	$(CC) $(CFLAGS) $< $(FRAMEWORKS) -o $@

$(BUILD_DIR):
	mkdir -p $@

check: $(BIN)
	$(BIN) --once
	plutil -lint com.user.chargeSoundAndGif.plist

install: $(BIN)
	@mkdir -p "$(dir $(LAUNCH_AGENT))" "$(HOME)/Library/Logs"
	@bin_path="$(abspath $(BIN))"; \
	action_path="$(ACTION_SCRIPT)"; \
	log_path="$(LOG_PATH)"; \
	plist_path="$(LAUNCH_AGENT)"; \
	label="$(LABEL)"; \
	escape_xml() { printf '%s' "$$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }; \
	bin_xml=$$(escape_xml "$$bin_path"); \
	action_xml=$$(escape_xml "$$action_path"); \
	log_xml=$$(escape_xml "$$log_path"); \
	label_xml=$$(escape_xml "$$label"); \
	{ \
		printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>'; \
		printf '%s\n' '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'; \
		printf '%s\n' '<plist version="1.0">'; \
		printf '%s\n' '<dict>'; \
		printf '%s\n' '    <key>Label</key>'; \
		printf '%s\n' "    <string>$$label_xml</string>"; \
		printf '%s\n' '    <key>ProgramArguments</key>'; \
		printf '%s\n' '    <array>'; \
		printf '%s\n' "        <string>$$bin_xml</string>"; \
		printf '%s\n' '        <string>--action</string>'; \
		printf '%s\n' "        <string>$$action_xml</string>"; \
		printf '%s\n' '    </array>'; \
		printf '%s\n' '    <key>RunAtLoad</key>'; \
		printf '%s\n' '    <true/>'; \
		printf '%s\n' '    <key>KeepAlive</key>'; \
		printf '%s\n' '    <true/>'; \
		printf '%s\n' '    <key>StandardOutPath</key>'; \
		printf '%s\n' "    <string>$$log_xml</string>"; \
		printf '%s\n' '    <key>StandardErrorPath</key>'; \
		printf '%s\n' "    <string>$$log_xml</string>"; \
		printf '%s\n' '</dict>'; \
		printf '%s\n' '</plist>'; \
	} > "$$plist_path"
	@plutil -lint "$(LAUNCH_AGENT)"
	@launchctl bootout "gui/$(USER_ID)/$(LABEL)" >/dev/null 2>&1 || true
	@launchctl bootstrap "gui/$(USER_ID)" "$(LAUNCH_AGENT)"
	@launchctl kickstart -k "gui/$(USER_ID)/$(LABEL)"
	@echo "Installed and started $(LABEL)"

uninstall:
	@launchctl bootout "gui/$(USER_ID)/$(LABEL)" >/dev/null 2>&1 || true
	@rm -f "$(LAUNCH_AGENT)"
	@echo "Uninstalled $(LABEL)"

clean:
	rm -rf "$(BUILD_DIR)"
