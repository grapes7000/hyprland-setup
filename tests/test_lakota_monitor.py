from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MONITOR = ROOT / "hypr/lakota-monitor.lua"


def test_vm_monitor_uses_available_4k_mode():
    source = MONITOR.read_text()
    assert 'output = "Virtual-1"' in source
    assert 'mode = "3840x2160@60"' in source
    assert "scale = 2" in source
