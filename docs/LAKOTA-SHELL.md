# Lakota Shell behavior integration

`hypr/lakota-shell.lua` owns Hyprland behavior needed by Lakota Shell without
changing Caelestia's installed configuration. The active user extension loads
this module through one marked `dofile` block.

The initial integration binds `SUPER + SPACE` to the targeted Quickshell IPC
command `qs -c lakota-shell ipc call launcher toggle`. It does not kill or
message other Quickshell configurations.

To disable it, remove only the block between `BEGIN LAKOTA SHELL BEHAVIOR` and
`END LAKOTA SHELL BEHAVIOR` from `~/.config/caelestia/hypr-user.lua`, then run
`hyprctl reload`. The pre-integration file is retained beside it with a
`.bak-lakota-<timestamp>` suffix.
