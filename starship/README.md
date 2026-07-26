# starship

Powerlevel10k-style prompt config — **generic, works with any shell on any
distro**. The repo installer initializes it for Zsh.

Copy `starship.toml` to `~/.config/starship.toml` and initialise starship in
your shell:
- bash: `eval "$(starship init bash)"` in `~/.bashrc`.
- zsh:  `eval "$(starship init zsh)"` in `~/.zshrc`.

The `[palettes.theme]` block is a static managed palette. The terminal installer
never invokes a theme engine or rewrites this file.
