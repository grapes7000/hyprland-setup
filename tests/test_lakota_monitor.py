from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MONITOR = ROOT / "hypr/lakota-monitor.lua"


def test_vm_monitor_uses_available_4k_mode():
    source = MONITOR.read_text()
    assert 'output = "Virtual-1"' in source
    assert 'mode = "3840x2160@60"' in source
    assert "scale = 1" in source
    assert 'name = "qemu-qemu-usb-tablet"' in source
    assert "enabled = false" in source
    assert 'hl.env("QT_SCALE_FACTOR", "2")' in source
    assert 'hl.env("GDK_SCALE", "2")' in source
    assert 'hl.env("XCURSOR_SIZE", "48")' in source

    environment = (ROOT / "hypr/lakota-hidpi.env").read_text()
    assert "QT_SCALE_FACTOR=2" in environment
    assert "GDK_SCALE=2" in environment
