# Theme Studio ↔ Waybar contract

The `themes` repository owns palette and editable Waybar component data. This repository owns the stable Waybar module definitions, scripts, and fallback layout.

## Startup

Hyprland starts:

```bash
bash ~/.config/waybar/launch.sh
```

The launcher chooses:

1. `~/.config/waybar/generated/config.jsonc` when Theme Studio has generated one.
2. `~/.config/waybar/config.jsonc` as the safe fallback.

It always loads `~/.config/waybar/style.css`.

## CSS layers

`style.css` imports:

```css
@import "generated/theme.css";
@import "generated/component.css";
```

- `theme.css` contains semantic palette roles.
- `component.css` contains geometry, spacing, layout, per-state workspace styles, and optional per-module overrides.
- The remainder of `style.css` contains stable semantic behavior for audio, network, battery, notifications, VPN, system stats, and the tray.

The tracked `generated/component.css` is a safe fallback. Theme Studio replaces it at runtime.

## Generated files

Theme Studio writes only inside the existing generated directory:

```text
waybar/generated/config.jsonc
waybar/generated/theme.css
waybar/generated/component.css
```

The hand-authored `config.jsonc`, scripts, and semantic state rules remain intact.

## Live reload

Normal changes use:

```bash
pkill -USR2 -x waybar
```

If the selected config path changes, Theme Studio restarts Waybar through `launch.sh`.

## Module ownership

Theme Studio may enable, disable, reorder, or move module names between `modules-left`, `modules-center`, and `modules-right`. This repo remains responsible for the actual module definitions and custom scripts.

Unknown modules are preserved but surfaced as validation suggestions.
