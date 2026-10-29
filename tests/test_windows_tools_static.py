"""Windows read-only tools and safe-browser contracts; no PowerShell is executed."""
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "windows/claude-switch.ps1"


class WindowsToolsStaticTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = CORE.read_text(encoding="utf-8-sig")

    def test_read_only_tool_commands_are_registered(self):
        for name in ("Get-Fingerprint", "Get-CliInfo", "Open-SafeUrl", "Invoke-ProxyDiagnostics"):
            self.assertIn(f"function {name}", self.core)
        for command in ("fingerprint", "cli-info", "open-safe", "diagnose-proxy"):
            self.assertIn(f"'{command}'", self.core)

    def test_fingerprint_and_cli_info_use_windows_read_only_apis(self):
        self.assertIn("Get-CimInstance", self.core)
        self.assertIn("Win32_VideoController", self.core)
        self.assertIn("Win32_ComputerSystem", self.core)
        self.assertIn("Get-Command claude", self.core)
        self.assertIn("claude-code", self.core)
        self.assertIn("@anthropic-ai/claude-code", self.core)

    def test_open_safe_isolated_profile_and_cleanup(self):
        start = self.core.index("function Open-SafeUrl")
        body = self.core[start:self.core.index("\nfunction ", start)]
        self.assertIn("http", body)
        self.assertIn("https", body)
        self.assertIn("Test-TunUp", body)
        self.assertIn("Test-ProxyAlive", body)
        self.assertIn("--user-data-dir=", body)
        self.assertIn("--disable-extensions", body)
        self.assertIn("--force-webrtc-ip-handling-policy=disable_non_proxied_udp", body)
        self.assertIn("ConvertTo-WindowsCommandLine", body)
        self.assertIn("Wait-Process", body)
        self.assertIn("Remove-Item", body)

    def test_proxy_diagnostics_do_not_create_state_or_client_log(self):
        self.assertIn("$args[0] -ne 'diagnose-proxy'", self.core)
        self.assertIn("if ($command -ne 'diagnose-proxy')", self.core)

    def test_proxy_diagnostics_use_explicit_sanitized_curl(self):
        start = self.core.index("function Invoke-ProxyDiagnostics")
        body = self.core[start:self.core.index("\nfunction ", start)]
        self.assertIn("RedirectStandardInput", body)
        self.assertIn("'-q'", body)
        self.assertIn("'--config'", body)
        self.assertIn("'--noproxy'", body)
        self.assertIn("EnvironmentVariables.Clear", body)
        self.assertIn("WaitForExit(15000)", body)
        self.assertIn("ssl_verify_result", body)
        self.assertIn("$uri.Host.Trim('[',']')", body)
        self.assertIn("configuration_error", body)
        self.assertIn("transport_reached", body)
        self.assertIn("launch_allowed", body)
        self.assertIn("system_modified", body)


if __name__ == "__main__":
    unittest.main()
