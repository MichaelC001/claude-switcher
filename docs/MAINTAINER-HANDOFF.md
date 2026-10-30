# Claude 账号切换器 · 维护交接文档

> 更新时间：2026-10-31  
> 适用仓库：`YOURSJEYO/claude-switcher`  
> 本地路径：`/Users/mac/Documents/claude-switcher`  
> 主分支：`main`  
> 本文件记录当前交付状态，不替代根目录 `AGENTS.md` 的安装与安全规则。

## 1. 当前状态速览

- 当前 Release：**v1.7.1**  
  https://github.com/YOURSJEYO/claude-switcher/releases/tag/v1.7.1
- 交接前远端 `main` 最新提交：`40f1357 ci: 增加 windows-latest job 执行两个 PowerShell 隔离集成回归`
- 交接前本地 `main` 已与远端同步，工作树干净。
- 本文档提交是交接后的下一笔文档提交，**不改变程序行为，也不需要单独发版**。
- 当前没有必须继续开发的遗留功能任务；下一项工作由维护者新指令决定。
- 不要重复完成此前的 PR 审核、Windows 功能补全、FlClash 修复或目录冲突修复。

### 发布与未发布内容

**v1.7.1 已包含：**

- 此前全部 Windows 功能补全、UI 优化和目录切换修复。
- macOS FlClash 一键修复与回滚（`cb6a72b`）。

**v1.7.1 之后进入 `main`、但尚未发布的内容：**

- `14814ed`：修复 Windows 加密快照 KDF 构造方式和 zip 条目路径，恢复 PowerShell 集成回归。
- `40f1357`：增加 `windows-latest` CI，实际执行两个 PowerShell 隔离集成测试。

下一版本如获维护者明确许可发布，应包含上述提交并再次核验 Windows 快照产物。

## 2. 已完成的平台功能

### macOS

主要文件：

- 核心：`core/claude-switch.sh`
- UI：`app/main.swift`
- 安装器：`installer/`
- 守护模板：`daemons/`
- 测试：`tests/`

现有能力包括：

- 14 项环境审计、Fail-Closed 启动、Kill-Switch 和时区看门狗。
- A–D 四账号快照隔离、APFS COW 恢复、跨身份保留。
- 可配置 6 项非关键检查，硬性安全项不可关闭或降级。
- 脱敏客户端日志、诊断导出、菜单栏模型。
- 设备指纹、Claude Code CLI 体检、一次性隔离浏览器、独立代理诊断。
- macOS AES-256 DMG 快照导出/导入。
- Clash Verge / FlClash / Shadowrocket / sing-box / ClashX / Surge 等客户端适配及 `set-client`。
- 应用内更新、Release 安装包和 SHA256 校验。

### Windows（Beta）

主要文件：

- 核心：`windows/claude-switch.ps1`
- UI：`windows/SwitcherUI.ps1`
- 安装器：`windows/install.ps1`
- 保镖：`windows/claude-bodyguard.ps1`
- 文档：`windows/README.md`

本轮已补齐：

- A–D 四账号、快照大小和日期、48 小时出口历史、跨身份保留。
- 可调整大小的深色 WPF 界面、四账号卡片、长任务后台执行、每次切换前重新审计。
- 代理客户端切换，包含 FlClash；核心脚本与 `proxy-mode.txt` 同步，保镖每轮读取。
- 指纹/CLI 体检、隔离浏览器、独立代理诊断、检查设置和脱敏诊断导出。
- Windows `.csnap` 加密快照：PBKDF2-HMAC-SHA256、AES-256-CBC、HMAC-SHA256，流式处理，先认证再解压。
- Release 启动检查和一键更新机制，未照搬 macOS launchd/updater。

**格式边界：** Windows `.csnap` 与 macOS 加密 DMG 不兼容，不要跨系统直接导入。

### Windows 目录切换修复

`92cd62f` 修复了两类普遍问题：

- 正常切换在 `%APPDATA%` 产生 `Claude.new` / `Claude.old`，可能触发多个 Claude 数据目录冲突。
- 新目录提交后旧目录清理失败，可能让账号指针停留在旧账号。

当前行为：

- 同盘时事务暂存位于 `%USERPROFILE%\.claude-switcher\staging`。
- 数据和 `current.txt` 先一起提交，再清理旧目录。
- 清理失败写入 `staging\cleanup.json`，下次仅清理能证明归属的残留。
- 不明残留仍拒绝自动删除。
- `%APPDATA%` 与 `%USERPROFILE%` 不同卷时保留原路径，避免跨卷改名回归。

### Windows 快照后续修复（未发布）

`14814ed` 修复了静态测试未覆盖到的 PowerShell 5.1 实机问题：

- `Rfc2898DeriveBytes` 改用 `::new()`，避免 `New-Object -ArgumentList` 把哈希算法结构体转成字符串。
- 新增 `New-SnapshotArchive`，手工统一 zip 条目分隔符为 `/`，避免导出的包无法导回。
- 同时修复两个 PowerShell 集成测试自身的打桩和自动变量问题。

`40f1357` 已在 `windows-latest` CI 中实际执行：

- `tests/windows-switch-integration.ps1`
- `tests/windows-snapshot-integration.ps1`

这意味着这两个隔离集成测试已有 Windows CI 执行证据，但仍不等于完整 Windows 真机 UI/安装/更新验收。

## 3. macOS FlClash 专用修复

最新功能提交：`cb6a72b feat: 增加 FlClash 一键修复与回滚`。

针对以下现象：

- DNS 未走隧道。
- Claude 域名置顶未命中。
- STUN 暴露非代理出口。

实现流程：

1. 关闭 FlClash。
2. 备份当前 `database.sqlite`。
3. 在当前 Profile 中事务写入 Claude 生态域名和 UDP `3478 / 5349 / 19302` 规则。
4. 使用当前配置中的有效代理组；配置组无效时回退到第一个 `select` 组，最后才回退 `GLOBAL`。
5. 重启后验证 fake-IP 路由和 STUN 结果。
6. 验证失败回滚；回滚失败则明确提示手动恢复，不能误报成功。

安全边界：

- 只修改当前 Profile，不读取或输出订阅、节点、凭据内容。
- 要求 fake-IP 已启用。
- 支持 FlClash 数据库 schema 17–21；未来版本结构未知时会拒绝写入。
- 无法识别当前 Profile、数据库结构不支持或配置缺失时，不修改配置。
- 重复执行不会插入重复规则。
- 默认保留 WebRTC/UDP 能力，不强制切换为 `reject`。
- STUN 无响应仍显示未确认，不伪装为通过。

**重要：** 这是 macOS 修复，不是 Windows 修复。实现使用 `osascript`、`open -a` 和 `~/Library/Application Support/com.follow.clash`。

## 4. 验证证据

最近一次完整本地验证（FlClash 提交及合并结果）：

- **229 tests OK**。
- FlClash 隔离测试覆盖：规则写入、幂等、回滚、未知 Profile、未来 schema、fake-IP 前置、成功生效及 STUN 失败回滚。
- Shell 语法、Swift 严格编译、JavaScript 语法、PowerShell BOM/LF、源码 SHA256 均通过。

关键 CI：

- FlClash 主分支检查：  
  https://github.com/YOURSJEYO/claude-switcher/actions/runs/41002576684
- Windows 目录修复主分支检查：  
  https://github.com/YOURSJEYO/claude-switcher/actions/runs/40943942754
- 最新 Windows/macOS 综合检查（含 PowerShell 隔离集成）：  
  https://github.com/YOURSJEYO/claude-switcher/actions/runs/41025969876
- v1.7.1 发布流水线：  
  https://github.com/YOURSJEYO/claude-switcher/actions/runs/41004237727

v1.7.1 全部 Release 产物已下载并执行 SHA256 校验，Windows 包内版本确认为 `1.7.1`。

### 尚未完成的验证

不得把静态检查当作完整真机验收：

- Windows 新 WPF 的实际渲染和完整交互。
- Windows 安装器、更新器和真实代理客户端环境。
- 真实 FlClash 中的规则加载、UDP 转发和不同节点行为。
- 真实 Windows 浏览器隔离、安装和账号使用流程。

后续维护者应明确区分：**静态测试、隔离集成测试、Windows CI、真实用户环境验收**。

## 5. 已知维护注意事项

- 本轮累计变更较大，维护者已明确指出。后续修复应优先小 diff，避免为局部问题引入过度设计。
- FlClash schema 大于 21 时当前修复会安全拒绝。升级 FlClash 后必须重新核对数据库结构，不能强行写入。
- `v1.7.1` 不包含其后的 Windows 快照 KDF/zip 修复，下一版本必须带上。
- Windows 真机未验收的功能不能宣称“已真机通过”。
- 不强制为用户切换 WebRTC `reject` 策略；默认 `proxy` 需要节点支持 UDP。
- 不把 STUN 无响应当作零泄漏，也不把 fake-IP 网卡存在当作全部流量已代理。
- 当前没有证据表明维护者本机的 FlClash 配置、Windows 安装态或账号存档被本轮开发直接修改；开发主要在仓库和隔离环境完成。

## 6. 后续工作规则

开始任何新改动前：

```bash
cd /Users/mac/Documents/claude-switcher
git status --short
git log -3 --oneline
export PATH="$HOME/.local/bin:$PATH"
gh api repos/YOURSJEYO/claude-switcher/commits/main --jq '.sha'
```

然后阅读根目录 `AGENTS.md`。远端可能已有其他维护者提交，先 `git fetch origin main`，不要基于旧状态覆盖他人工作。

处理用户反馈时：

1. 先区分用户个例与默认安装/升级/数据安全等普遍问题。
2. 先查根因、找证据、隔离复现，再决定是否改产品。
3. 修复前说明根因、影响范围、为什么这样修、如何验证。
4. 普遍问题需保持向后兼容并添加回归测试。
5. 小步修改，不为通过检查放宽出口一致性、Kill-Switch、root 权限、账号归档或供应链校验。
6. 未验证的平台必须明确标注。

高风险操作仍需维护者在当前对话中明确授权，否则不得：

- 发布 Release 或打 tag。
- 执行安装器、卸载器或本机 `update`。
- 覆盖 `~/.local/bin/claude-switch.sh`。
- 重新编译或替换 `~/Desktop/Claude切换器.app`。
- 修改 `/Library/Application Support/claude-switcher/`。
- 修改 `/Library/LaunchDaemons/local.claude-*` 或 `~/Library/LaunchAgents/local.claude-*`。
- 改动 `~/.claude-switcher/accounts/` 的存档结构。
- 修改真实 FlClash/Clash 配置、账号、代理或系统设置。

## 7. 常用验证命令

完整测试：

```bash
cd /Users/mac/Documents/claude-switcher
python3 -B -m unittest discover -s tests -v
```

仅 FlClash 回归：

```bash
python3 -B -m unittest tests.test_flclash_repair -v
```

Shell 与静态检查：

```bash
bash -n core/claude-switch.sh
swiftc -O -parse-as-library -warnings-as-errors \
  -target "$(uname -m)-apple-macos13.0" \
  app/main.swift -o /tmp/ClaudeSwitcher \
  -framework SwiftUI -framework AppKit
node --check docs/app.js
git diff --check
```

修改 `core/`、`daemons/` 或 `installer/` 后，提交前必须：

```bash
bash scripts/gen-sums.sh
shasum -a 256 -c SHA256SUMS
```

所有 `.ps1` 必须保持 **UTF-8 with BOM** 和 LF。不要遗漏更新后的 `SHA256SUMS`。

推送后：

```bash
export PATH="$HOME/.local/bin:$PATH"
gh run list --workflow checks.yml --branch main --limit 5
gh run watch <run-id> --exit-status
```

只有维护者明确许可发布时才执行版本发布。发布后要核对 Release 资产、全部 SHA256 和包内版本，不只看流水线绿色。

## 8. 建议的下一批工作（非承诺任务）

按维护者新指令选择，不要自动展开：

1. 在真实 FlClash 中验收一键修复、规则加载和 STUN 行为。
2. 在真实 Windows 中验收 WPF、安装、更新和 `.csnap` 往返。
3. 准备下一版本时，纳入 `14814ed` 和 `40f1357`，但发布前必须再次取得许可。
4. 后续局部修复保持小 diff，优先复用客户端官方配置接口，避免重复实现复杂事务逻辑。

---

**接手原则：先读当前状态和 `AGENTS.md`，再决定新任务。不要重复本轮已完成的开发、审核和发布。**
