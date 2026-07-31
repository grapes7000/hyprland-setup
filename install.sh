#!/usr/bin/env bash
set -euo pipefail

_src="${BASH_SOURCE[0]-}"
if [ -z "$_src" ] || [ ! -f "$_src" ]; then
    printf 'Downloading hyprland-setup...\n'
    _tmpdir="$(mktemp -d)"
    trap 'rm -rf "$_tmpdir"' EXIT
    git clone --depth 1 https://github.com/grapes7000/hyprland-setup.git "$_tmpdir/hyprland-setup"
    bash "$_tmpdir/hyprland-setup/install.sh" "$@"
    exit $?
fi

REPO="$(cd "$(dirname "$_src")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/hyprland-setup"
DRY_RUN=false
ASSUME_YES=false
DESKTOP=false
STATE_DIR=""
DISTRO=""
PKG_MGR=""

# ── Package lists (Arch names as canonical keys) ─────────────────────────

terminal_packages_base=(
    zsh kitty starship oh-my-zsh-git zsh-autosuggestions zsh-syntax-highlighting
    fzf ripgrep fd bat eza thefuck zoxide direnv yazi jq tldr
    git curl unzip ttf-jetbrains-mono-nerd neovim
)
desktop_packages_base=(
    hyprland waybar eww wofi hyprpaper hyprlock hypridle
    xdg-desktop-portal-hyprland polkit-kde-agent qt5-wayland qt6-wayland
    grim slurp wl-clipboard brightnessctl playerctl pamixer python-pillow
    dunst pavucontrol rofi-rbw wlr-randr cava
)
legacy_packages=(cachyos-fish-config fish cachyos-zsh-config zsh-theme-powerlevel10k)

# ── Distro detection ─────────────────────────────────────────────────────

detect_distro() {
    local id id_like
    local os_release="${INSTALL_OS_RELEASE:-/etc/os-release}"
    if [ -f "$os_release" ]; then
        # shellcheck disable=SC1090
        . "$os_release"
        id="${ID:-}"
        id_like="${ID_LIKE:-}"
    else
        die "cannot detect distribution (/etc/os-release not found).
  Supported: arch, fedora, debian/ubuntu."
    fi

    case "$id" in
        arch|cachyos|endeavouros|manjaro|garuda|artix)
            DISTRO=arch; PKG_MGR=pacman ;;
        fedora|nobara)
            DISTRO=fedora; PKG_MGR=dnf ;;
        debian|ubuntu|linuxmint|pop|zorin|elementary|kali)
            DISTRO=debian; PKG_MGR=apt ;;
        *)
            case "$id_like" in
                *arch*)   DISTRO=arch;   PKG_MGR=pacman ;;
                *fedora*) DISTRO=fedora; PKG_MGR=dnf ;;
                *debian*|*ubuntu*) DISTRO=debian; PKG_MGR=apt ;;
                *) die "unsupported distribution: $id (ID_LIKE=$id_like).
  Supported: arch (and derivatives), fedora, debian/ubuntu." ;;
            esac
            ;;
    esac
}

# ── Package name resolution ──────────────────────────────────────────────

# Packages that need manual installation on non-Arch (not in repos).
# Value is the method: "omz" for oh-my-zsh, "nerdfont" for font, "starship"
# for starship.rs, "skip" to silently omit.
declare -A manual_install_method
manual_install_method=(
    [oh-my-zsh-git]=omz
    [ttf-jetbrains-mono-nerd]=nerdfont
)

# Arch package name overrides (AUR-only packages need manual install)
declare -A pkg_arch
pkg_arch=(
    [oh-my-zsh-git]=__manual__
)

# Fedora package name overrides (where different from Arch)
declare -A pkg_fedora
pkg_fedora=(
    [oh-my-zsh-git]=__manual__
    [ttf-jetbrains-mono-nerd]=__manual__
    [fd]=fd-find
    [polkit-kde-agent]=polkit-kde-agent-1
    [qt5-wayland]=qt5-qtwayland
    [qt6-wayland]=qt6-qtwayland
    [python-pillow]=python3-pillow
    [rofi-rbw]=__skip__
    [wlr-randr]=__skip__
)

# Debian/Ubuntu package name overrides
declare -A pkg_debian
pkg_debian=(
    [oh-my-zsh-git]=__manual__
    [ttf-jetbrains-mono-nerd]=__manual__
    [starship]=__manual__
    [fd]=fd-find
    [eza]=__skip__
    [thefuck]=__skip__
    [yazi]=__skip__
    [polkit-kde-agent]=polkit-kde-agent-1
    [qt5-wayland]=qtwayland5
    [qt6-wayland]=qt6-wayland-dev
    [python-pillow]=python3-pil
    [hyprland]=__manual_desktop__
    [hyprpaper]=__manual_desktop__
    [hyprlock]=__manual_desktop__
    [hypridle]=__manual_desktop__
    [xdg-desktop-portal-hyprland]=__manual_desktop__
    [rofi-rbw]=__skip__
    [wlr-randr]=__skip__
)

# Resolve a base package list to distro-specific names.
# Sets: resolved_packages (array), manual_methods (array of "method:name" pairs),
#       skipped_packages (array)
resolved_packages=()
manual_methods=()
skipped_packages=()
manual_desktop_packages=()

resolve_packages() {
    local -n _base_list=$1
    resolved_packages=()
    manual_methods=()
    skipped_packages=()
    manual_desktop_packages=()

    local pkg mapped
    for pkg in "${_base_list[@]}"; do
        mapped="$pkg"
        case "$DISTRO" in
            arch)   [ "${pkg_arch[$pkg]+set}" ]   && mapped="${pkg_arch[$pkg]}" ;;
            fedora) [ "${pkg_fedora[$pkg]+set}" ] && mapped="${pkg_fedora[$pkg]}" ;;
            debian) [ "${pkg_debian[$pkg]+set}" ] && mapped="${pkg_debian[$pkg]}" ;;
        esac

        case "$mapped" in
            __manual__)
                local method="${manual_install_method[$pkg]:-skip}"
                manual_methods+=("$method:$pkg")
                ;;
            __skip__)
                skipped_packages+=("$pkg")
                ;;
            __manual_desktop__)
                manual_desktop_packages+=("$pkg")
                ;;
            *)
                resolved_packages+=("$mapped")
                ;;
        esac
    done
}

# ── Package manager dispatch ─────────────────────────────────────────────

pkg_install() {
    local noconfirm_flag=""
    if "$ASSUME_YES"; then
        case "$DISTRO" in
            arch) noconfirm_flag="--noconfirm" ;;
        esac
    fi
    case "$DISTRO" in
        arch)   run sudo pacman -S --needed $noconfirm_flag "$@" ;;
        fedora) run sudo dnf install -y "$@" ;;
        debian) run sudo apt install -y "$@" ;;
    esac
}

pkg_remove() {
    case "$DISTRO" in
        arch)   run sudo pacman -Rns "$@" ;;
        fedora) run sudo dnf remove -y "$@" ;;
        debian) run sudo apt remove -y "$@" ;;
    esac
}

package_is_installed() {
    case "$DISTRO" in
        arch)   pacman -Q "$1" >/dev/null 2>&1 ;;
        fedora) rpm -q "$1" >/dev/null 2>&1 ;;
        debian) dpkg -l "$1" 2>/dev/null | grep -q '^ii' ;;
    esac
}

# ── Manual install functions ─────────────────────────────────────────────

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ] || [ -d /usr/share/oh-my-zsh ]; then
        printf '  unchanged Oh My Zsh (already installed)\n'
        return
    fi
    if "$DRY_RUN"; then
        printf '  would install Oh My Zsh from upstream\n'
        return
    fi
    printf '  installing Oh My Zsh from upstream...\n'
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
        printf '  warning: Oh My Zsh install failed; install it manually later\n'
    }
}

install_nerd_font() {
    local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerd"
    if [ -d "$font_dir" ] && ls "$font_dir"/*.ttf >/dev/null 2>&1; then
        printf '  unchanged JetBrains Mono Nerd Font (already installed)\n'
        return
    fi
    if "$DRY_RUN"; then
        printf '  would install JetBrains Mono Nerd Font from GitHub\n'
        return
    fi
    printf '  installing JetBrains Mono Nerd Font...\n'
    local tmpdir
    tmpdir="$(mktemp -d)"
    run curl -fsSL -o "$tmpdir/JetBrainsMono.tar.xz" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    mkdir -p "$font_dir"
    tar -xf "$tmpdir/JetBrainsMono.tar.xz" -C "$font_dir" --wildcards '*.ttf' 2>/dev/null || \
        tar -xf "$tmpdir/JetBrainsMono.tar.xz" -C "$font_dir"
    rm -rf "$tmpdir"
    run fc-cache -f
    printf '  installed JetBrains Mono Nerd Font\n'
}

install_starship() {
    if command -v starship >/dev/null 2>&1; then
        printf '  unchanged starship (already installed)\n'
        return
    fi
    if "$DRY_RUN"; then
        printf '  would install starship from starship.rs\n'
        return
    fi
    printf '  installing starship...\n'
    run sh -c 'curl -sS https://starship.rs/install.sh | sh -s -- -y'
}

run_manual_installs() {
    local entry method pkg
    for entry in "${manual_methods[@]}"; do
        method="${entry%%:*}"
        pkg="${entry#*:}"
        case "$method" in
            omz)      install_oh_my_zsh ;;
            nerdfont) install_nerd_font ;;
            starship) install_starship ;;
            skip)     printf '  skipped %s (not available for %s)\n' "$pkg" "$DISTRO" ;;
        esac
    done
}

# ── Post-install fixups ──────────────────────────────────────────────────

post_install_fixups() {
    if [ "$DISTRO" = "debian" ]; then
        # Debian installs bat as batcat and fd as fdfind
        local bin_dir="$HOME/.local/bin"
        mkdir -p "$bin_dir"
        if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
            if "$DRY_RUN"; then
                printf '  would symlink %s/bat -> batcat\n' "$bin_dir"
            else
                ln -sf "$(command -v batcat)" "$bin_dir/bat"
                printf '  symlinked bat -> batcat\n'
            fi
        fi
        if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
            if "$DRY_RUN"; then
                printf '  would symlink %s/fd -> fdfind\n' "$bin_dir"
            else
                ln -sf "$(command -v fdfind)" "$bin_dir/fd"
                printf '  symlinked fd -> fdfind\n'
            fi
        fi
    fi
}

# ── Core helpers (archive, link, install, seed — unchanged) ──────────────

usage() {
    cat <<'USAGE'
Usage: ./install.sh [--dry-run] [--yes] [--desktop]

Install the managed terminal profile (zsh, kitty, starship, CLI tools, font).
Files already managed by Chezmoi are detected and left alone.

  --desktop  Also link Hyprland, Waybar, and Neovim configs and install
             desktop packages (hyprland, waybar, wofi, etc.).
  --dry-run  Print the complete plan without changing anything.
  --yes      Apply without the interactive confirmation prompt.
  -h, --help Show this help.

Supported distros: Arch (+ derivatives), Fedora, Debian/Ubuntu.
The installer auto-detects your distribution from /etc/os-release.
USAGE
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

chezmoi_manages() {
    local target="$1"
    command -v chezmoi >/dev/null 2>&1 || return 1
    chezmoi source-path >/dev/null 2>&1 || return 1
    chezmoi managed --path-style absolute 2>/dev/null | grep -Fqx "$target"
}

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

seed_file() {
    local source="$1" destination="$2" mode="$3"
    if target_exists "$destination"; then
        printf '  existing %s\n' "$destination"
        return
    fi
    ensure_state_dir
    if "$DRY_RUN"; then
        printf '  would seed fallback %s -> %s\n' "$source" "$destination"
    else
        mkdir -p "$(dirname "$destination")"
        install -m "$mode" "$source" "$destination"
        record seed "$destination" "$source"
        printf '  seeded fallback %s\n' "$destination"
    fi
}

# ── Preflight & plan ─────────────────────────────────────────────────────

packages_to_remove=()

preflight() {
    command -v "$PKG_MGR" >/dev/null 2>&1 || die "$PKG_MGR not found — is $DISTRO properly set up?"
    command -v chsh >/dev/null 2>&1 || die 'chsh is required to set the login shell'

    # Legacy package removal (Arch-only, from CachyOS migration)
    packages_to_remove=()
    if [ "$DISTRO" = "arch" ]; then
        local package
        for package in "${legacy_packages[@]}"; do
            package_is_installed "$package" && packages_to_remove+=("$package") || true
        done
    fi

    # Resolve package names for this distro
    resolve_packages terminal_packages_base
    terminal_packages=("${resolved_packages[@]}")
    terminal_manual=("${manual_methods[@]}")

    resolve_packages desktop_packages_base
    desktop_packages=("${resolved_packages[@]}")
    desktop_manual=("${manual_methods[@]}")
    desktop_manual_note=("${manual_desktop_packages[@]}")
    desktop_skipped=("${skipped_packages[@]}")

    # Debian desktop caveat
    if "$DESKTOP" && [ "$DISTRO" = "debian" ] && ((${#desktop_manual_note[@]})); then
        if ! command -v Hyprland >/dev/null 2>&1; then
            printf '\n'
            printf '  NOTE: Hyprland is not in Debian/Ubuntu repos.\n'
            printf '  The following must be installed manually before using --desktop:\n'
            printf '    %s\n' "${desktop_manual_note[@]}"
            printf '  See: https://wiki.hyprland.org/Getting-Started/Installation/\n'
            printf '\n'
            printf '  The installer will still link config files if you continue,\n'
            printf '  but Hyprland will not work until you install it separately.\n'
            printf '\n'
        fi
    fi
}

show_welcome() {
    local distro_label
    case "$DISTRO" in
        arch)   distro_label="Arch Linux ($PKG_MGR)" ;;
        fedora) distro_label="Fedora ($PKG_MGR)" ;;
        debian) distro_label="Debian/Ubuntu ($PKG_MGR)" ;;
    esac

    printf '\n'
    printf '  ┌─────────────────────────────────────────────────────────┐\n'
    printf '  │              hyprland-setup installer                   │\n'
    printf '  │                                                        │\n'
    printf '  │  Detected: %-43s │\n' "$distro_label"
    printf '  │                                                        │\n'
    printf '  │  This installer can set up:                            │\n'
    printf '  │    terminal   zsh, kitty, starship, CLI tools, font    │\n'
    printf '  │    desktop    + hyprland, waybar, wofi, nvim configs   │\n'
    printf '  │                                                        │\n'
    printf '  │  Run with --dry-run to preview without changes         │\n'
    printf '  └─────────────────────────────────────────────────────────┘\n'
    printf '\n'
}

interactive_mode() {
    [ -t 0 ] || return 1
    "$ASSUME_YES" && return 1
    "$DRY_RUN" && return 1
    # Only enter interactive mode if no mode flags were passed
    return 0
}

ask_desktop() {
    if ! "$DESKTOP" && interactive_mode; then
        local default_desktop=false
        if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || command -v hyprctl >/dev/null 2>&1 \
           || command -v Hyprland >/dev/null 2>&1; then
            default_desktop=true
        fi

        if "$default_desktop"; then
            printf 'Hyprland detected. Install terminal + desktop? (or terminal only)\n'
            printf '  [d] terminal + desktop (default)\n'
            printf '  [t] terminal only\n'
        else
            printf 'Install terminal tools only, or include the full desktop (Hyprland, Waybar, etc.)?\n'
            printf '  [t] terminal only (default)\n'
            printf '  [d] terminal + desktop\n'
        fi
        printf '  choice: '
        local answer
        read -r answer
        if "$default_desktop"; then
            [[ "$answer" =~ ^[Tt] ]] || DESKTOP=true
        else
            [[ "$answer" =~ ^[Dd] ]] && DESKTOP=true
        fi
    fi
}

print_plan() {
    printf '\n── Plan ──────────────────────────────────────────────────────\n'
    printf '  distro:             %s (%s)\n' "$DISTRO" "$PKG_MGR"
    printf '  terminal packages:  %s\n' "${terminal_packages[*]}"
    if ((${#terminal_manual[@]})); then
        printf '  manual installs:    '
        local entry; for entry in "${terminal_manual[@]}"; do printf '%s ' "${entry#*:}"; done
        printf '\n'
    fi
    printf '  legacy removal:     %s\n' "${packages_to_remove[*]:-(none)}"
    printf '  config targets:     ~/.zshrc, ~/.config/kitty/kitty.conf, ~/.config/starship.toml\n'
    printf '  always manage:      ~/.local/bin/shortcuts\n'
    printf '  login shell:        chsh -s zsh (if needed)\n'
    printf '  state directory:    %s/install-<timestamp>\n' "$STATE_ROOT"
    printf '  untouched:          ~/.bashrc, existing DE configs, theme-engine targets\n'
    if "$DESKTOP"; then
        printf '  desktop packages:   %s\n' "${desktop_packages[*]}"
        if ((${#desktop_manual[@]})); then
            printf '  desktop manual:     '
            local entry; for entry in "${desktop_manual[@]}"; do printf '%s ' "${entry#*:}"; done
            printf '\n'
        fi
        if ((${#desktop_manual_note[@]})); then
            printf '  needs manual install: %s\n' "${desktop_manual_note[*]}"
        fi
        printf '  desktop links:      ~/.config/hypr, ~/.config/waybar, ~/.config/nvim\n'
        printf '  desktop helpers:    workspace-switcher, power-menu, wofi-singleton, etc.\n'
        printf '  fallback seeds:     hypr/generated/theme.conf, waybar/generated/{theme,component}.css, eww theme.scss\n'
    fi
    printf '──────────────────────────────────────────────────────────────\n\n'
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

# ── Execution phases ─────────────────────────────────────────────────────

manage_packages() {
    printf '\n[1/5] Installing packages...\n'
    ensure_state_dir
    record package-install "${terminal_packages[*]}" "sudo $PKG_MGR install"
    if ((${#terminal_packages[@]})); then
        pkg_install "${terminal_packages[@]}"
    fi
    if ((${#terminal_manual[@]})); then
        manual_methods=("${terminal_manual[@]}")
        run_manual_installs
    fi
    if "$DESKTOP"; then
        if ((${#desktop_packages[@]})); then
            record package-install "${desktop_packages[*]}" "sudo $PKG_MGR install"
            pkg_install "${desktop_packages[@]}"
        fi
        if ((${#desktop_manual[@]})); then
            manual_methods=("${desktop_manual[@]}")
            run_manual_installs
        fi
    fi
    if ((${#packages_to_remove[@]})); then
        record package-remove "${packages_to_remove[*]}" "sudo $PKG_MGR remove"
        pkg_remove "${packages_to_remove[@]}"
    fi
}

set_zsh_as_login_shell() {
    printf '\n[4/5] Setting login shell...\n'
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
    printf '\n[2/5] Configuring terminal (zsh, kitty, starship)...\n'
    archive "$CFG/fish"
    archive "$HOME/.p10k.zsh"

    if chezmoi_manages "$HOME/.zshrc"; then
        printf '  Chezmoi owns %s; leaving it unchanged\n' "$HOME/.zshrc"
    else
        link "$REPO/zsh/.zshrc" "$HOME/.zshrc"
    fi

    if chezmoi_manages "$CFG/kitty/kitty.conf"; then
        printf '  Chezmoi owns %s; leaving it unchanged\n' "$CFG/kitty/kitty.conf"
    else
        install_file "$REPO/kitty/kitty.conf" "$CFG/kitty/kitty.conf" 0644
    fi

    if chezmoi_manages "$CFG/starship.toml"; then
        printf '  Chezmoi owns %s; leaving it unchanged\n' "$CFG/starship.toml"
    elif grep -q 'AUTO-GENERATED by `theme`' "$CFG/starship.toml" 2>/dev/null; then
        printf '  unchanged %s (managed by theme engine)\n' "$CFG/starship.toml"
    else
        install_file "$REPO/starship/starship.toml" "$CFG/starship.toml" 0644
    fi

    install_file "$REPO/bin/shortcuts" "$HOME/.local/bin/shortcuts" 0755
}

manage_desktop_files() {
    printf '\n[3/5] Configuring desktop (hyprland, waybar, nvim)...\n'
    link "$REPO/hypr" "$CFG/hypr"
    link "$REPO/waybar" "$CFG/waybar"
    link "$REPO/eww/waybar-panels" "$CFG/eww/waybar-panels"
    link "$REPO/nvim" "$CFG/nvim"
    if "$DRY_RUN"; then
        printf '  would generate %s (expand __HOME__ -> %s)\n' "$REPO/hypr/hyprpaper.conf" "$HOME"
    else
        sed "s|__HOME__|$HOME|g" "$REPO/hypr/hyprpaper.conf.tpl" > "$REPO/hypr/hyprpaper.conf"
        printf '  generated %s\n' "$REPO/hypr/hyprpaper.conf"
    fi
    install_file "$REPO/bin/workspace-switcher" "$CFG/bin/workspace-switcher" 0755
    install_file "$REPO/bin/power-menu" "$CFG/bin/power-menu" 0755
    install_file "$REPO/bin/apply-cursor" "$CFG/bin/apply-cursor" 0755
    install_file "$REPO/bin/quick-note" "$CFG/bin/quick-note" 0755
    install_file "$REPO/bin/notification-center" "$CFG/bin/notification-center" 0755
    install_file "$REPO/bin/session-welcome" "$CFG/bin/session-welcome" 0755
    install_file "$REPO/bin/generate-keybinds" "$CFG/bin/generate-keybinds" 0755
    install_file "$REPO/bin/keybind-menu" "$CFG/bin/keybind-menu" 0755
    install_file "$REPO/bin/wofi-singleton" "$HOME/.local/bin/wofi-singleton" 0755
    install_file "$REPO/bin/waybar-panel" "$CFG/bin/waybar-panel" 0755
    seed_file "$REPO/fallback/hypr-theme.conf" "$CFG/hypr/generated/theme.conf" 0644
    seed_file "$REPO/fallback/waybar-theme.css" "$CFG/waybar/generated/theme.css" 0644
    seed_file "$REPO/fallback/waybar-component.css" "$CFG/waybar/generated/component.css" 0644
    seed_file "$REPO/fallback/eww-panels-theme.scss" "$CFG/eww/waybar-panels/generated/theme.scss" 0644
}

post_install_summary() {
    printf '\n[5/5] Post-install...\n'
    post_install_fixups
    if "$DRY_RUN"; then
        printf '\nDry run complete. No changes were made.\n'
    else
        printf '\nDone. Backups and manifest: %s\n' "$STATE_DIR"
        printf '\n── Next steps ────────────────────────────────────────────────\n'
        printf '  1. Open a new terminal or run: exec zsh\n'
        if "$DESKTOP"; then
            printf '  2. Log out and select "Hyprland" at your display manager\n'
            printf '  3. Press Super+Shift+? inside Hyprland for the keybind cheat sheet\n'
            printf '  4. Optional: install the theme engine from the themes repo\n'
        else
            printf '  2. To install the desktop later: ./install.sh --desktop\n'
        fi
        printf '──────────────────────────────────────────────────────────────\n'
    fi
}

# ── Argument parsing & main ──────────────────────────────────────────────

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

detect_distro
show_welcome
ask_desktop
preflight
print_plan
confirm
manage_packages
manage_terminal_files
"$DESKTOP" && manage_desktop_files
set_zsh_as_login_shell
post_install_summary
