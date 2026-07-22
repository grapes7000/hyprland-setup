# starship

Prompt config — **generic, works with any shell (fish/bash/zsh) on any distro**.

Copy `starship.toml` to `~/.config/starship.toml` and ensure starship is
initialised in your shell (e.g. fish: `starship init fish | source`).

The `[palettes.theme]` block is **rewritten by the [`themes`](../../themes)
engine** on every `theme <name>` switch, so the prompt always matches your
desktop. Standalone, it's just a normal starship config — edit the palette by
hand or swap in your own.
