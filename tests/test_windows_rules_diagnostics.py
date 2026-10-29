"""Windows「规则置顶」诊断的静态回归。

背景：`规则置顶=warn:规则已写入但无法验证内核加载` 原来只有结论没有原因，
用户无法判断是接口没配、端口不对、secret 不匹配还是超时。这组用例锁住：

1. 控制接口地址会依次读 clash-verge.yaml / config.yaml / verge.yaml
2. 异常被归类成 no-endpoint / connect-failed / auth-failed / timeout
3. /rules 超时放宽到 8 秒
4. 检查与一键修复的输出都带原因
5. rules-status 是只读命令，且打印可定位问题的字段

只读脚本文本，不执行 PowerShell，也不接触真实 Clash。
"""

import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
CORE = ROOT / "windows" / "claude-switch.ps1"


class WindowsRulesDiagnosticsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw = CORE.read_bytes()
        cls.text = cls.raw.decode("utf-8-sig")

    def test_core_keeps_bom_and_lf(self):
        self.assertTrue(self.raw.startswith(b"\xef\xbb\xbf"), "claude-switch.ps1 必须保持 UTF-8 BOM")
        self.assertEqual(self.raw.count(b"\r\n"), 0)

    def test_reads_external_controller_from_verge_yaml(self):
        self.assertIn("@('clash-verge.yaml', 'config.yaml', 'verge.yaml')", self.text)
        self.assertIn("source = $name", self.text)

    def test_api_failures_are_classified(self):
        self.assertIn("function Get-ClashApiError", self.text)
        self.assertIn("function Get-ClashApiHint", self.text)
        for reason in ("'no-endpoint'", "'connect-failed'", "'auth-failed'", "'timeout'"):
            self.assertIn(reason, self.text)

    def test_rules_timeout_is_eight_seconds(self):
        self.assertIn("Invoke-ClashApi '/rules' 8", self.text)
        self.assertIn("Invoke-ClashApi '/configs' 3", self.text)

    def test_warning_and_fix_carry_the_reason(self):
        self.assertIn(
            "规则已写入但无法验证内核加载($(Get-ClashApiHint $rulesInfo.reason))",
            self.text,
        )
        self.assertIn(
            "FIX:规则已写入但无法验证内核加载($(Get-ClashApiHint $rulesInfo.reason))",
            self.text,
        )

    def test_rules_status_is_read_only_and_dispatched(self):
        self.assertIn("'rules-status' { Invoke-RulesStatus }", self.text)
        # 只读：不得为它创建状态目录
        self.assertIn("$args[0] -ne 'rules-status'", self.text)
        self.assertIn("|rules-status", self.text)

    def test_rules_status_prints_diagnostics(self):
        body = self.text[self.text.index("function Invoke-RulesStatus"):]
        for field in ('"mode=$(Get-ClashMode)"', "api=source=", "configs=", "rules=", "script="):
            self.assertIn(field, body)


if __name__ == "__main__":
    unittest.main()
