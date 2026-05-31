#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

GIF_PATH="${POKE_CHARGE_GIF:-$SCRIPT_DIR/qwe.gif}"
SOUND_PATH="${POKE_CHARGE_SOUND:-$SCRIPT_DIR/the-microsoft-sound.mp3}"
PREVIEW_SECONDS="${POKE_CHARGE_PREVIEW_SECONDS:-5}"

preview_pid=""
sound_pid=""
timer_pid=""

fail() {
    printf 'poke-charge action: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    if [[ -n "$timer_pid" ]] && kill -0 "$timer_pid" 2>/dev/null; then
        kill "$timer_pid" 2>/dev/null || true
        wait "$timer_pid" 2>/dev/null || true
    fi

    if [[ -n "$sound_pid" ]] && kill -0 "$sound_pid" 2>/dev/null; then
        kill "$sound_pid" 2>/dev/null || true
        wait "$sound_pid" 2>/dev/null || true
    fi

    if [[ -n "$preview_pid" ]] && kill -0 "$preview_pid" 2>/dev/null; then
        kill "$preview_pid" 2>/dev/null || true
        wait "$preview_pid" 2>/dev/null || true
    fi
}

trap cleanup EXIT
trap 'trap - EXIT; cleanup; exit 130' INT
trap 'trap - EXIT; cleanup; exit 143' TERM

[[ -f "$GIF_PATH" ]] || fail "GIF not found: $GIF_PATH"
[[ -f "$SOUND_PATH" ]] || fail "sound not found: $SOUND_PATH"
command -v qlmanage >/dev/null 2>&1 || fail "qlmanage is not available"
command -v afplay >/dev/null 2>&1 || fail "afplay is not available"

qlmanage -p "$GIF_PATH" >/dev/null 2>&1 &
preview_pid="$!"

afplay "$SOUND_PATH" &
sound_pid="$!"

sleep "$PREVIEW_SECONDS" &
timer_pid="$!"

wait "$sound_pid"
sound_pid=""

wait "$timer_pid"
timer_pid=""
