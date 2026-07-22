# kitty

Terminal config. **Generic — works in kitty on any OS**, not tied to Hyprland
or Arch.

## Use standalone
Copy `kitty.conf` to `~/.config/kitty/kitty.conf`.

The one integration line is:
```
include generated/theme.conf
```
That file is written by the [`themes`](../../themes) engine (colors + ANSI
palette + font size). For standalone use without the theme engine, either:
- remove that `include` line and set your own colors, or
- drop any kitty color theme at `~/.config/kitty/generated/theme.conf`.

Reload a running kitty after changes: `kill -SIGUSR1 $(pgrep kitty)` (the theme
engine does this for you).
