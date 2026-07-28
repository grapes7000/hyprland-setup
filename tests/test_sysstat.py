"""Tests for waybar sysstat module."""
import importlib.util
import importlib.machinery
import json
import os
import sys
import tempfile
import types
import pytest

SCRIPT_PATH = os.path.join(
    os.path.dirname(__file__), "..", "waybar", "scripts", "sysstat.py"
)
spec = importlib.util.spec_from_file_location("sysstat", SCRIPT_PATH)
sysstat = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sysstat)


class TestReadMemory:
    def test_parses_meminfo(self, tmp_path):
        meminfo = tmp_path / "meminfo"
        meminfo.write_text(
            "MemTotal:       16384000 kB\n"
            "MemFree:         4096000 kB\n"
            "MemAvailable:    8192000 kB\n"
        )
        original = sysstat.__builtins__ if hasattr(sysstat, '__builtins__') else {}
        import builtins
        real_open = builtins.open

        def mock_open(path, *a, **kw):
            if path == "/proc/meminfo":
                return real_open(str(meminfo), *a, **kw)
            return real_open(path, *a, **kw)

        builtins.open = mock_open
        try:
            result = sysstat.read_memory()
        finally:
            builtins.open = real_open

        assert result is not None
        pct, used, total = result
        assert 0 <= pct <= 100
        assert total > 0


class TestReadDisk:
    def _make_statvfs_result(self, f_blocks, f_frsize, f_bavail):
        result = types.SimpleNamespace()
        result.f_blocks = f_blocks
        result.f_frsize = f_frsize
        result.f_bavail = f_bavail
        result.f_bsize = f_frsize
        result.f_bfree = f_bavail
        result.f_files = 1000000
        result.f_ffree = 500000
        result.f_favail = 500000
        result.f_flag = 0
        result.f_namemax = 255
        return result

    def test_reads_disk_deterministic(self, monkeypatch):
        fake = self._make_statvfs_result(
            f_blocks=1000000, f_frsize=4096, f_bavail=400000
        )
        monkeypatch.setattr(os, "statvfs", lambda path: fake)
        result = sysstat.read_disk()
        assert result is not None
        pct, used, total = result
        assert pct == 60
        total_bytes = 1000000 * 4096
        free_bytes = 400000 * 4096
        used_bytes = total_bytes - free_bytes
        assert used == round(used_bytes / (1024 ** 3), 1)
        assert total == round(total_bytes / (1024 ** 3), 1)

    def test_zero_total_returns_none(self, monkeypatch):
        fake = self._make_statvfs_result(f_blocks=0, f_frsize=4096, f_bavail=0)
        monkeypatch.setattr(os, "statvfs", lambda path: fake)
        result = sysstat.read_disk()
        assert result is None

    def test_statvfs_oserror_returns_none(self, monkeypatch):
        def raise_oserror(path):
            raise OSError("no such device")
        monkeypatch.setattr(os, "statvfs", raise_oserror)
        result = sysstat.read_disk()
        assert result is None


class TestReadUptime:
    def test_reads_uptime(self):
        result = sysstat.read_uptime()
        assert result is not None
        assert "m" in result


class TestReadTemp:
    def test_handles_missing_temp(self):
        result = sysstat.read_temp()
        assert result is None or isinstance(result, int)


class TestMainOutput:
    def test_outputs_valid_json(self, capsys):
        sysstat.main()
        captured = capsys.readouterr()
        data = json.loads(captured.out)
        assert "text" in data
        assert "tooltip" in data
        assert "class" in data
        assert isinstance(data["class"], list)
        assert len(data["class"]) > 0

    def test_warning_class_when_metric_high(self, monkeypatch, capsys):
        monkeypatch.setattr(sysstat, "read_cpu", lambda: 80)
        monkeypatch.setattr(sysstat, "read_memory", lambda: (50, 8.0, 16.0))
        monkeypatch.setattr(sysstat, "read_disk", lambda: (50, 100.0, 200.0))
        monkeypatch.setattr(sysstat, "read_uptime", lambda: "5h 30m")
        monkeypatch.setattr(sysstat, "read_load", lambda: "1.5")
        monkeypatch.setattr(sysstat, "read_temp", lambda: 55)
        sysstat.main()
        data = json.loads(capsys.readouterr().out)
        assert "warning" in data["class"]
        assert "critical" not in data["class"]

    def test_critical_class_when_metric_very_high(self, monkeypatch, capsys):
        monkeypatch.setattr(sysstat, "read_cpu", lambda: 95)
        monkeypatch.setattr(sysstat, "read_memory", lambda: (95, 15.2, 16.0))
        monkeypatch.setattr(sysstat, "read_disk", lambda: (50, 100.0, 200.0))
        monkeypatch.setattr(sysstat, "read_uptime", lambda: "2h 10m")
        monkeypatch.setattr(sysstat, "read_load", lambda: "4.0")
        monkeypatch.setattr(sysstat, "read_temp", lambda: 80)
        sysstat.main()
        data = json.loads(capsys.readouterr().out)
        assert "critical" in data["class"]

    def test_fallback_text_and_normal_class_when_all_metrics_unavailable(
        self, monkeypatch, capsys
    ):
        monkeypatch.setattr(sysstat, "read_cpu", lambda: None)
        monkeypatch.setattr(sysstat, "read_memory", lambda: None)
        monkeypatch.setattr(sysstat, "read_disk", lambda: None)
        monkeypatch.setattr(sysstat, "read_uptime", lambda: None)
        monkeypatch.setattr(sysstat, "read_load", lambda: None)
        monkeypatch.setattr(sysstat, "read_temp", lambda: None)
        sysstat.main()
        data = json.loads(capsys.readouterr().out)
        assert data["text"] == "…"
        assert data["class"] == ["normal"]
        assert data["tooltip"] == ""
