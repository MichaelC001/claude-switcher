"""Windows encrypted snapshot contracts; no PowerShell is executed."""
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "windows/claude-switch.ps1"


class WindowsSnapshotStaticTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = CORE.read_text(encoding="utf-8-sig")

    def test_snapshot_commands_and_crypto_format(self):
        self.assertIn("function Export-EncryptedSnapshot", self.core)
        self.assertIn("function Import-EncryptedSnapshot", self.core)
        self.assertIn("'snapshot-export'", self.core)
        self.assertIn("'snapshot-import'", self.core)
        self.assertIn("Aes", self.core)
        self.assertIn("CreateEncryptor", self.core)
        self.assertIn("CreateDecryptor", self.core)
        self.assertIn("Rfc2898DeriveBytes", self.core)
        self.assertIn("SHA256", self.core)
        self.assertIn("200000", self.core)
        self.assertIn("HMACSHA256", self.core)
        self.assertIn("CSNAP001", self.core)

    def test_crypto_streams_and_authenticates_before_extraction(self):
        self.assertIn("TransformBlock", self.core)
        self.assertIn("CryptoStream", self.core)
        self.assertNotIn("ReadAllBytes", self.core)
        verify = self.core.index("Test-SnapshotAuthentication")
        extract = self.core.index("Expand-SnapshotArchive", verify)
        self.assertLess(verify, extract)

    def test_archive_rejects_traversal_rooted_paths_and_links(self):
        self.assertIn("function Test-SnapshotArchive", self.core)
        self.assertIn("IsPathRooted", self.core)
        self.assertIn("'..'", self.core)
        self.assertIn("$name.Contains(':')", self.core)
        self.assertIn("ExternalAttributes", self.core)
        self.assertIn("0xA000", self.core)

    def test_snapshot_guards_never_overwrite_account_data(self):
        for text in ("正在使用中", "目标文件已存在", "已有快照", "账号不匹配", "密码至少 8 位"):
            self.assertIn(text, self.core)
        self.assertIn("$target.new", self.core)
        self.assertIn("--password-stdin", self.core)


if __name__ == "__main__":
    unittest.main()
