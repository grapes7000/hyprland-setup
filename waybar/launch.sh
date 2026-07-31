#!/usr/bin/env bash
# Waybar launcher shared with Theme Studio. Failures persist in a user log so
# a fresh desktop never leaves an unexplained empty top edge.
set -u
WAYBAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
CONFIG="$WAYBAR_DIR/config.jsonc"
STYLE="$WAYBAR_DIR/style.css"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprland-setup"
LOG="$STATE_DIR/waybar.log"
mkdir -p "$STATE_DIR"

if ! command -v waybar >/dev/null 2>&1; then
    printf '%s waybar: command not found\n' "$(date -Is)" >> "$LOG"
    exit 127
fi
if [ ! -s "$CONFIG" ] || [ ! -s "$STYLE" ]; then
    printf '%s waybar: missing config or stylesheet in %s\n' "$(date -Is)" "$WAYBAR_DIR" >> "$LOG"
    exit 1
fi

if [ -s "$WAYBAR_DIR/generated/config.jsonc" ]; then
    CONFIG="$WAYBAR_DIR/generated/config.jsonc"
fi

printf '%s waybar: starting with %s\n' "$(date -Is)" "$CONFIG" >> "$LOG"
waybar -c "$CONFIG" -s "$STYLE" >> "$LOG" 2>&1
status=$?

# A broken generated Theme Studio layout should not take down the whole bar.
if [ "$status" -ne 0 ] && [ "$CONFIG" != "$WAYBAR_DIR/config.jsonc" ]; then
    printf '%s waybar: generated config failed (%s); trying fallback\n' \
        "$(date -Is)" "$status" >> "$LOG"
    exec waybar -c "$WAYBAR_DIR/config.jsonc" -s "$STYLE" >> "$LOG" 2>&1
fi
exit "$status"
