"""Windows 保镖计划任务持久化与存活校验静态回归(Issue #54,可在 macOS/Linux CI 运行)。"""
import pathlib
import unittest

from tests.test_windows_egress_retry_static import function_body


ROOT = pathlib.Path(__file__).resolve().parents[1]
INSTALL = ROOT / "windows/install.ps1"
CORE = ROOT / "windows/claude-switch.ps1"
GUARD = ROOT / "windows/claude-bodyguard.ps1"


class WindowsBodyguardStaticTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.install_raw = INSTALL.read_bytes()
        cls.core_raw = CORE.read_bytes()
        cls.guard_raw = GUARD.read_bytes()
        cls.install = cls.install_raw.decode("utf-8-sig")
        cls.core = cls.core_raw.decode("utf-8-sig")
        cls.guard = cls.guard_raw.decode("utf-8-sig")

    def test_all_modified_ps1_keep_utf8_bom_and_lf(self):
        for name, raw in (("install.ps1", self.install_raw),
                          ("claude-switch.ps1", self.core_raw),
                          ("claude-bodyguard.ps1", self.guard_raw)):
            self.assertTrue(raw.startswith(b"\xef\xbb\xbf"), f"{name} 必须保持 UTF-8 BOM")
            self.assertEqual(raw.count(b"\r\n"), 0, f"{name} 不得引入 CRLF")

    def test_installer_registers_task_without_72h_or_battery_limits(self):
        self.assertIn("New-ScheduledTaskSettingsSet", self.install)
        for flag in (
            "-ExecutionTimeLimit ([TimeSpan]::Zero)",
            "-AllowStartIfOnBatteries",
            "-DontStopIfGoingOnBatteries",
            "-RestartCount 3",
            "-RestartInterval (New-TimeSpan -Minutes 1)",
            "-MultipleInstances IgnoreNew",
            "-Settings $settings",
        ):
            self.assertIn(flag, self.install, f"install.ps1 缺少计划任务加固参数: {flag}")

    def test_bodyguard_polls_every_3s_and_matches_verge_mihomo_variants(self):
        self.assertIn("Start-Sleep -Seconds 3", self.guard)
        self.assertNotIn("Start-Sleep -Seconds 10", self.guard)
        self.assertIn("'verge-mihomo*'", self.guard)
        self.assertIn("'verge-mihomo*'", function_body(self.core, "Test-ProxyAlive"))

    def test_checkdetail_verifies_bodyguard_alive_and_task_settings(self):
        detail = function_body(self.core, "Invoke-CheckDetail")
        self.assertIn("Get-BodyguardStatus", detail)
        self.assertNotIn('if ($bg) { "保镖=ok" }', detail)
        status_fn = function_body(self.core, "Get-BodyguardStatus")
        self.assertIn("Test-BodyguardAlive", status_fn)
        self.assertIn("Test-BodyguardTaskHardened", status_fn)
        self.assertIn("保镖=fail:未运行", status_fn)
        self.assertIn("保镖=warn:运行中,但计划任务含72h或电池限制", status_fn)

    def test_fix_repairs_stopped_or_unhardened_bodyguard_task(self):
        fix_fn = function_body(self.core, "Invoke-Fix")
        self.assertIn("Test-BodyguardTaskHardened", fix_fn)
        self.assertIn("Test-BodyguardAlive", fix_fn)
        self.assertIn("New-ScheduledTaskSettingsSet", fix_fn)
        self.assertIn("-AllowStartIfOnBatteries", fix_fn)
        self.assertIn("-DontStopIfGoingOnBatteries", fix_fn)

    def test_windows_bodyguard_integration_test_is_wired_into_ci(self):
        asn_test = (ROOT / "tests/windows-asn-integration.ps1").read_text(encoding="utf-8-sig")
        self.assertIn("windows-bodyguard-integration.ps1", asn_test)


if __name__ == "__main__":
    unittest.main()
