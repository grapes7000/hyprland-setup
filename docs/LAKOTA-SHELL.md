# Lakota Shell behavior integration

`hypr/lakota-shell.lua` owns Hyprland behavior needed by Lakota Shell without
changing Caelestia's installed configuration. The active user extension loads
this module through one marked `dofile` block.

The initial integration binds `SUPER + SPACE` to the targeted Quickshell IPC
command `qs -c lakota-shell ipc call launcher toggle`. It does not kill or
message other Quickshell configurations.

`hypr/lakota-monitor.lua` owns the VM-specific display override. It selects
`3840x2160@60` on the Virtio-GPU `Virtual-1` output at scale 2, producing a
sharp 4K framebuffer with a readable 1920x1080 logical desktop. The active user
extension loads it after the base monitor rule so the override remains in
effect after login and Hyprland restarts.

To disable it, remove only the block between `BEGIN LAKOTA SHELL BEHAVIOR` and
`END LAKOTA SHELL BEHAVIOR` from `~/.config/caelestia/hypr-user.lua`, then run
`hyprctl reload`. The pre-integration file is retained beside it with a
`.bak-lakota-<timestamp>` suffix.

To disable only the 4K override, remove the block between `BEGIN LAKOTA VM
MONITOR` and `END LAKOTA VM MONITOR` from the same user extension and reload
Hyprland.
