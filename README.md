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
├── kitty/         Terminal config          [GENERIC — any distro]
├── fish/          Shell PATH snippet        [GENERIC — any distro]
├── starship/      Prompt config             [GENERIC — any shell/distro]
├── bin/           shortcuts (keybind cheat-sheet command)
├── docs/
│   ├── TROUBLESHOOTING.md    ← every issue hit + how to fix it (READ THIS)
│   └── VM-GUEST-SETUP.md     ← SPICE, virgl, resolution, SSH specifics
└── install.sh     symlinks everything into ~/.config
```

The folders marked **GENERIC** are self-contained — each has its own README and
works on any distro, no Hyprland required. See [Reusable parts](#reusable-parts).

---

## Quick start

```sh
git clone https://github.com/grapes7000/hyprland-setup.git ~/hyprland-setup
cd ~/hyprland-setup
./install.sh
```

Install the packages it needs (Arch):
```sh
sudo pacman -S --needed hyprland waybar kitty wofi hyprpaper hyprlock hypridle \
  xdg-desktop-portal-hyprland polkit-kde-agent qt5-wayland qt6-wayland \
  grim slurp wl-clipboard starship ttf-jetbrains-mono-nerd \
  brightnessctl playerctl pamixer python-pillow
```

Then log out and pick **Hyprland** at your display manager, or run `Hyprland`
from a TTY.

### Theming

Colors, blur, shadows and wallpapers come from the separate
[`themes`](https://github.com/grapes7000/themes) repo. The main installer clones
it to `~/themes` when needed, runs its installer, and applies
`catppuccin_mocha`, so no second command is required. Set a different initial
theme with `HYPRLAND_THEME=gruvbox ./install.sh`.

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

- **`kitty/`** — terminal config, works in kitty on any OS. The one Hyprland
  tie-in is a `include generated/theme.conf` line (from the theme engine);
  remove it or drop your own colors for standalone use. See `kitty/README.md`.
- **`fish/`** — the `fish_add_path` snippet to get `~/.local/bin` on PATH.
- **`starship/`** — the prompt config. The palette block is rewritten by the
  theme engine, but the layout works anywhere. See `starship/README.md`.
- **`waybar/`** — a clean top bar for any wlroots compositor; colors come from
  `generated/theme.css` (theme engine) via `@import`.

---

## The VM story / troubleshooting

This setup was built inside a KVM guest and hit a lot of the classic
SPICE/virtio/Wayland snags. **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**
is a full playbook: spice-vdagent failing as a user service, `xrandr` vs
`wlr-randr` resolution, enabling virgl GPU acceleration (and un-breaking the
boot when it fails), Hyprland 0.56 config changes, fish gotchas, and getting
SSH into the guest. Read it before you re-derive any of it.

---

## Credits

Theme palettes are adapted from their upstream projects (Catppuccin, Dracula,
Nord, Gruvbox, Tokyo Night, Everforest, Kanagawa, Solarized, One Dark, Monokai,
Material). See the `themes` repo for per-theme attribution.
