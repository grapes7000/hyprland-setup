#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

def runtime_state(name: str) -> Path:
    root = Path(os.environ["XDG_RUNTIME_DIR"]) if os.environ.get("XDG_RUNTIME_DIR") else Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "waybar-panels"
    try:
        root.mkdir(parents=True, exist_ok=True, mode=0o700)
        root.chmod(0o700)
    except OSError:
        pass
    return root / name


NETWORK_STATE = runtime_state("network.json")


def run(*args: str) -> str:
    try:
        return subprocess.run(args, check=False, capture_output=True, text=True, timeout=2).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""


def audio() -> dict[str, str]:
    volume = run("pamixer", "--get-volume") if shutil.which("pamixer") else ""
    muted = run("pamixer", "--get-mute") if shutil.which("pamixer") else ""
    status = run("playerctl", "status") if shutil.which("playerctl") else "Unavailable"
    return {"volume": volume or "Unavailable", "muted": "Muted" if muted == "true" else "Unmuted", "microphone": "Muted" if run("pamixer", "--default-source", "--get-mute") == "true" else "Unmuted", "device": run("pactl", "get-default-sink") or "Unavailable", "title": run("playerctl", "metadata", "title") or "Unavailable", "artist": run("playerctl", "metadata", "artist") or "", "status": status, "progress": run("playerctl", "position") or "0"}


def network() -> dict[str, str]:
    route = run("ip", "route", "show", "default").split()
    device = route[4] if len(route) > 4 else "Unavailable"
    address = run("ip", "-4", "-o", "addr", "show", "dev", device).split()
    ipv4 = address[3].split("/")[0] if len(address) > 3 else "Unavailable"
    gateway = route[2] if len(route) > 2 and route[0] == "default" and route[1] == "via" else "Unavailable"
    active_wifi = run("nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "dev", "wifi")
    fields = next((line.split(":", 3) for line in active_wifi.splitlines() if line.startswith("yes:")), [])
    ssid, signal, security = (fields[1], fields[2], fields[3]) if len(fields) == 4 else ("Ethernet" if device != "Unavailable" else "Unavailable", "Unavailable", "")
    received, sent = interface_bytes(device)
    down, up = transfer_rate(device, received, sent)
    ping = run("ping", "-c", "1", "-W", "1", gateway if gateway != "Unavailable" else "1.1.1.1")
    latency = next((word.removeprefix("time=") for word in ping.split() if word.startswith("time=")), "Unavailable")
    return {"interface": device, "ssid": ssid or "Unavailable", "signal": signal or "Unavailable", "security": security or "", "ipv4": ipv4, "gateway": gateway, "down": down, "up": up, "state": "Connected" if device != "Unavailable" else "Disconnected", "mullvad": run("mullvad", "status") or "Unavailable", "tailscale": run("tailscale", "ip", "-4") or "Unavailable", "ping": latency}


def interface_bytes(device: str) -> tuple[int, int]:
    try:
        values = Path("/proc/net/dev").read_text().splitlines()
        line = next(line for line in values if line.strip().startswith(f"{device}:"))
        fields = line.split(":", 1)[1].split()
        return int(fields[0]), int(fields[8])
    except (OSError, StopIteration, ValueError, IndexError):
        return 0, 0


def transfer_rate(device: str, received: int, sent: int) -> tuple[str, str]:
    try:
        prior = json.loads(NETWORK_STATE.read_text())
        down = max(0, received - int(prior["received"])) if prior["device"] == device else 0
        up = max(0, sent - int(prior["sent"])) if prior["device"] == device else 0
    except (OSError, ValueError, KeyError, json.JSONDecodeError):
        down, up = 0, 0
    try:
        NETWORK_STATE.write_text(json.dumps({"device": device, "received": received, "sent": sent}))
    except OSError:
        pass
    return (f"{down / 1024:.0f} KiB/s" if down else "Idle", f"{up / 1024:.0f} KiB/s" if up else "Idle")


def clock() -> dict[str, str]:
    return {"time": run("date", "+%H:%M:%S"), "date": run("date", "+%A, %B %d, %Y"), "timezone": run("date", "+%Z"), "calendar": run("cal") or "Unavailable"}


def apps() -> dict[str, object]:
    try:
        clients = json.loads(run("hyprctl", "clients", "-j"))
        active = json.loads(run("hyprctl", "activeworkspace", "-j")).get("id", 0)
    except (json.JSONDecodeError, AttributeError):
        return {"apps": []}
    rows = [{"address": str(item.get("address", "")), "name": str(item.get("class") or "Unknown"), "title": str(item.get("title") or ""), "workspace": str(item.get("workspace", {}).get("id", "")), "active": item.get("workspace", {}).get("id") == active} for item in clients if item.get("mapped") and item.get("workspace", {}).get("id", -1) > 0]
    rows.sort(key=lambda item: (not item["active"], item["name"].lower()))
    return {"apps": rows[:12]}


def main() -> int:
    name = sys.argv[1] if len(sys.argv) == 2 else ""
    payload = {"audio": audio, "network": network, "clock": clock, "apps": apps}.get(name)
    if payload is None:
        return 2
    print(json.dumps(payload(), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
