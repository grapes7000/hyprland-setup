# starship

Prompt config — **generic, works with any shell (fish/bash/zsh) on any distro**.

Copy `starship.toml` to `~/.config/starship.toml` and initialise starship in
your shell:
- fish: add `starship init fish | source` to `~/.config/fish/config.fish`
  (AFTER any distro config that sets its own prompt, or it won't take effect).
- bash: `eval "$(starship init bash)"` in `~/.bashrc`.
- zsh:  `eval "$(starship init zsh)"` in `~/.zshrc`.

The `[palettes.theme]` block + character colors are **rewritten by the
[`themes`](../../themes) engine** on every `theme <name>` switch, so the prompt
always matches your desktop. Standalone, it's a normal starship config.
