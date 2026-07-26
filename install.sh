#!/usr/bin/env bash
# Symlink the Hyprland desktop config into ~/.config (and bin into ~/.local/bin).
# Re-runnable. Backs up anything it would overwrite to <target>.bak-<timestamp>.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
THEMES_DIR="${THEMES_DIR:-$HOME/themes}"
THEMES_REPO="${THEMES_REPO:-https://github.com/grapes7000/themes.git}"
DEFAULT_THEME="${HYPRLAND_THEME:-catppuccin_mocha}"
ts="$(date +%s)"

link() {  # link <src> <dest>
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    [ -e "$dest" ] && [ ! -L "$dest" ] && mv "$dest" "$dest.bak-$ts" && echo "  backed up $dest"
    ln -sfn "$src" "$dest"
    echo "  linked $dest"
}

ensure_shell_path() {
    local file="$1" line='export PATH="$HOME/.local/bin:$PATH"'
    touch "$file"
    grep -Fqx "$line" "$file" || printf '\n%s\n' "$line" >> "$file"
}

enable_theme_target() {
    local target="$1" targets="$CFG/theme-engine/targets.conf"
    if grep -Eq "^[[:space:]]*#[[:space:]]*$target[[:space:]]*$" "$targets"; then
        sed -i -E "s|^[[:space:]]*#[[:space:]]*$target[[:space:]]*$|$target|" "$targets"
    elif ! grep -Eq "^[[:space:]]*$target[[:space:]]*$" "$targets"; then
        printf '%s\n' "$target" >> "$targets"
    fi
}

echo "Installing hyprland-setup from $REPO"
link "$REPO/hypr"           "$CFG/hypr"
link "$REPO/nvim"           "$CFG/nvim"
link "$REPO/waybar"         "$CFG/waybar"
link "$REPO/kitty/kitty.conf" "$CFG/kitty/kitty.conf"
link "$REPO/starship/starship.toml" "$CFG/starship.toml"
mkdir -p "$HOME/.local/bin"
install -m755 "$REPO/bin/shortcuts" "$HOME/.local/bin/shortcuts"
echo "  installed shortcuts -> ~/.local/bin"

ensure_shell_path "$HOME/.zshrc"
ensure_shell_path "$HOME/.bashrc"
if [ -d "$CFG/fish" ] && ! grep -q '.local/bin' "$CFG/fish/config.fish" 2>/dev/null; then
    echo 'fish_add_path -g ~/.local/bin' >> "$CFG/fish/config.fish"
    echo 'starship init fish | source' >> "$CFG/fish/config.fish"
fi
echo "  ensured ~/.local/bin is on PATH for zsh and bash"

if [ ! -x "$THEMES_DIR/install.sh" ]; then
    echo "Cloning theme engine into $THEMES_DIR"
    git clone "$THEMES_REPO" "$THEMES_DIR"
fi

"$THEMES_DIR/install.sh"
for target in hypr waybar kitty starship nvim wallpaper wofi dunst hyprlock; do
    enable_theme_target "$target"
done
"$HOME/.local/bin/theme" "$DEFAULT_THEME"
echo "Done. Applied theme: $DEFAULT_THEME"
