#!/usr/bin/env bash
# Waybar launcher shared with Theme Studio.
# Generated config is preferred; the hand-authored config remains a safe fallback.
set -u
WAYBAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
CONFIG="$WAYBAR_DIR/config.jsonc"
STYLE="$WAYBAR_DIR/style.css"

if [ -s "$WAYBAR_DIR/generated/config.jsonc" ]; then
    CONFIG="$WAYBAR_DIR/generated/config.jsonc"
fi

exec waybar -c "$CONFIG" -s "$STYLE"
