#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
home="$root/home"
mock="$root/mock"
cleanup() { rm -rf "$root"; }
trap cleanup EXIT
mkdir -p "$home/.config/kitty" "$home/.config/hypr" "$home/.config/waybar" "$home/.config/nvim" "$home/.config/fish" "$home/.local/bin" "$mock"
printf 'old zsh\n' > "$home/.zshrc"
printf 'old kitty\n' > "$home/.config/kitty/kitty.conf"
printf 'old bash\n' > "$home/.bashrc"
printf 'old fish\n' > "$home/.config/fish/config.fish"
printf 'old p10k\n' > "$home/.p10k.zsh"
printf 'hypr sentinel\n' > "$home/.config/hypr/sentinel"
printf 'waybar sentinel\n' > "$home/.config/waybar/sentinel"
printf 'nvim sentinel\n' > "$home/.config/nvim/sentinel"
ln -s "$home/not-starship" "$home/.config/starship.toml"

printf '%s\n' '#!/usr/bin/env bash' 'exec "$@"' > "$mock/sudo"
printf '%s\n' '#!/usr/bin/env bash' 'if [ "$1" = "-Q" ]; then exit 0; fi' 'printf "%s\\n" "$*" >> "$INSTALL_TEST_LOG"' > "$mock/pacman"
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\\n" "$*" >> "$INSTALL_TEST_LOG"' > "$mock/chsh"
chmod +x "$mock/sudo" "$mock/pacman" "$mock/chsh"

if ! env HOME="$home" USER=tester SHELL=/bin/bash XDG_STATE_HOME="$home/.state" PATH="$mock:$PATH" INSTALL_TEST_LOG="$root/log" \
    "$repo/install.sh" --dry-run > "$root/dry-run" 2>&1; then
    sed -n '1,160p' "$root/dry-run" >&2
    exit 1
fi
cmp <(printf 'old zsh\n') "$home/.zshrc"
cmp <(printf 'old kitty\n') "$home/.config/kitty/kitty.conf"
[ ! -e "$root/log" ]
rg -F 'untouched by default:' "$root/dry-run" >/dev/null

if ! env HOME="$home" USER=tester SHELL=/bin/bash XDG_STATE_HOME="$home/.state" PATH="$mock:$PATH" INSTALL_TEST_LOG="$root/log" \
    "$repo/install.sh" --yes > "$root/apply" 2>&1; then
    sed -n '1,160p' "$root/apply" >&2
    exit 1
fi
[ -L "$home/.zshrc" ]
cmp "$repo/kitty/kitty.conf" "$home/.config/kitty/kitty.conf"
cmp "$repo/starship/starship.toml" "$home/.config/starship.toml"
cmp <(printf 'old bash\n') "$home/.bashrc"
cmp <(printf 'hypr sentinel\n') "$home/.config/hypr/sentinel"
cmp <(printf 'waybar sentinel\n') "$home/.config/waybar/sentinel"
cmp <(printf 'nvim sentinel\n') "$home/.config/nvim/sentinel"
state_dir="$(find "$home/.state/hyprland-setup" -mindepth 1 -maxdepth 1 -type d)"
[ -f "$state_dir/manifest.tsv" ]
rg -F "$home/.config/starship.toml" "$state_dir/manifest.tsv" >/dev/null
rg -F "$home/.config/fish" "$state_dir/manifest.tsv" >/dev/null
rg -F -- '-Rns cachyos-fish-config fish cachyos-zsh-config zsh-theme-powerlevel10k' "$root/log" >/dev/null
rg -F -- '-s /usr/bin/zsh' "$root/log" >/dev/null
printf 'installer tests passed\n'
