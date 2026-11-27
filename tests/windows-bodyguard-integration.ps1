﻿$ErrorActionPreference = 'Stop'
# 隔离验证 Windows 保镖计划任务设置审计与存活判定(不触碰真实计划任务与系统服务)。
$core = Join-Path (Split-Path -Parent $PSScriptRoot) 'windows\claude-switch.ps1'
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($core, [ref]$null, [ref]$parseErrors)
if ($parseErrors.Count) { throw $parseErrors[0].Message }
foreach ($name in @('Test-BodyguardTaskHardened', 'Test-BodyguardProcessAlive', 'Test-BodyguardAlive', 'Get-BodyguardStatus')) {
    $fn = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name }, $true)
    if (-not $fn) { throw "缺少函数: $name" }
    . ([scriptblock]::Create($fn.Extent.Text))
}

$script:mockTask = $null
$script:mockProcs = @()
function Get-ScheduledTask {
    param([string]$TaskName, $ErrorAction)
    return $script:mockTask
}
function Get-CimInstance {
    param([string]$ClassName, [string]$Filter, $ErrorAction)
    return $script:mockProcs
}

function New-MockTask([string]$State, [string]$Limit, [bool]$DisallowBattery, [bool]$StopOnBattery) {
    return [pscustomobject]@{
        TaskName = 'ClaudeBodyguard'
        State    = $State
        Settings = [pscustomobject]@{
            ExecutionTimeLimit       = $Limit
            DisallowStartIfOnBatteries = $DisallowBattery
            StopIfGoingOnBatteries   = $StopOnBattery
        }
    }
}

function Assert-Status([string]$CaseName, [string]$ExpectedPattern) {
    $actual = Get-BodyguardStatus
    if ($actual -notmatch $ExpectedPattern) {
        throw "$CaseName 失败: 实际='$actual', 期望匹配='$ExpectedPattern'"
    }
    "PASS  $CaseName"
}

# 1. 未注册计划任务 -> fail:未安装
$script:mockTask = $null
$script:mockProcs = @()
Assert-Status '未安装计划任务判 fail' '^保镖=fail:未安装$'

# 2. 旧版默认设置(PT72H + 电池限制)且已被系统停止(State=Ready,无进程) -> fail:未运行(提示含72h/电池限制)
$script:mockTask = New-MockTask 'Ready' 'PT72H' $true $true
Assert-Status '72h超时或切电池停机后判 fail' '^保镖=fail:未运行\(计划任务含72h/电池限制,请点一键修复\)$'

# 3. 已加固计划任务但当前未运行 -> fail:未运行
$script:mockTask = New-MockTask 'Ready' 'PT0S' $false $false
Assert-Status '已加固但停止的计划任务判 fail' '^保镖=fail:未运行\(请点一键修复重新启动\)$'

# 4. 计划任务被禁用 -> fail:计划任务已禁用
$script:mockTask = New-MockTask 'Disabled' 'PT0S' $false $false
Assert-Status '禁用状态判 fail' '^保镖=fail:计划任务已禁用\(请点一键修复\)$'

# 5. 旧版任务仍在运行但带 72h 或电池限制 -> warn 提示一键修复加固
$script:mockTask = New-MockTask 'Running' 'PT72H' $false $false
Assert-Status '运行中但含 72h 限制判 warn' '^保镖=warn:运行中,但计划任务含72h或电池限制\(建议点一键修复加固\)$'

$script:mockTask = New-MockTask 'Running' 'PT0S' $false $true
Assert-Status '运行中但含电池停机限制判 warn' '^保镖=warn:运行中,但计划任务含72h或电池限制\(建议点一键修复加固\)$'

# 6. 已加固且处于 Running -> ok:运行中
$script:mockTask = New-MockTask 'Running' 'PT0S' $false $false
Assert-Status '已加固且 Running 判 ok' '^保镖=ok:运行中$'

# 7. State 非 Running 但进程命令行确认在跑 -> ok:运行中
$script:mockTask = New-MockTask 'Ready' '00:00:00' $false $false
$script:mockProcs = @([pscustomobject]@{ ProcessId = ($PID + 99999); CommandLine = 'powershell.exe -File "C:\Users\u\.claude-switcher\claude-bodyguard.ps1"' })
Assert-Status '进程命令行命中 claude-bodyguard.ps1 判 ok' '^保镖=ok:运行中$'
