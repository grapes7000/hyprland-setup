# hyprland-setup

> **Lakota Shell:** on the active Caelestia Lua layout,
> `bin/lakota-hypr-theme install` adds a version-aware, reversible styling
> adapter through the user extension file. See `docs/LAKOTA-THEME.md`.

A modular, themeable **Hyprland** desktop environment with managed configs for
Hyprland, Waybar, Kitty, Zsh, Starship, and Neovim. Comes with a 36-theme
engine, per-theme wallpapers, blur/shadow eye-candy, and a set of helper
scripts.

---

## What you get

**Terminal mode** (default) installs and configures:
- **Zsh** with Oh My Zsh, autosuggestions, syntax highlighting, history-substring-search
- **Kitty** terminal with JetBrains Mono Nerd Font
- **Starship** prompt (Powerlevel10k-style)
- CLI tools: fzf, ripgrep, fd, bat, eza, zoxide, direnv, yazi, jq, tldr, thefuck, neovim

**Desktop mode** (`--desktop`) additionally sets up:
- **Hyprland** compositor with a modular config (keybinds, window rules, animations)
- **Waybar** top bar with workspace indicators, system stats, clock, audio, network
- **Eww homepage** with a clock, welcome panel, and discoverable shortcuts
- **Neovim** config with Tree-sitter and colorizer
- Helper scripts: power menu, workspace switcher, keybind cheat sheet, app launcher
- Wofi launcher, dunst notifications, hyprlock screen lock, hypridle

---

## Supported distributions

| Distro | Terminal mode | Desktop mode |
|---|---|---|
| **Arch Linux** (+ CachyOS, EndeavourOS, Manjaro) | Full support | Full support |
| **Fedora** 39+ | Full support | Full support |
| **Debian / Ubuntu** 24.04+ | Full support | Configs only — Hyprland must be installed manually first |

The installer auto-detects your distribution from `/etc/os-release` and uses
the right package manager (`pacman`, `dnf`, or `apt`).

---

## Quick start — Arch Linux

This is the simplest path. All packages are in the repos (or AUR).

### Step 1: Clone the repo

```sh
git clone https://github.com/grapes7000/hyprland-setup.git ~/hyprland-setup
cd ~/hyprland-setup
```

### Step 2: Preview what will happen

```sh
./install.sh --dry-run
```

This prints the full plan — packages to install, files to link, backups to
create — without changing anything. Read through it.

### Step 3: Run the installer

```sh
./install.sh
```

The installer is interactive by default. It will:
1. Show a welcome banner with your detected distro
2. Ask whether you want terminal-only or full desktop
3. Show the plan and ask for confirmation
4. Install packages, link configs, and set zsh as your login shell

For a non-interactive run (e.g., scripting):
```sh
./install.sh --yes              # terminal only, no prompts
./install.sh --yes --desktop    # terminal + desktop, no prompts
```

### Step 4: Start using it

```sh
exec zsh            # switch to zsh in your current terminal
```

For desktop mode:
1. Log out of your current session
2. At your display manager (SDDM, GDM, etc.), select **Hyprland**
3. Press **Super+Shift+?** for the keybind cheat sheet
4. Press **Super+Return** to open a terminal

### Step 5: Theming (optional)

Colors, wallpapers, blur, and shadows come from the separate
[themes](https://github.com/grapes7000/themes) repo. The installer seeds safe
fallback files so the desktop works without it. To install themes:

```sh
git clone https://github.com/grapes7000/themes.git ~/themes
~/themes/install.sh
theme catppuccin_mocha    # or any of the 36 themes
```

---

## Quick start — Fedora

Hyprland is in the Fedora repos since Fedora 39, so the experience is similar
to Arch.

### Step 1: Clone and preview

```sh
git clone https://github.com/grapes7000/hyprland-setup.git ~/hyprland-setup
cd ~/hyprland-setup
./install.sh --dry-run
```

### Step 2: Run the installer

```sh
./install.sh
```

Differences from Arch:
- **Oh My Zsh** is installed from the upstream script (not a package)
- **JetBrains Mono Nerd Font** is downloaded from GitHub releases
- A few packages (`rofi-rbw`, `wlr-randr`) are not available and are skipped
- Legacy CachyOS migration is skipped (Arch-only)

### Step 3: Launch Hyprland

If you chose desktop mode:
1. Log out
2. At GDM or your display manager, click the gear icon and select **Hyprland**
3. Your existing desktop (GNOME, KDE, etc.) is untouched — see
   [Installing alongside an existing DE](#installing-alongside-an-existing-desktop-environment)

---

## Quick start — Debian / Ubuntu

Terminal mode works identically. Desktop mode requires an extra step because
Hyprland is **not in the Debian/Ubuntu repos**.

### Step 1: Install Hyprland manually (desktop mode only)

Follow the official guide:
**https://wiki.hyprland.org/Getting-Started/Installation/**

This typically means building from source or adding a third-party PPA.

### Step 2: Clone and run

```sh
git clone https://github.com/grapes7000/hyprland-setup.git ~/hyprland-setup
cd ~/hyprland-setup
./install.sh
```

Differences from Arch:
- **Oh My Zsh**, **JetBrains Mono Nerd Font**, and **Starship** are installed
  from upstream (not packages)
- `bat` is installed as `batcat` — the installer creates a `bat` symlink in
  `~/.local/bin`
- `fd` is installed as `fd-find` — same symlink treatment
- Some packages (`eza`, `thefuck`, `yazi`) are not in repos and are skipped;
  install them via `pip`, `cargo`, or upstream releases if you want them

### Step 3: Launch Hyprland

Same as Fedora — log out, select Hyprland at your display manager.

---

## Installing alongside an existing desktop environment

Hyprland is a **Wayland compositor**, not a full desktop environment replacement.
Installing it **does not remove, disable, or modify** your existing DE (GNOME,
KDE Plasma, XFCE, etc.).

### How it works

- Hyprland registers itself as a separate **session** at your display manager
  (GDM, SDDM, LightDM, etc.)
- At the login screen, you choose which session to start — Hyprland or your
  existing DE
- Each session has its own config files in different directories
- Switching back is as simple as logging out and picking your DE at the login
  screen

### What the installer touches

The installer **only** manages these paths:

| Path | What | Mode |
|---|---|---|
| `~/.zshrc` | Symlink to repo | terminal |
| `~/.config/kitty/kitty.conf` | Copy from repo | terminal |
| `~/.p10k.zsh` | Preserved and sourced when present | terminal |
| `~/.local/bin/shortcuts` | Copy from repo | terminal |
| `~/.config/hypr` | Symlink to repo | desktop |
| `~/.config/waybar` | Symlink to repo | desktop |
| `~/.config/eww` | Symlink to the bundled homepage | desktop |
| `~/.config/nvim` | Symlink to repo | desktop |
| `~/.config/bin/*` | Helper scripts | desktop |
| `~/.local/bin/wofi-singleton` | Copy from repo | desktop |

### What it does NOT touch

- `~/.bashrc` — never modified
- GNOME settings (`dconf`, `~/.config/gnome-*`)
- KDE settings (`~/.config/kde*`, `~/.config/plasma*`)
- Your display manager configuration
- System-wide settings in `/etc`
- Any other DE's config files

### If you don't have a display manager

You need one to switch between sessions. Install one:

```sh
# Arch
sudo pacman -S sddm && sudo systemctl enable sddm

# Fedora (GDM is usually pre-installed)
sudo dnf install sddm && sudo systemctl enable sddm

# Debian/Ubuntu (GDM is usually pre-installed)
sudo apt install sddm && sudo systemctl enable sddm
```

Or start Hyprland from a TTY without a display manager:

```sh
# Log into a TTY (Ctrl+Alt+F2), then:
Hyprland
```

---

## What the installer does (detailed)

The installer runs in phases with progress output:

### Phase 1: Detection
- Reads `/etc/os-release` to identify your distro
- Maps package names to your package manager
- Checks for legacy configs to migrate (Arch only)

### Phase 2: Packages
- Installs terminal tools via your package manager
- Manually installs Oh My Zsh, Powerlevel10k, and the Nerd Font when needed
- If `--desktop`: installs Hyprland, Waybar, Wofi, and related packages
- On Arch: removes legacy packages if found (cachyos-fish-config, fish,
  cachyos-zsh-config)

### Phase 3: Terminal config
- Archives an existing `~/.config/fish` directory during legacy migration
- Symlinks `~/.zshrc` → repo's `zsh/.zshrc`
- Copies `kitty.conf` to `~/.config/` and configures Powerlevel10k for Zsh
- Installs `shortcuts` command to `~/.local/bin/`
- Skips any target managed by [Chezmoi](https://www.chezmoi.io/)

### Phase 4: Desktop config (only with `--desktop`)
- Symlinks `~/.config/hypr`, `~/.config/waybar`, `~/.config/nvim` → repo dirs
- Generates `hyprpaper.conf` from template (expands `$HOME` path)
- Installs helper scripts (power menu, workspace switcher, etc.)
- Seeds fallback theme files if the theme engine hasn't run yet

### Phase 5: Login shell
- Sets Zsh as your login shell via `chsh` (if not already Zsh)

### Backups

Every file the installer replaces is archived first to:
```
~/.local/state/hyprland-setup/install-<timestamp>/backups/
```

A `manifest.tsv` in the same directory records every action taken. To restore
a file, check the manifest for its backup path and move it back.

---

## What's in this repo

```
hyprland-setup/
├── hypr/          Hyprland config (modular — sourced from hyprland.conf)
│   ├── hyprland.conf         entry point
│   ├── conf/                 env, monitors, behavior, input, keybinds, window rules, autostart
│   ├── generated/            theme-engine output (colors, decoration)
│   ├── themes/               36 theme JSON definitions
│   ├── wallpapers/           per-theme wallpapers (generated)
│   ├── hyprpaper.conf.tpl    wallpaper daemon template
│   ├── hyprlock.conf         lock screen
│   └── hypridle.conf         idle timeouts
├── waybar/        Top bar config + CSS (portable to other wlroots WMs)
├── homepage/      Eww homepage config + logged startup launcher
├── kitty/         Kitty terminal config (works on any OS)
├── zsh/           Zsh profile with Oh My Zsh + Starship
├── starship/      Starship prompt config (works with any shell)
├── nvim/          Neovim config (lazy.nvim, treesitter, colorizer)
├── bin/           Helper scripts (shortcuts, power-menu, workspace-switcher, etc.)
├── fallback/      Safe fallback theme files for first boot
├── docs/          Troubleshooting, VM setup, keybind reference
├── tests/         Installer test suite
└── install.sh     Multi-distro installer
```

---

## Keybinds

`SUPER` is the Windows/Meta key. Full list any time with `shortcuts` or
**Super+Shift+?**

| Key | Action |
|---|---|
| `Super + Return` | Terminal (Kitty) |
| `Super + Space` | App launcher (Wofi) |
| `Super + B` | Password manager (rofi-rbw) |
| `Super + T` | Theme picker |
| `Super + Shift + W` | Workspace switcher (Wofi) |
| `Super + Shift + P` | Power menu (Wofi) |
| `Super + Shift + ?` | Keybind cheat sheet |
| `Super + Q` | Close window |
| `Super + H/J/K/L` | Focus (vim directions) |
| `Super + Shift + H/J/K/L` | Move window |
| `Super + Ctrl + H/J/K/L` | Resize window |
| `Super + 1..0` | Switch workspace |
| `Super + Shift + 1..0` | Send window to workspace |
| `Super + F` | Fullscreen |
| `Super + V` | Toggle floating |
| `Print` / `Super + S` | Screenshot region → clipboard |

Edit `hypr/conf/keybinds.conf` to customize, then `hyprctl reload`.

---

## Helper commands

| Command | What it does | Source |
|---|---|---|
| `shortcuts` | Print the keybind + command cheat sheet | this repo |
| `theme [name]` | Switch/list themes (regenerates everything, live) | themes repo |
| `theme-new <name>` | Scaffold a new theme from an existing one | themes repo |
| `theme-menu` | Wofi theme picker | themes repo |
| `wallgen [name]` | (Re)generate blurry-blob wallpapers | themes repo |

---

## Reusable parts

These folders are self-contained — grab just the one you want, no Hyprland
required:

- **`kitty/`** — terminal config with its own palette. See `kitty/README.md`.
- **`zsh/`** — managed Zsh profile using Oh My Zsh + Starship. Add personal
  shell changes to `~/.zshrc.local` (sourced automatically).
- **`starship/`** — Powerlevel10k-style prompt config. See `starship/README.md`.
- **`waybar/`** — clean top bar for any wlroots compositor. Colors come from
  `generated/theme.css` via `@import`.

---

## Troubleshooting

### Hyprland won't start / config errors

```sh
hyprctl configerrors    # shows exactly what's wrong, with file + line
hyprctl reload          # apply config changes live
```

### "My desktop environment is gone"

It isn't. Log out and select your DE at the login screen. Hyprland is a
separate session, not a replacement.

### Fonts look wrong / missing icons

The Nerd Font may not have installed correctly. On Arch:
```sh
sudo pacman -S ttf-jetbrains-mono-nerd
```
On other distros, re-run the installer or manually download from
[nerdfonts.com](https://www.nerdfonts.com/).

### `bat` / `fd` command not found (Debian/Ubuntu)

These are installed as `batcat` and `fdfind`. The installer creates symlinks
in `~/.local/bin/`. If they're missing:
```sh
ln -sf "$(command -v batcat)" ~/.local/bin/bat
ln -sf "$(command -v fdfind)" ~/.local/bin/fd
```

### Blur/animations are laggy (VM)

You're likely using software rendering. See
[docs/VM-GUEST-SETUP.md](docs/VM-GUEST-SETUP.md) for virgl GPU acceleration.

### Full troubleshooting

- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** — spice-vdagent,
  resolution, GPU acceleration, Hyprland config, SSH
- **[docs/VM-GUEST-SETUP.md](docs/VM-GUEST-SETUP.md)** — complete VM guest
  setup procedure for QEMU/KVM/SPICE

---

## Credits

Theme palettes are adapted from their upstream projects (Catppuccin, Dracula,
Nord, Gruvbox, Tokyo Night, Everforest, Kanagawa, Solarized, One Dark, Monokai,
Material). See the `themes` repo for per-theme attribution.
