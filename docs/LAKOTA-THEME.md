# Lakota theme adapter

`bin/lakota-hypr-theme` is the only Hyprland-specific consumer of
`~/.config/theme-engine/generated/theme.json`. On this Caelestia installation
it generates `~/.config/hypr/generated/lakota-theme.lua` using the installed
Hyprland version and adds one marked `dofile` block to
`~/.config/caelestia/hypr-user.lua`.

Run `lakota-hypr-theme install` once, then `lakota-hypr-theme apply` after a
theme change. Both generation and integration are idempotent. `disable` removes
only the marked integration block. Every changed external config gets a sibling
`.bak-lakota-<timestamp>` copy first.

The adapter owns only window borders, gaps, rounding, opacity, blur, and shadow.
It does not alter monitors, input, keybinds, rules, or startup behavior.
