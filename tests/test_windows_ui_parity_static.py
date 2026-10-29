"""Windows WPF feature-parity and interaction contracts; XAML is parsed, not rendered."""
from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
UI = ROOT / "windows/SwitcherUI.ps1"


class WindowsUiParityStaticTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ui = UI.read_text(encoding="utf-8-sig")
        cls.xaml = re.search(r'\$xaml = @"\n(.*?)\n"@', cls.ui, re.S).group(1)
        cls.root = ET.fromstring(cls.xaml)

    def test_main_xaml_is_unique_and_resizable(self):
        x_name = "{http://schemas.microsoft.com/winfx/2006/xaml}Name"
        names = [node.get(x_name) for node in self.root.iter() if node.get(x_name)]
        self.assertEqual(len(names), len(set(names)))
        self.assertEqual(self.root.get("ResizeMode"), "CanResize")
        self.assertGreaterEqual(float(self.root.get("MinWidth")), 480)
        self.assertIn("ScrollViewer", self.xaml)

    def test_every_xaml_window_is_well_formed(self):
        variables = ("xaml", "toolsXaml", "inputXaml", "dialogXaml", "settingsXaml")
        for variable in variables:
            with self.subTest(variable=variable):
                match = re.search(rf'\${variable} = @"\n(.*?)\n"@', self.ui, re.S)
                self.assertIsNotNone(match)
                ET.fromstring(match.group(1))

    def test_four_accounts_show_live_and_archive_metadata(self):
        for slot in "ABCD":
            self.assertIn(f'x:Name="Btn{slot}"', self.xaml)
            self.assertIn(f'x:Name="Account{slot}Subtitle"', self.xaml)
        for text in ("fields['current']", "fields['accounts']", 'fields["acc$slot"]', "未初始化", "已建档"):
            self.assertIn(text, self.ui)

    def test_proxy_and_all_tool_commands_are_wired(self):
        for name in ("ProxyClient", "BtnTools", "BtnFingerprint", "BtnCliInfo", "BtnOpenSafe", "BtnRegion", "BtnSnapshotExport", "BtnSnapshotImport"):
            self.assertIn(name, self.ui)
        for mode in ("clash-verge", "flclash", "sing-box", "clashx", "surge", "wireguard", "other", "auto"):
            self.assertIn(mode, self.ui)
        for command in ("fingerprint", "cli-info", "open-safe", "set-region", "snapshot-export", "snapshot-import"):
            self.assertIn(command, self.ui)

    def test_long_operations_are_serialized_and_audited(self):
        self.assertIn("Start-Job", self.ui)
        self.assertIn("DispatcherTimer", self.ui)
        self.assertIn("$script:isBusy", self.ui)
        self.assertIn("$script:environmentReady", self.ui)
        self.assertIn("Add_Closing", self.ui)
        self.assertIn("$_.Cancel = $true", self.ui)
        switch = self.ui[self.ui.index("function Switch-To"):]
        switch = switch[:switch.index("\nfunction ")]
        self.assertIn("environmentReady", switch)
        self.assertIn("$script:pendingSwitch = $target", switch)
        self.assertLess(switch.index("$script:pendingSwitch = $target"), switch.index("Refresh-Checks"))
        complete = self.ui[self.ui.index("function Complete-UiOperation"):]
        self.assertIn("$script:pendingSwitch", complete)

    def test_snapshot_passwords_use_stdin_not_arguments(self):
        self.assertIn("PasswordBox", self.ui)
        self.assertIn("--password-stdin", self.ui)
        self.assertIn("StandardInput", self.ui)
        self.assertNotRegex(self.ui, r"snapshot-(?:export|import)[^\n]*Password")

    def test_states_remain_semantic(self):
        self.assertRegex(self.ui, r"'skip'\s*\{")
        self.assertIn("#FF6B7280", self.ui)
        self.assertIn("IsEnabled = $false", self.ui)
        self.assertIn("ToolTip", self.xaml)


if __name__ == "__main__":
    unittest.main()
