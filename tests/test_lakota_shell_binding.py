from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BINDING = ROOT / "hypr/lakota-shell.lua"


def test_launcher_binding_is_targeted():
    source = BINDING.read_text()
    assert '"SUPER + SPACE"' in source
    assert "qs -c lakota-shell ipc call launcher toggle" in source
    assert "pkill" not in source
    assert "caelestia" not in source.lower()
