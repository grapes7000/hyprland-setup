# Hyprland / qtile on an Arch KVM Guest — Troubleshooting Playbook

A field guide to every problem hit while setting up a themed Wayland desktop
(qtile, then Hyprland) inside a QEMU/KVM guest driven over SPICE, on an Arch
Linux guest running under a CachyOS + qtile (wlroots) host.

Written so that **future-you can fix these in minutes instead of hours.** Each
entry is: *symptom → root cause → fix → why*.

## Waybar or homepage is missing

Desktop mode installs and verifies both launchers. Their startup output is kept
instead of disappearing with the Hyprland session:

```sh
cat ~/.local/state/hyprland-setup/waybar.log
cat ~/.local/state/hyprland-setup/homepage.log
```

Restart either component without logging out:

```sh
bash ~/.config/waybar/launch.sh
pkill -x eww
bash ~/.config/eww/launch.sh
```

If `eww` is missing, rerun `./install.sh --desktop`. Desktop mode installs its
GTK build dependencies and builds the pinned Wayland release automatically.

---

## Table of Contents

1. [spice-vdagent user service fails (clipboard/resolution broken)](#1-spice-vdagent-user-service-fails)
2. [Dynamic resolution doesn't work on wlroots](#2-dynamic-resolution-on-wlroots)
3. [No GPU acceleration — llvmpipe / laggy blur](#3-no-gpu-acceleration-virgl)
4. [Enabling virgl breaks VM boot (EGL_NOT_INITIALIZED)](#4-virgl-breaks-boot-egl_not_initialized)
5. [Hyprland 0.56 config option changes](#5-hyprland-056-config-changes)
6. [hyprpaper won't set the wallpaper](#6-hyprpaper-wont-set-wallpaper)
7. [Zsh shell notes](#7-zsh-shell-notes)
8. [SSH into the guest from the host](#8-ssh-into-the-guest)
9. [Quick reference: the golden commands](#9-quick-reference)

---

## 1. spice-vdagent user service fails

**Symptom**
- `spice-vdagent.service` (user unit) dies instantly with
  `status=1/FAILURE`, no useful log.
- Running `/usr/bin/spice-vdagent -x -d` **by hand in a terminal works fine.**
- Clipboard sync host↔guest and dynamic resolution don't work.

**Root cause (there are actually three layers):**

1. **Missing `DISPLAY`.** spice-vdagent is fundamentally an X client (it talks
   to Xwayland). Your interactive shell has `DISPLAY` set, but the systemd
   **user** service environment does **not** — importing `WAYLAND_DISPLAY`
   alone is not enough. The service dies with `cannot open display:`.

2. **The error is hidden.** Arch's packaged unit ships
   `StandardError=null` (to avoid duplicate syslog+journal lines). So even with
   `-d`, the debug output is thrown in the bin — you see `vdagent started`
   then nothing. To *see* the real error, temporarily override:
   ```ini
   # ~/.config/systemd/user/spice-vdagent.service.d/override.conf
   [Service]
   StandardError=journal
   ExecStart=
   ExecStart=/usr/bin/spice-vdagent -x -d
   ```
   Then `systemctl --user daemon-reload && systemctl --user restart spice-vdagent`
   and read `journalctl --user -u spice-vdagent -b`.

3. **A lingering agent.** Only ONE spice-vdagent may connect to
   `spice-vdagentd` per session. If a stray instance is already running (e.g. a
   manual test you forgot to kill), the service connects, does one thing, and
   exits `status=0`. Kill the stray: `pkill -x spice-vdagent`.

**The fix (robust, survives reboots):**

Have the **compositor** push `DISPLAY` into the systemd user + dbus environment
once Xwayland is up, then (re)start the agent. This works because the
compositor sets `DISPLAY` for its children only after Xwayland is running.

- **Hyprland** — in `~/.config/hypr/conf/autostart.conf`:
  ```
  exec-once = dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP
  exec-once = systemctl --user import-environment DISPLAY WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP
  exec-once = systemctl --user restart spice-vdagent.service
  ```
- **qtile** (wayland) — in your autostart script (run from the
  `startup_once` hook), after Xwayland is available:
  ```sh
  if command -v systemctl >/dev/null 2>&1; then
      systemctl --user import-environment DISPLAY WAYLAND_DISPLAY
      systemctl --user restart spice-vdagent.service 2>/dev/null || true
  fi
  ```

**Also required — device permissions.** The virtio-serial port must be
accessible to your user. Add a udev rule:
```
# /etc/udev/rules.d/50-spice-vdagent.rules
SUBSYSTEM=="virtio-ports", KERNEL=="vport*", TAG+="uaccess"
```
Then `sudo udevadm control --reload && sudo udevadm trigger`. Verify with
`getfacl /dev/vport*` — your user should have `rw-`.

**Verify it's fixed:** `systemctl --user is-active spice-vdagent` → `active`,
and the journal shows resolution + clipboard traffic instead of an instant exit.

> **Why "works by hand but not as a service" is the classic tell:** the
> interactive shell inherits a rich environment (`DISPLAY`, dbus address,
> a login session); the user service gets a deliberately minimal one. Whenever
> a GUI-adjacent thing behaves this way, suspect a missing env var first.

---

## 2. Dynamic resolution on wlroots

**Symptom**
- Guest stuck at 1280x800; host-window resize doesn't drive the guest.
- An `xrandr --newmode / --addmode` script "runs" but nothing changes.

**Root cause**
On a **wlroots** compositor (qtile-wayland, Hyprland, sway) `xrandr` only
touches the **Xwayland** virtual screen — it **cannot** change the real Wayland
output. spice-vdagent's own resize path also targets X/mutter and does not
drive wlroots outputs.

**Fix — use `wlr-randr`, not xrandr:**
```sh
wlr-randr --output Virtual-1 --mode 2560x1440
```
List available modes (they come from the virtio-gpu EDID) with a bare
`wlr-randr`. On Hyprland you can also just set it in config:
```
monitor = Virtual-1, 2560x1440@60, 0x0, 1
```

**Gotcha:** if your autostart guards the resolution script with
`command -v xrandr`, switch that guard to `command -v wlr-randr`.

> **Note:** true *host-driven* dynamic resize (drag the virt-manager window →
> guest follows) is a weak spot on a wlroots **guest** — there's no mutter for
> spice-vdagent to talk to, and the SPICE↔RandR output mapping fails
> (`xrandr output ID NOT FOUND` in the agent log). Clipboard still works.
> For a fixed high resolution, `wlr-randr` / the `monitor` line is the answer.

---

## 3. No GPU acceleration (virgl)

**Symptom**
- Blur/animations are laggy at high resolution.
- `glxinfo | grep renderer` → `llvmpipe` (that's **CPU** software rendering).

**Root cause**
The guest is using Mesa's software rasterizer because **virgl (3D
passthrough)** is not enabled on the VM. `virtio_gpu` being loaded is not
enough; you need `accel3d` on the video device **and** OpenGL enabled on the
SPICE display so QEMU can host a real GL context.

**Fix (host side, libvirt XML):**
```xml
<video>
  <model type='virtio' heads='1' primary='yes'>
    <acceleration accel3d='yes'/>
  </model>
</video>
<graphics type='spice'>
  <listen type='none'/>
  <gl enable='yes' rendernode='/dev/dri/renderD128'/>
</graphics>
```
Apply with `virsh define` (or `virsh edit`), then **cold boot** (full shutdown +
start — a *reboot* will not re-read device XML).

**⚠️ This commonly fails to boot — see the next section before doing it.**

Verify success after boot: `glxinfo | grep renderer` should now say
`virgl` / `virtio_gpu`, not `llvmpipe`.

---

## 4. virgl breaks boot (EGL_NOT_INITIALIZED)

**Symptom**
After enabling `<gl enable='yes'>`, the VM refuses to start:
```
qemu-system-x86_64: egl: eglInitialize failed: EGL_NOT_INITIALIZED
qemu-system-x86_64: egl: render node init failed
Failed to start domain 'archlinux'
```

**Root cause**
Under the **system** libvirt daemon (`qemu:///system`), the QEMU process runs
as a restricted user (e.g. `qemu`) that **cannot open the host GPU render node
`/dev/dri/renderD128`**, so it can't initialize EGL. Check:
```sh
getent group render          # who may use renderD128 (mode 0660, group 'render')
```
If the QEMU user isn't in `render`, EGL init fails.

**Fixes (pick one, all host-side, need sudo):**
1. Add the QEMU user to the GPU groups, then restart libvirt:
   ```sh
   sudo usermod -aG render,video qemu
   sudo systemctl restart libvirtd
   ```
2. Or set QEMU to run as your user in `/etc/libvirt/qemu.conf`:
   ```
   user = "yourname"
   group = "yourname"
   ```
   then `sudo systemctl restart libvirtd`.
3. Or run the VM under the **session** daemon (`qemu:///session`), where QEMU
   runs as you and already has render access via logind uaccess.

**Emergency revert (VM won't boot, need it back NOW):**
Keep a backup of the working XML *before* editing:
```sh
virsh --connect qemu:///system dumpxml DOMAIN > backup.xml   # BEFORE changes
# ...to revert:
virsh --connect qemu:///system define backup.xml
virsh --connect qemu:///system start DOMAIN
```
Flipping `<gl enable='no'/>` and `accel3d='no'` also restores bootability.

> **Lesson:** always dump a backup XML before touching `<video>`/`<graphics>`,
> and test with a cold boot you can watch — a bad GL config is a hard boot fail,
> not a soft warning.

---

## 5. Hyprland 0.56 config changes

Options that moved/renamed and now throw `config option <x> does not exist`
or `invalid dispatcher`. Check your config live with:
```sh
hyprctl configerrors
```

| Old (pre-0.56)                       | 0.56 replacement                          |
|--------------------------------------|-------------------------------------------|
| `dwindle { pseudotile = true }`      | removed — use the `pseudo` dispatcher bind |
| `misc { vfr = true }`                | removed (VFR is default/managed)          |
| `gestures { workspace_swipe = true }`| gestures reworked — remove or use new `gesture =` syntax |
| `bind = ..., togglesplit`            | `bind = ..., layoutmsg, togglesplit`      |
| `windowrulev2 = ...`                 | `windowrule = ...` (v2 is deprecated; still works with a warning) |

**Shadow/blur syntax (current, nested under `decoration`):**
```
decoration {
    rounding = 12
    active_opacity = 0.95
    inactive_opacity = 0.88
    blur {
        enabled = true
        size = 8
        passes = 3
    }
    shadow {
        enabled = true
        range = 20
        render_power = 3
        color = rgba(000000cc)
    }
}
```

> **Tip:** after any config edit, `hyprctl reload` applies it live and
> `hyprctl configerrors` tells you exactly what's wrong, with file + line.
> Deprecation warnings are non-fatal; "does not exist" / "invalid dispatcher"
> are the ones that actually break a binding.

---

## 6. hyprpaper won't set the wallpaper

**Symptom**
- `hyprctl hyprpaper listloaded` → `error: invalid hyprpaper request`.
- Launching `hyprpaper` over SSH → `wl_display_connect failed (is a wayland
  compositor running?)` or `failed to create display`.

**Root cause**
GUI Wayland clients (hyprpaper, grim, etc.) need `WAYLAND_DISPLAY` **and**
`XDG_RUNTIME_DIR` pointing at the running compositor. Over a bare SSH session
those aren't set, and launching a client detached from the session can't reach
the compositor.

**Fix — run it *inside* the session.** From SSH, dispatch through Hyprland:
```sh
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export HYPRLAND_INSTANCE_SIGNATURE=$(ls "$XDG_RUNTIME_DIR/hypr" | head -1)
hyprctl dispatch exec hyprpaper           # launches it in-session
```
For grim/screenshots over SSH also export the socket:
```sh
export WAYLAND_DISPLAY=$(cd "$XDG_RUNTIME_DIR" && ls wayland-* | grep -v .lock | head -1)
grim /tmp/shot.png
```
hyprpaper reads `~/.config/hypr/hyprpaper.conf` on start, so pointing that file
at the right image and restarting it (`pkill -x hyprpaper; hyprctl dispatch
exec hyprpaper`) is the simplest wallpaper reload.

---

## 7. Zsh shell notes

The installer makes **Zsh** the login shell and uses Starship rather than
Powerlevel10k. Its managed profile puts `~/.local/bin` on `PATH`, enables fzf,
zoxide, direnv, autosuggestions, and syntax highlighting. Put customizations
in `~/.zshrc.local`; it is sourced before syntax highlighting.

When scripting a box over SSH, explicitly invoke Bash for Bash-specific syntax:
`ssh host 'bash -s' <<'REMOTE' … REMOTE`.

---

## 8. SSH into the guest

Getting a shell into a fresh Arch guest from the host:

```sh
# in the guest (from the virt-manager console):
sudo pacman -S --needed openssh
sudo systemctl enable --now sshd
sudo ufw allow 22/tcp          # if ufw is active — this was THE blocker once

# from the host:
ssh-copy-id user@<guest-ip>    # key auth, so scripts don't hit password prompts
```
Find the guest IP from the host: `sudo virsh domifaddr <domain>`.

**Gotcha we hit:** `ping` worked but port 22 was filtered — `ufw` was active
and silently dropping TCP while allowing ICMP. `sudo ufw allow 22/tcp` fixed it.
Always check `sudo systemctl is-active firewalld ufw nftables iptables` when a
port is reachable-by-ping but connection-refused/filtered.

---

## 9. Quick reference

```sh
# --- spice-vdagent ---
systemctl --user status spice-vdagent
journalctl --user -u spice-vdagent -b -o verbose
pkill -x spice-vdagent                      # clear a stray instance

# --- resolution (wlroots) ---
wlr-randr                                    # list outputs + modes
wlr-randr --output Virtual-1 --mode 2560x1440

# --- GPU check ---
glxinfo | grep -i "renderer\|direct rendering"   # llvmpipe = software, virgl = accelerated

# --- Hyprland ---
hyprctl reload
hyprctl configerrors
hyprctl monitors
hyprctl dispatch exec <program>              # launch in-session from SSH

# --- libvirt (host) ---
virsh --connect qemu:///system dumpxml DOMAIN > backup.xml
virsh --connect qemu:///system define file.xml
virsh --connect qemu:///system domstate DOMAIN
# cold boot (device XML changes need this, NOT reboot):
virsh --connect qemu:///system shutdown DOMAIN && virsh --connect qemu:///system start DOMAIN
```
