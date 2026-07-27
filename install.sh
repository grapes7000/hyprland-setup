#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/hyprland-setup"
DRY_RUN=false
ASSUME_YES=false
DESKTOP=false
STATE_DIR=""

terminal_packages=(
    zsh kitty starship oh-my-zsh-git zsh-autosuggestions zsh-syntax-highlighting
    fzf ripgrep fd bat eza thefuck zoxide direnv yazi jq tldr
    git curl unzip ttf-jetbrains-mono-nerd
)
legacy_packages=(cachyos-fish-config fish cachyos-zsh-config zsh-theme-powerlevel10k)

usage() {
    cat <<'EOF'
Usage: ./install.sh [--dry-run] [--yes] [--desktop]

Install the managed terminal profile. By default this only owns Kitty,
Starship, Zsh, ~/.local/bin/shortcuts, and the legacy Fish/Powerlevel10k
archives. --desktop additionally links Hyprland, Waybar, and Neovim, and
installs the workspace-switcher and power-menu helpers used by Hyprland.

--dry-run  Print the complete plan without writing or running package commands.
--yes      Apply without the interactive confirmation.
--desktop  Explicitly opt in to linking ~/.config/hypr, waybar, and nvim.
EOF
}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
run() {
    if "$DRY_RUN"; then
        printf '  would run:'; printf ' %q' "$@"; printf '\n'
    else
        "$@"
    fi
}

target_exists() { [ -e "$1" ] || [ -L "$1" ]; }
same_link() { [ -L "$2" ] && [ "$(readlink -f "$2")" = "$(readlink -f "$1")" ]; }

record() {
    "$DRY_RUN" && return 0
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$STATE_DIR/manifest.tsv"
}
ensure_state_dir() {
    [ -n "$STATE_DIR" ] && return
    STATE_DIR="$STATE_ROOT/install-$(date +%Y%m%d-%H%M%S)-$$"
    if "$DRY_RUN"; then
        printf '  would create state directory %s\n' "$STATE_DIR"
    else
        mkdir -p "$STATE_DIR/backups"
        printf '# action\ttarget\tbackup\n' > "$STATE_DIR/manifest.tsv"
    fi
}

archive() {
    local target="$1" backup
    target_exists "$target" || return 0
    ensure_state_dir
    backup="$STATE_DIR/backups/${target#"$HOME"/}"
    if "$DRY_RUN"; then
        printf '  would archive %s -> %s\n' "$target" "$backup"
        return
    fi
    mkdir -p "$(dirname "$backup")"
    mv "$target" "$backup"
    record archive "$target" "$backup"
    printf '  archived %s\n' "$target"
}

link() {
    local source="$1" destination="$2"
    if same_link "$source" "$destination"; then
        printf '  unchanged %s\n' "$destination"
        return
    fi
    archive "$destination"
    if "$DRY_RUN"; then
        printf '  would link %s -> %s\n' "$destination" "$source"
    else
        mkdir -p "$(dirname "$destination")"
        ln -s "$source" "$destination"
        record link "$destination" "$source"
        printf '  linked %s\n' "$destination"
    fi
}

install_file() {
    local source="$1" destination="$2" mode="$3"
    if [ -f "$destination" ] && [ ! -L "$destination" ] && cmp -s "$source" "$destination"; then
        printf '  unchanged %s\n' "$destination"
        return
    fi
    archive "$destination"
    if "$DRY_RUN"; then
        printf '  would install %s -> %s\n' "$source" "$destination"
    else
        mkdir -p "$(dirname "$destination")"
        install -m "$mode" "$source" "$destination"
        record install "$destination" "$source"
        printf '  installed %s\n' "$destination"
    fi
}

package_is_installed() { pacman -Q "$1" >/dev/null 2>&1; }
packages_to_remove=()
preflight() {
    command -v pacman >/dev/null 2>&1 || die 'this installer supports Arch-based systems (pacman is required)'
    command -v chsh >/dev/null 2>&1 || die 'chsh is required to set the login shell'
    packages_to_remove=()
    local package
    for package in "${legacy_packages[@]}"; do
        package_is_installed "$package" && packages_to_remove+=("$package")
    done
}

print_plan() {
    cat <<EOF
Terminal-only installer plan
  terminal package install: ${terminal_packages[*]}
  legacy package removal: ${packages_to_remove[*]:-(none installed)}
  archive/replace: $HOME/.zshrc, $CFG/kitty/kitty.conf, $CFG/starship.toml,
                   $HOME/.local/bin/shortcuts, $CFG/fish, $HOME/.p10k.zsh
  login-shell action: chsh -s zsh (only if needed)
  state directory: $STATE_ROOT/install-<timestamp>-<pid>
  untouched by default: $HOME/.bashrc, $CFG/hypr, $CFG/waybar, $CFG/nvim,
                        theme-engine targets, theme repositories, Wofi, Dunst, Hyprlock
EOF
    if "$DESKTOP"; then
        printf '  desktop opt-in links: %s, %s, %s\n' "$CFG/hypr" "$CFG/waybar" "$CFG/nvim"
    fi
}

confirm() {
    "$ASSUME_YES" && return
    "$DRY_RUN" && return
    [ -t 0 ] || die 'refusing non-interactive apply without --yes'
    printf 'Apply this plan? [y/N] '
    local answer
    read -r answer
    [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]] || die 'cancelled'
}

manage_packages() {
    ensure_state_dir
    record package-install "${terminal_packages[*]}" 'sudo pacman -S --needed'
    run sudo pacman -S --needed "${terminal_packages[@]}"
    if ((${#packages_to_remove[@]})); then
        record package-remove "${packages_to_remove[*]}" 'sudo pacman -Rns'
        run sudo pacman -Rns "${packages_to_remove[@]}"
    fi
}

set_zsh_as_login_shell() {
    local zsh_bin
    zsh_bin="$(command -v zsh || printf /usr/bin/zsh)"
    if [ "${SHELL:-}" != "$zsh_bin" ]; then
        ensure_state_dir
        record login-shell "$zsh_bin" 'chsh -s'
        run chsh -s "$zsh_bin"
    else
        printf '  unchanged login shell %s\n' "$zsh_bin"
    fi
}

manage_terminal_files() {
    archive "$CFG/fish"
    archive "$HOME/.p10k.zsh"
    link "$REPO/zsh/.zshrc" "$HOME/.zshrc"
    install_file "$REPO/kitty/kitty.conf" "$CFG/kitty/kitty.conf" 0644
    if grep -q 'AUTO-GENERATED by `theme`' "$CFG/starship.toml" 2>/dev/null; then
        printf '  unchanged %s (managed by theme engine)\n' "$CFG/starship.toml"
    else
        install_file "$REPO/starship/starship.toml" "$CFG/starship.toml" 0644
    fi
    install_file "$REPO/bin/shortcuts" "$HOME/.local/bin/shortcuts" 0755
}

manage_desktop_files() {
    link "$REPO/hypr" "$CFG/hypr"
    link "$REPO/waybar" "$CFG/waybar"
    link "$REPO/nvim" "$CFG/nvim"
    # Generate hyprpaper.conf from template with real $HOME path
    if "$DRY_RUN"; then
        printf '  would generate %s (expand __HOME__ -> %s)\n' "$REPO/hypr/hyprpaper.conf" "$HOME"
    else
        sed "s|__HOME__|$HOME|g" "$REPO/hypr/hyprpaper.conf.tpl" > "$REPO/hypr/hyprpaper.conf"
        printf '  generated %s\n' "$REPO/hypr/hyprpaper.conf"
    fi
    install_file "$REPO/bin/workspace-switcher" "$CFG/bin/workspace-switcher" 0755
    install_file "$REPO/bin/power-menu" "$CFG/bin/power-menu" 0755
}

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        --yes) ASSUME_YES=true ;;
        --desktop) DESKTOP=true ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; die "unknown option: $1" ;;
    esac
    shift
done

preflight
print_plan
confirm
manage_packages
manage_terminal_files
"$DESKTOP" && manage_desktop_files
set_zsh_as_login_shell
if "$DRY_RUN"; then
    printf 'Dry run complete. No changes made.\n'
else
    printf 'Done. Backups and manifest: %s\n' "$STATE_DIR"
fi
