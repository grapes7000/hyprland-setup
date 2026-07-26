# hyprland-setup

A modular, themeable **Hyprland** desktop, built to run in a QEMU/KVM Arch
guest (over SPICE) but usable on any Arch/Wayland machine. Comes with a
28-theme engine (see the companion [`themes`](#theming) repo), per-theme
wallpapers, blur/shadow eye-candy, and a set of small helper commands.

> **Backup-first:** this repo exists so the whole setup can be restored if the
> VM is ever wiped. Clone it, run `install.sh`, log into Hyprland, done.

---

## What's in here

```
hyprland-setup/
├── hypr/          Hyprland config (modular — sourced from hyprland.conf)
│   ├── hyprland.conf         entry point; sources everything below
│   ├── conf/
│   │   ├── env.conf          environment variables
│   │   ├── monitors.conf     output + resolution (2560x1440)
│   │   ├── behavior.conf     layout, animations, misc
│   │   ├── input.conf        keyboard/mouse/touchpad
│   │   ├── keybinds.conf     all keybindings
│   │   ├── windowrules.conf  floating dialogs etc.
│   │   └── autostart.conf    exec-once services (waybar, spice fix, etc.)
│   ├── hyprpaper.conf        wallpaper daemon
│   ├── hyprlock.conf         lock screen
│   └── hypridle.conf         idle/lock timeouts
├── waybar/        Top bar (config + CSS)   [portable to other wlroots WMs]
├── kitty/         Kitty terminal config     [GENERIC — any distro]
├── zsh/           Oh My Zsh + plugin config [Arch installer target]
├── starship/      Powerlevel10k-style prompt [GENERIC — any shell/distro]
├── bin/           shortcuts (keybind cheat-sheet command)
├── docs/
│   ├── TROUBLESHOOTING.md    ← every issue hit + how to fix it (READ THIS)
│   └── VM-GUEST-SETUP.md     ← SPICE, virgl, resolution, SSH specifics
└── install.sh     safe terminal installer; desktop linking is opt-in
```

The folders marked **GENERIC** are self-contained — each has its own README and
works on any distro, no Hyprland required. See [Reusable parts](#reusable-parts).

---

## Quick start

```sh
git clone https://github.com/grapes7000/hyprland-setup.git ~/hyprland-setup
cd ~/hyprland-setup
./install.sh --dry-run
./install.sh
```

The installer is terminal-only by default. It installs and configures Kitty,
Zsh, packaged `oh-my-zsh-git`, Starship, autosuggestions, syntax highlighting,
fzf, ripgrep, fd, bat, eza, thefuck, zoxide, direnv, yazi, jq, tldr, and a Nerd
Font. It replaces only `~/.zshrc`, `~/.config/kitty/kitty.conf`,
`~/.config/starship.toml`, and `~/.local/bin/shortcuts`; it archives each
replaced item first and sets Zsh as the login shell after confirmation.

It never writes `~/.bashrc`, Hyprland, Waybar, Neovim, theme-engine targets,
Wofi, Dunst, or Hyprlock unless you explicitly select desktop linking:

```sh
./install.sh --desktop
```

`--desktop` links only `~/.config/hypr`, `~/.config/waybar`, and
`~/.config/nvim`, with the same archive-first behavior. Neither mode clones,
installs, configures, or applies a theme engine.

`--dry-run` prints the exact package, archive, file, and login-shell plan
without changing anything. `--yes` is the only non-interactive apply path.
During migration the installer archives `~/.config/fish`, `~/.p10k.zsh`, and
the old Zsh config, then removes installed legacy packages:
`cachyos-fish-config`, `fish`, `cachyos-zsh-config`, and
`zsh-theme-powerlevel10k`. Backups and `manifest.tsv` are placed under
`~/.local/state/hyprland-setup/install-*/`. To restore a target, remove its
new managed file or symlink, then move the backup path listed in the manifest
back to the target path. Package and login-shell changes are intentionally
listed in the dry-run/apply summary and must be reversed explicitly.

The installer currently supports Arch-based distributions.

Install the desktop packages it needs (Arch):
```sh
sudo pacman -S --needed hyprland waybar wofi hyprpaper hyprlock hypridle \
  xdg-desktop-portal-hyprland polkit-kde-agent qt5-wayland qt6-wayland \
  grim slurp wl-clipboard brightnessctl playerctl pamixer python-pillow
```

Then log out and pick **Hyprland** at your display manager, or run `Hyprland`
from a TTY.

### Theming

Colors, blur, shadows and wallpapers come from the separate
[`themes`](https://github.com/grapes7000/themes) repo. Install and run it
separately if you want theme management; this installer deliberately leaves it
alone.

---

## Keybinds (the essentials)

`SUPER` is the Windows key. Full list any time with `shortcuts` or **Super+Shift+?**

| Key | Action |
|---|---|
| `Super + Return` | Terminal (kitty) |
| `Super + Space` | App launcher (wofi) |
| `Super + T` | Theme picker |
| `Super + Shift + ?` | This cheat sheet |
| `Super + Q` | Close window |
| `Super + H/J/K/L` | Focus (vim directions) |
| `Super + Shift + H/J/K/L` | Move window |
| `Super + Ctrl + H/J/K/L` | Resize window |
| `Super + 1..0` | Switch workspace |
| `Super + Shift + 1..0` | Send window to workspace |
| `Super + F` | Fullscreen |
| `Super + V` | Toggle floating |
| `Print` / `Super + S` | Screenshot region → clipboard |

Edit `hypr/conf/keybinds.conf` to customise, then `hyprctl reload`.

---

## Helper commands

| Command | What it does | Lives in |
|---|---|---|
| `shortcuts` | Print the keybind + command cheat sheet | this repo |
| `theme [name]` | Switch/list themes (regenerates everything, live) | themes repo |
| `theme-new <name>` | Scaffold a new theme from an existing one | themes repo |
| `theme-menu` | wofi theme picker | themes repo |
| `wallgen [name]` | (Re)generate the blurry-blob wallpaper(s) | themes repo |

---

## Reusable parts

These folders are deliberately generic — grab just the one you want:

- **`kitty/`** — terminal config, works in kitty on any OS and includes its own
  palette. See `kitty/README.md`.
- **`zsh/`** — the managed Zsh profile. It uses Oh My Zsh plugins and Starship
  instead of Powerlevel10k. Add personal shell changes to `~/.zshrc.local`.
- **`starship/`** — the self-contained Powerlevel10k-style prompt config. See
  `starship/README.md`.
- **`waybar/`** — a clean top bar for any wlroots compositor; colors come from
  `generated/theme.css` (theme engine) via `@import`.

---

## The VM story / troubleshooting

This setup was built inside a KVM guest and hit a lot of the classic
SPICE/virtio/Wayland snags. **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**
is a full playbook: spice-vdagent failing as a user service, `xrandr` vs
`wlr-randr` resolution, enabling virgl GPU acceleration (and un-breaking the
boot when it fails), Hyprland 0.56 config changes, Zsh notes, and getting
SSH into the guest. Read it before you re-derive any of it.

---

## Credits

Theme palettes are adapted from their upstream projects (Catppuccin, Dracula,
Nord, Gruvbox, Tokyo Night, Everforest, Kanagawa, Solarized, One Dark, Monokai,
Material). See the `themes` repo for per-theme attribution.
