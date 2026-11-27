"""macOS 以太网/Wi-Fi IPv6 服务扫描与 Clash Party 客户端支持隔离回归。"""
import http.server
import json
import os
from pathlib import Path
import re
import socketserver
import subprocess
import tempfile
import threading
import unittest


ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "core" / "claude-switch.sh"
INSTALLER = ROOT / "installer" / "安装.command"

PINNED_DOMAINS = (
    "claude.ai", "claude.com", "anthropic.com", "claudeusercontent.com",
    "challenges.cloudflare.com", "datadoghq.com", "segment.io", "stripe.com",
    "stripe.network", "stripecdn.com", "intercom.io", "intercomcdn.com",
    "intercomassets.com",
)


class UnixJsonServer:
    """在临时目录提供最小 Mihomo Unix-socket HTTP 服务，不触碰真实系统网络。"""

    def __init__(self, sock_path: Path, state: dict):
        self.sock_path = sock_path
        self.state = state

        class Handler(http.server.BaseHTTPRequestHandler):
            def do_GET(handler):
                auth = state.get("secret", "")
                if auth and handler.headers.get("Authorization") != f"Bearer {auth}":
                    handler.send_response(401)
                    handler.end_headers()
                    return
                if handler.path == "/configs":
                    payload = {"mode": state.get("mode", "rule")}
                elif handler.path == "/proxies":
                    payload = state.get("proxies", {
                        "proxies": {
                            "GLOBAL": {"type": "Selector", "now": "US-Node"},
                            "US-Node": {"type": "Trojan", "udp": True},
                        }
                    })
                elif handler.path == "/rules":
                    payload = {"rules": state.get("rules", [])}
                else:
                    handler.send_response(404)
                    handler.end_headers()
                    return
                body = json.dumps(payload).encode("utf-8")
                handler.send_response(200)
                handler.send_header("Content-Type", "application/json")
                handler.send_header("Content-Length", str(len(body)))
                handler.end_headers()
                handler.wfile.write(body)

            def log_message(handler, fmt, *args):
                return

        class ThreadedUnixServer(socketserver.ThreadingMixIn, socketserver.UnixStreamServer):
            daemon_threads = True

        self.httpd = ThreadedUnixServer(str(sock_path), Handler)
        self.thread = threading.Thread(target=self.httpd.serve_forever, daemon=True)

    def __enter__(self):
        self.thread.start()
        return self

    def __exit__(self, exc_type, exc, tb):
        self.httpd.shutdown()
        self.httpd.server_close()
        try:
            self.sock_path.unlink()
        except FileNotFoundError:
            pass


class MacosIpv6AndClashPartyTests(unittest.TestCase):
    def setUp(self):
        # Unix socket 路径受约 104 字节长度限制，放在 /tmp 短路径下并在清理时移除
        self.temp = tempfile.TemporaryDirectory(dir="/tmp", prefix="csw-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "h"
        self.fakebin = self.root / "bin"
        self.sockdir = self.root / "sock"
        (self.home / ".claude-switcher").mkdir(parents=True)
        (self.home / "Library" / "Logs").mkdir(parents=True)
        (self.home / "Library" / "Application Support" / "mihomo-party").mkdir(parents=True)
        self.fakebin.mkdir()
        self.sockdir.mkdir()

        self.guard = self.root / "claude-bodyguard.sh"
        self.guard.write_text('MODE="clash-party"\n', encoding="utf-8")
        self.core = self.root / "claude-switch.sh"
        src = CORE.read_text(encoding="utf-8")
        src = src.replace("/Library/Application Support/claude-switcher/claude-bodyguard.sh", str(self.guard))
        src = re.sub(r'^PROXY_MODE="[^"]*"', 'PROXY_MODE="clash-party"', src, count=1, flags=re.M)
        self.core.write_text(src, encoding="utf-8")
        self.core.chmod(0o755)
        self._install_common_stubs()

    def stub(self, name: str, content: str):
        path = self.fakebin / name
        path.write_text(content, encoding="utf-8")
        path.chmod(0o755)

    def _install_common_stubs(self):
        (self.home / ".claude-switcher" / "stun-probe.py").write_text(
            "print('RESULT:198.51.100.7')\n", encoding="utf-8"
        )
        self.stub("pgrep", "#!/bin/sh\ncase \"$*\" in */Contents/Resources/sidecar/mihomo*) exit 0 ;; *) exit 1 ;; esac\n")
        self.stub("ifconfig", "#!/bin/sh\necho 'utun4: inet 198.18.0.1 --> 198.18.0.1 netmask 0xffff0000'\n")
        self.stub("curl", """#!/bin/sh
case "$*" in
    *cdn-cgi/trace*) printf 'ip=198.51.100.7\\nloc=US\\n' ;;
    *ipinfo.io/*/json*) printf '{"ip":"198.51.100.7","org":"AS7922 Comcast Cable"}\\n200' ;;
    *peeringdb.com*) printf '{"data":[{"asn":7922,"info_type":"Cable/DSL/ISP"}]}\\n200' ;;
    *claude.ai*|*api.anthropic.com*) printf '200' ;;
    *) printf '200' ;;
esac
""")
        self.stub("readlink", "#!/bin/sh\necho '/var/db/timezone/zoneinfo/America/New_York'\n")
        self.stub("defaults", """#!/bin/sh
case "$*" in
    *AppleLocale*) echo 'en_US' ;;
    *com.anthropic.claudefordesktop*) echo '("en-US")' ;;
    *) echo '(\n    "en-US",\n    "en-US"\n)' ;;
esac
""")
        self.stub("dig", "#!/bin/sh\necho '198.18.0.42'\n")
        self.stub("launchctl", "#!/bin/sh\nexit 0\n")
        self.stub("osascript", "#!/bin/sh\ncat > \"$CLAUDE_SWITCHER_TEST_OSA\"\nexit 0\n")
        self._stub_ethernet_networksetup(v6_mode="Off")

    def _stub_ethernet_networksetup(self, v6_mode="Off", service_name="Ethernet", include_bridge=True):
        bridge_line = "Thunderbolt Bridge\niPhone USB\n" if include_bridge else ""
        self.stub("networksetup", f"""#!/bin/sh
if [ "$1" = "-listallnetworkservices" ]; then
    printf 'An asterisk (*) denotes that a network service is disabled.\\n{service_name}\\n{bridge_line}'
    exit 0
fi
if [ "$1" = "-getinfo" ]; then
    case "$2" in
        "{service_name}")
            printf 'DHCP Configuration\\nIP address: 192.168.10.25\\nSubnet mask: 255.255.255.0\\nRouter: 192.168.10.1\\nIPv6: {v6_mode}\\nIPv6 IP address: none\\n'
            exit 0 ;;
        "Thunderbolt Bridge"|"iPhone USB")
            printf 'DHCP Configuration\\nIPv6: Automatic\\nIPv6 IP address: none\\n'
            exit 0 ;;
        *)
            printf '** Error: Unable to find %s in network database.\\n' "$2"
            exit 4 ;;
    esac
fi
if [ "$1" = "-setv6off" ]; then
    printf '%s\\n' "$2" >> "$CLAUDE_SWITCHER_SETV6_LOG"
    exit 0
fi
exit 0
""")

    def run_core(self, *args):
        env = dict(
            os.environ,
            HOME=str(self.home),
            PATH=f"{self.fakebin}:/usr/bin:/bin:/usr/sbin:/sbin",
            CLAUDE_SWITCHER_CORE=str(self.core),
            CLAUDE_SWITCHER_PARTY_SOCK_DIR=str(self.sockdir),
            CLAUDE_SWITCHER_TEST_OSA=str(self.root / "osa.txt"),
            CLAUDE_SWITCHER_SETV6_LOG=str(self.root / "setv6.log"),
        )
        return subprocess.run(
            ["/bin/bash", str(self.core), *args],
            env=env, text=True, capture_output=True, timeout=15,
        )

    def test_ethernet_only_mac_detects_and_fixes_ipv6_without_wifi(self):
        self._stub_ethernet_networksetup(v6_mode="Automatic", service_name="USB 10/100/1000 LAN")
        detail = self.run_core("checkdetail")
        self.assertEqual(detail.returncode, 0, detail.stdout + detail.stderr)
        self.assertIn("IPv6=fail:未关闭(USB 10/100/1000 LAN)", detail.stdout)

        chk = self.run_core("check")
        self.assertNotEqual(chk.returncode, 0)
        self.assertIn("IPv6:未关闭(USB 10/100/1000 LAN)", chk.stdout)

        fix = self.run_core("fix")
        self.assertEqual(fix.returncode, 0, fix.stdout + fix.stderr)
        osa = (self.root / "osa.txt").read_text(encoding="utf-8")
        self.assertIn("networksetup -setv6off 'USB 10/100/1000 LAN'", osa)
        self.assertNotIn("Thunderbolt Bridge", osa, "未插线的桥接伪服务不得被误操作")
        self.assertNotIn("Wi-Fi", osa, "仅以太网机器不应再写死 Wi-Fi")

        self._stub_ethernet_networksetup(v6_mode="Off", service_name="USB 10/100/1000 LAN")
        detail_ok = self.run_core("checkdetail")
        self.assertEqual(detail_ok.returncode, 0, detail_ok.stdout + detail_ok.stderr)
        self.assertIn("IPv6=ok:已关闭(USB 10/100/1000 LAN)", detail_ok.stdout)
        chk_ok = self.run_core("check")
        self.assertEqual(chk_ok.returncode, 0, chk_ok.stdout + chk_ok.stderr)

    def test_wifi_mac_ignores_inactive_thunderbolt_bridge_automatic_ipv6(self):
        self._stub_ethernet_networksetup(v6_mode="Off", service_name="Wi-Fi", include_bridge=True)
        detail = self.run_core("checkdetail")
        self.assertEqual(detail.returncode, 0, detail.stdout + detail.stderr)
        self.assertIn("IPv6=ok:已关闭(Wi-Fi)", detail.stdout)

    def test_unrecognized_network_services_fail_closed(self):
        self.stub("networksetup", """#!/bin/sh
if [ "$1" = "-listallnetworkservices" ]; then
    printf 'An asterisk (*) denotes that a network service is disabled.\\n*Wi-Fi\\nThunderbolt Bridge\\n'
    exit 0
fi
if [ "$1" = "-getinfo" ]; then
    printf 'DHCP Configuration\\nIPv6: Automatic\\nIPv6 IP address: none\\n'
    exit 0
fi
""")
        detail = self.run_core("checkdetail")
        self.assertEqual(detail.returncode, 0)
        self.assertIn("IPv6=fail:无法判断(未识别到网络服务)", detail.stdout)
        chk = self.run_core("check")
        self.assertNotEqual(chk.returncode, 0)
        self.assertIn("IPv6:无法判断", chk.stdout)

    def test_installer_shares_ethernet_ipv6_scan(self):
        install_src = INSTALLER.read_text(encoding="utf-8")
        fn1 = re.search(r"(?ms)^_ipv6_is_lan_wlan_service\(\) \{\n.*?^\}", install_src)
        fn2 = re.search(r"(?ms)^_ipv6_scan\(\) \{\n.*?^\}", install_src)
        self.assertIsNotNone(fn1)
        self.assertIsNotNone(fn2)
        self._stub_ethernet_networksetup(v6_mode="Automatic", service_name="Ethernet")
        snippet = f"{fn1.group(0)}\n{fn2.group(0)}\n_ipv6_scan\nprintf '%s\\n' \"$_IPV6_SCAN_STATE\"\nprintf '%s\\n' \"${{_IPV6_OPEN_SERVICES[*]}}\"\n"
        env = dict(os.environ, PATH=f"{self.fakebin}:/usr/bin:/bin")
        res = subprocess.run(["/bin/bash", "-c", snippet], env=env, text=True, capture_output=True, timeout=5)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        lines = res.stdout.strip().splitlines()
        self.assertEqual(lines, ["fail:未关闭(Ethernet)", "Ethernet"])

    def test_clash_party_unix_socket_modes_and_rules_verification(self):
        sock_path = self.sockdir / f"mihomo-party-{os.getuid()}-9999.sock"
        (self.home / "Library" / "Application Support" / "mihomo-party" / "mihomo.yaml").write_text(
            'secret: "party-secret-123"\n', encoding="utf-8"
        )
        pinned_rules = [
            {"type": "DomainSuffix", "payload": d, "proxy": "ClaudeGroup"}
            for d in PINNED_DOMAINS
        ]
        state = {"secret": "party-secret-123", "mode": "rule", "rules": pinned_rules}
        with UnixJsonServer(sock_path, state):
            # 1) Rule 模式且 13 个生态域名全部置顶 -> 内核规则直接验证通过
            r_rule = self.run_core("checkdetail")
            self.assertEqual(r_rule.returncode, 0, r_rule.stdout + r_rule.stderr)
            self.assertIn("代理内核=ok:Clash Party 运行中", r_rule.stdout)
            self.assertIn("规则置顶=ok:内核规则已验证(13 个生态域名已置顶)", r_rule.stdout)

            # 2) Global 模式且有效节点 -> 全局通过
            state["mode"] = "global"
            r_global = self.run_core("checkdetail")
            self.assertEqual(r_global.returncode, 0, r_global.stdout + r_global.stderr)
            self.assertIn("规则置顶=ok:全局模式(全部流量走代理)", r_global.stdout)
            self.assertIn("WebRTC=ok:仅暴露代理出口IP(全局模式)", r_global.stdout)

            # 3) Direct 模式 -> 必须硬性拦截，且不向已知直连路径发 STUN 探测
            state["mode"] = "direct"
            r_direct = self.run_core("checkdetail")
            self.assertEqual(r_direct.returncode, 0)
            self.assertIn("规则置顶=fail:Clash Party 当前处于直连(direct)模式", r_direct.stdout)
            self.assertIn("WebRTC=fail:Clash Party 当前处于直连(direct)模式，未发送 STUN 探测", r_direct.stdout)
            chk_direct = self.run_core("check")
            self.assertNotEqual(chk_direct.returncode, 0)
            self.assertIn("置顶规则:Clash Party 当前处于直连(direct)模式", chk_direct.stdout)

    def test_clash_party_controller_override_validation(self):
        r0 = self.run_core("get-clash-party-controller")
        self.assertEqual(r0.returncode, 0)
        self.assertEqual(r0.stdout.strip(), "controller=auto")

        bad = self.run_core("set-clash-party-controller", "8.8.8.8:9090")
        self.assertNotEqual(bad.returncode, 0, "不得允许把控制接口指到非本机公网地址")

        ok = self.run_core("set-clash-party-controller", "9097")
        self.assertEqual(ok.returncode, 0, ok.stdout + ok.stderr)
        self.assertEqual(self.run_core("get-clash-party-controller").stdout.strip(), "controller=127.0.0.1:9097")

        # 显式指定了不可达端口时必须报 fail 而非静默回退
        fail_override = self.run_core("checkdetail")
        self.assertEqual(fail_override.returncode, 0)
        self.assertIn("规则置顶=fail:指定的 Clash Party 控制接口不可达", fail_override.stdout)
        chk_override = self.run_core("check")
        self.assertNotEqual(chk_override.returncode, 0)
        self.assertIn("置顶规则:指定的 Clash Party 控制接口不可达", chk_override.stdout)

        reset = self.run_core("set-clash-party-controller", "auto")
        self.assertEqual(reset.returncode, 0)
        self.assertEqual(self.run_core("get-clash-party-controller").stdout.strip(), "controller=auto")

        # auto 无控制接口时回退 fake-ip 行为检测
        auto_fallback = self.run_core("checkdetail")
        self.assertIn("规则置顶=ok:行为检测通过(控制接口未验证", auto_fallback.stdout)


if __name__ == "__main__":
    unittest.main()
