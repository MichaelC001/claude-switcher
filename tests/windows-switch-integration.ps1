# Windows 切换流程的隔离集成测试
#
# 只用临时目录 + 打桩的进程/启动命令，不接触真实 Claude、账号快照、注册表、计划任务或网络。
# 在 Windows PowerShell 5.1 或 pwsh 7 下运行：
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tests\windows-switch-integration.ps1
#
# 覆盖：首次收编 / 新建空槽位 / 往返切换的数据归属 / 暂存目录残留时拒绝覆盖。

$ErrorActionPreference = 'Stop'

$core = Join-Path (Split-Path -Parent $PSScriptRoot) 'windows\claude-switch.ps1'
if (-not (Test-Path -LiteralPath $core)) { throw "找不到核心脚本: $core" }

$root = Join-Path ([System.IO.Path]::GetTempPath()) ('cs-it-' + [guid]::NewGuid().ToString('N'))
$env:USERPROFILE = Join-Path $root 'user'
$env:APPDATA = Join-Path $root 'appdata'
$env:LOCALAPPDATA = Join-Path $root 'localappdata'
foreach ($d in @($env:USERPROFILE, $env:APPDATA, $env:LOCALAPPDATA)) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

# 打桩：不碰真实进程，也不启动任何程序（CmdletBinding 让 -ErrorAction 等公共参数可用）
function global:Get-Process {
    [CmdletBinding()]
    param([string[]]$Name)
    return @()
}
function global:Start-Process {
    [CmdletBinding()]
    param($FilePath, $ArgumentList, [switch]$Wait, [switch]$NoNewWindow)
    return $null
}

$failures = 0
function Assert([string]$what, [bool]$condition, [string]$detail = '') {
    if ($condition) {
        "PASS  $what"
    } else {
        "FAIL  $what $detail"
        $script:failures++
    }
}
function Read-Text([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return '' }
    return (Get-Content -LiteralPath $path -Raw -Encoding UTF8).Trim()
}

$scriptErrorPreference = $ErrorActionPreference
try {
    . $core *> $null
    $ErrorActionPreference = 'Stop'

    $data = $DATA
    $base = $BASE
    $accounts = Join-Path $base 'accounts'
    New-Item -ItemType Directory -Path $data -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $data 'config.json') -Value 'A1' -Encoding UTF8 -NoNewline

    # 1. 首次收编：当前登录变成账号 A，且当前数据目录不被删除
    $null = Invoke-Switch 'A'
    Assert '首次收编写入 current=A' ((Read-Text "$base\current.txt") -eq 'A') "实际=$(Read-Text "$base\current.txt")"
    Assert '首次收编生成 A 快照' ((Read-Text "$accounts\A\config.json") -eq 'A1')
    Assert '首次收编保留当前数据' ((Read-Text "$data\config.json") -eq 'A1')

    # 2. 切到空槽位 B：A 重新归档为 A2，B 以全新状态初始化
    Set-Content -LiteralPath (Join-Path $data 'config.json') -Value 'A2' -Encoding UTF8 -NoNewline
    $null = Invoke-Switch 'B'
    Assert '切换后 current=B' ((Read-Text "$base\current.txt") -eq 'B')
    Assert 'A 快照更新为最新内容' ((Read-Text "$accounts\A\config.json") -eq 'A2')
    Assert '空槽位 B 初始化后无 A 的配置' (-not (Test-Path -LiteralPath "$data\config.json"))

    # 3. 在 B 里产生数据，再切回 A：两侧内容各归各
    Set-Content -LiteralPath (Join-Path $data 'config.json') -Value 'B1' -Encoding UTF8 -NoNewline
    $null = Invoke-Switch 'A'
    Assert '切回后 current=A' ((Read-Text "$base\current.txt") -eq 'A')
    Assert 'A 的数据被还原' ((Read-Text "$data\config.json") -eq 'A2')
    Assert 'B 的数据被归档' ((Read-Text "$accounts\B\config.json") -eq 'B1')

    # 4. 暂存残留：拒绝覆盖，当前数据与指针都不变
    New-Item -ItemType Directory -Path "$accounts\A.new" -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $accounts 'A.new\stale.txt') -Value 'stale' -Encoding UTF8
    $r = Invoke-Switch 'B'
    Assert '存在待恢复快照时返回 FAIL' (((@($r) -join "`n") -match '(?m)^FAIL:')) "输出=$r"
    Assert '拒绝覆盖时 current 不变' ((Read-Text "$base\current.txt") -eq 'A')
    Assert '拒绝覆盖时当前数据不变' ((Read-Text "$data\config.json") -eq 'A2')
    Remove-Item -LiteralPath "$accounts\A.new" -Recurse -Force

    # 5. 非法槽位
    $r = Invoke-Switch 'E'
    Assert '非法槽位返回 FAIL' (((@($r) -join "`n") -match '(?m)^FAIL:')) "输出=$r"

    # 6. 不留下暂存/回滚残留
    foreach ($leftover in @("$accounts\A.new", "$accounts\A.previous", "$accounts\B.new", "$accounts\B.previous", "$data.new", "$data.old")) {
        Assert "无残留 $leftover" (-not (Test-Path -LiteralPath $leftover))
    }
} finally {
    $ErrorActionPreference = $scriptErrorPreference
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures -gt 0) {
    "FAILED: $failures 项"
    exit 1
}
'OK: 全部通过'
