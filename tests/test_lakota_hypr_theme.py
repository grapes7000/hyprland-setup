import importlib.machinery
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_loader("lakota_hypr", importlib.machinery.SourceFileLoader("lakota_hypr", str(ROOT / "bin/lakota-hypr-theme")))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

THEME = {"name":"test", "roles":{"focus":"#112233", "accent2":"#445566", "border_normal":"#778899"}, "style":{"border_width":3,"gaps":9,"corner_radius":0,"opacity":1,"opacity_inactive":.9,"blur_on":"false","blur_strength":0,"shadow_on":"true","shadow_radius":20,"shadow_opacity":.5,"shadow_offset":-4}}


def test_render_uses_current_nested_shadow_syntax():
    output = mod.render(THEME, (0, 56, 1))
    assert "shadow = {" in output
    assert 'active_border = "rgba(112233ff)"' in output
    assert 'border_active = "rgba(445566ff)"' in output
    assert "gaps_in = 4" in output and "gaps_out = 9" in output
    assert 'offset = "0 -4"' in output


def test_install_markers_are_idempotent():
    once = "existing\n\n" + mod.BLOCK + "\n"
    assert once.count(mod.BEGIN) == 1
    assert mod.strip_block(once) == "existing\n"


def test_atomic_generation(tmp_path):
    output = tmp_path / "generated.lua"
    mod.atomic_write(output, "one\n")
    mod.atomic_write(output, "two\n")
    assert output.read_text() == "two\n"
    assert not list(tmp_path.glob(".generated.lua.*"))
