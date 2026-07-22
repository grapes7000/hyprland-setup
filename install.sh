#!/usr/bin/env bash
# Symlink the Hyprland desktop config into ~/.config (and bin into ~/.local/bin).
# Re-runnable. Backs up anything it would overwrite to <target>.bak-<timestamp>.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
ts="$(date +%s)"

link() {  # link <src> <dest>
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    [ -e "$dest" ] && [ ! -L "$dest" ] && mv "$dest" "$dest.bak-$ts" && echo "  backed up $dest"
    ln -sfn "$src" "$dest"
    echo "  linked $dest"
}

echo "Installing hyprland-setup from $REPO"
link "$REPO/hypr"           "$CFG/hypr"
link "$REPO/waybar"         "$CFG/waybar"
link "$REPO/kitty/kitty.conf" "$CFG/kitty/kitty.conf"
link "$REPO/starship/starship.toml" "$CFG/starship.toml"
mkdir -p "$HOME/.local/bin"
install -m755 "$REPO/bin/shortcuts" "$HOME/.local/bin/shortcuts"
echo "  installed shortcuts -> ~/.local/bin"

# fish PATH
if [ -d "$CFG/fish" ] && ! grep -q '.local/bin' "$CFG/fish/config.fish" 2>/dev/null; then
    echo 'fish_add_path -g ~/.local/bin' >> "$CFG/fish/config.fish"
    echo "  added ~/.local/bin to fish PATH"
fi

# offer to clone the themes engine
if [ ! -d "$CFG/hypr/themes" ] && [ ! -d "$HOME/themes" ]; then
    echo
    echo "The theme engine (colors/wallpapers) lives in the separate 'themes' repo."
    echo "Clone it, then run: cd ~/themes && ./install.sh && theme catppuccin_mocha"
fi
echo "Done. Log into Hyprland, then run: theme <name>"
