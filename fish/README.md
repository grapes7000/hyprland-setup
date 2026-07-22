# fish

A one-line PATH snippet — **generic, any distro**.

Append `config.fish`'s contents to your `~/.config/fish/config.fish` so the
helper commands (`theme`, `wallgen`, `shortcuts`) in `~/.local/bin` are found:
```fish
fish_add_path -g ~/.local/bin
```
(For bash/zsh the equivalent is `export PATH="$HOME/.local/bin:$PATH"`.)
