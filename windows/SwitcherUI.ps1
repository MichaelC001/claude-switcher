# Claude 账号切换器 - Windows 界面 (WPF, Beta)
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$BASE = "$env:USERPROFILE\.claude-switcher"
$CORE = "$BASE\claude-switch.ps1"

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Claude 账号切换器" Width="470" Height="820" ResizeMode="NoResize"
        WindowStartupLocation="CenterScreen" Background="#FF12141D" Foreground="White">
    <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Foreground="White">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/><RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,14">
            <Border Width="44" Height="44" CornerRadius="12">
                <Border.Background>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                        <GradientStop Color="#FF6366F1" Offset="0"/><GradientStop Color="#FF9333EA" Offset="1"/>
                    </LinearGradientBrush>
                </Border.Background>
                <TextBlock Text="盾" HorizontalAlignment="Center" VerticalAlignment="Center" FontSize="20" Foreground="White"/>
            </Border>
            <StackPanel Margin="12,0,0,0" VerticalAlignment="Center">
                <TextBlock Text="Claude 账号切换器" FontSize="18" FontWeight="Bold"/>
                <TextBlock Text="安全检查 · 切换 · 启动" FontSize="11" Foreground="#8AFFFFFF"/>
            </StackPanel>
            <Border x:Name="StatusPill" Margin="60,0,0,0" Padding="12,5" CornerRadius="12" Background="#2E22C55E" VerticalAlignment="Center">
                <TextBlock x:Name="StatusText" Text="检查中" FontSize="11" FontWeight="Bold" Foreground="#FFFB923C"/>
            </Border>
        </StackPanel>

        <Border Grid.Row="1" CornerRadius="12" Background="#0DFFFFFF" BorderBrush="#14FFFFFF" BorderThickness="1" Padding="4">
            <ListBox x:Name="CheckList" Background="Transparent" BorderThickness="0" Foreground="#E6FFFFFF" FontSize="13">
                <ListBox.ItemTemplate>
                    <DataTemplate>
                        <Grid Margin="6,6" Width="380">
                            <TextBlock Text="{Binding Name}" VerticalAlignment="Center"/>
                            <TextBlock Text="{Binding Detail}" HorizontalAlignment="Right" Margin="0,0,26,0" Foreground="#73FFFFFF" FontSize="11"/>
                            <TextBlock Text="{Binding Icon}" HorizontalAlignment="Right" Foreground="{Binding Color}" FontSize="14" FontWeight="Bold"/>
                        </Grid>
                    </DataTemplate>
                </ListBox.ItemTemplate>
            </ListBox>
        </Border>

        <StackPanel Grid.Row="2" Margin="0,14,0,0">
            <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                <TextBlock Text="当前账号" FontSize="11" Foreground="#80FFFFFF" VerticalAlignment="Center"/>
                <Border Margin="6,0,0,0" Padding="10,3" CornerRadius="10" Background="#4D6366F1">
                    <TextBlock x:Name="CurrentAccount" Text="?" FontSize="11" FontWeight="Bold" Foreground="#FFA5B4FC"/>
                </Border>
            </StackPanel>
            <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition Width="10"/><ColumnDefinition/></Grid.ColumnDefinitions>
                <Button x:Name="BtnA" Grid.Column="0" Content="账号 A" Height="52" FontSize="15" FontWeight="Bold"
                        Foreground="White" Background="#7A6366F1" BorderThickness="0" Cursor="Hand"/>
                <Button x:Name="BtnB" Grid.Column="2" Content="账号 B" Height="52" FontSize="15" FontWeight="Bold"
                        Foreground="White" Background="#14FFFFFF" BorderBrush="#26FFFFFF" Cursor="Hand"/>
            </Grid>
            <TextBlock x:Name="ActionHint" Text="" FontSize="11" Foreground="#80FFFFFF" Margin="0,8,0,0" TextWrapping="Wrap"/>
        </StackPanel>

        <StackPanel Grid.Row="3">
            <Border x:Name="UpdateBar" Visibility="Collapsed" CornerRadius="10" Background="#1F6366F1" BorderBrush="#556366F1" BorderThickness="1" Padding="12,10" Margin="0,12,0,0">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock x:Name="UpdateText" Grid.Column="0" Text="" FontSize="11" Foreground="#FFE0E7FF" TextWrapping="Wrap" VerticalAlignment="Center" Margin="0,0,8,0"/>
                    <Button x:Name="BtnUpdate" Grid.Column="1" Content="一键更新" Padding="10,5" Margin="0,0,6,0" FontSize="11" FontWeight="Bold" Foreground="White" Background="#FF6366F1" BorderThickness="0" Cursor="Hand"/>
                    <Button x:Name="BtnLater" Grid.Column="2" Content="稍后" Padding="10,5" FontSize="11" Foreground="#B3FFFFFF" Background="#14FFFFFF" BorderThickness="0" Cursor="Hand"/>
                </Grid>
            </Border>
            <TextBlock x:Name="Banner" Text="" FontSize="12" Foreground="#FFF87171" Margin="0,12,0,6" TextWrapping="Wrap"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <Button x:Name="BtnFix" Content="一键修复" Padding="18,8" Margin="0,0,10,0" FontWeight="Bold" Foreground="White" BorderThickness="0" Cursor="Hand">
                    <Button.Background>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                            <GradientStop Color="#FF6366F1" Offset="0"/><GradientStop Color="#FF9333EA" Offset="1"/>
                        </LinearGradientBrush>
                    </Button.Background>
                </Button>
                <Button x:Name="BtnRefresh" Content="重新检查" Padding="18,8" FontWeight="Bold" Foreground="White" Background="#1AFFFFFF" BorderThickness="0" Cursor="Hand"/>
                <Button x:Name="BtnCheckUpdate" Content="检查更新" Padding="18,8" Margin="10,0,0,0" FontWeight="Bold" Foreground="White" Background="#1AFFFFFF" BorderThickness="0" Cursor="Hand"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,10,0,0">
                <Button x:Name="BtnSettings" Content="检查设置" Padding="16,6" Margin="0,0,10,0" FontSize="11" Foreground="#CCFFFFFF" Background="#14FFFFFF" BorderThickness="0" Cursor="Hand"/>
                <Button x:Name="BtnDiagnostics" Content="导出诊断日志" Padding="16,6" FontSize="11" Foreground="#CCFFFFFF" Background="#14FFFFFF" BorderThickness="0" Cursor="Hand"/>
            </StackPanel>
            <TextBlock Text="硬性安全项必须通过；非关键项可显式跳过或忽略" FontSize="10" Foreground="#59FFFFFF" HorizontalAlignment="Center" Margin="0,14,0,0"/>
        </StackPanel>
    </Grid>
    </ScrollViewer>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$win = [Windows.Markup.XamlReader]::Load($reader)

$rows = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$win.FindName('CheckList').ItemsSource = $rows

$checkNames = @('代理内核','TUN网卡','出口IP','IP一致','时区','地区','IPv6','DNS','WebRTC','保镖','规则置顶','客户端语言','ASN属性','生态可达性')

function Set-Status($text, $color) {
    $win.FindName('StatusText').Text = $text
    $win.FindName('StatusText').Foreground = (New-Object System.Windows.Media.SolidColorBrush $color)
}

function Invoke-Core([string[]]$coreArgs) {
    # checkdetail/fix 改从落盘的 UTF-8 文件读取:子进程 stdout 经控制台代码页(如 GBK/936)转码会把中文弄乱
    $script:lastCoreExit = 1
    if ($coreArgs[0] -eq 'checkdetail') {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $CORE @coreArgs 2>$null | Out-Null
        $script:lastCoreExit = $LASTEXITCODE
        return ((Get-Content "$BASE\last-check.txt" -Encoding UTF8) -join "`n").Trim()
    }
    if ($coreArgs[0] -eq 'fix') {
        Remove-Item -LiteralPath "$BASE\last-fix.txt" -Force -ErrorAction SilentlyContinue
        & powershell -NoProfile -ExecutionPolicy Bypass -File $CORE @coreArgs 2>$null | Out-Null
        $script:lastCoreExit = $LASTEXITCODE
        if (Test-Path -LiteralPath "$BASE\last-fix.txt") {
            return ((Get-Content "$BASE\last-fix.txt" -Encoding UTF8) -join "`n").Trim()
        }
        return ''
    }
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $CORE @coreArgs 2>$null
    $script:lastCoreExit = $LASTEXITCODE
    return ($out | Out-String).Trim()
}

function Refresh-Checks {
    $rows.Clear()
    foreach ($n in $checkNames) { $rows.Add([pscustomobject]@{ Name = $n; Detail = ''; Icon = '…'; Color = '#FF6B7280' }) }
    Set-Status '检查中' ([System.Windows.Media.Color]::FromRgb(0xFB,0x92,0x3C))
    $win.FindName('Banner').Text = ''

    $out = Invoke-Core @('checkdetail')
    $allOk = $true; $matched = 0
    foreach ($line in ($out -split "`n")) {
        $kv = $line -split '=', 2
        if ($kv.Count -ne 2) { continue }
        $st = $kv[1] -split ':', 2
        for ($i = 0; $i -lt $rows.Count; $i++) {
            if ($rows[$i].Name -eq $kv[0] -or ($kv[0] -eq 'TUN网卡' -and $rows[$i].Name -eq 'TUN网卡')) {
                $matched++
                $d = if ($st.Count -gt 1) { $st[1] } else { '' }
                switch ($st[0]) {
                    'ok'   { $rows[$i] = [pscustomobject]@{ Name = $rows[$i].Name; Detail = $d; Icon = '✓'; Color = '#FF22C55E' } }
                    'warn' { $rows[$i] = [pscustomobject]@{ Name = $rows[$i].Name; Detail = $d; Icon = '⚠'; Color = '#FFFACC15' } }
                    'skip' { $rows[$i] = [pscustomobject]@{ Name = $rows[$i].Name; Detail = $d; Icon = '−'; Color = '#FF6B7280' } }
                    default { $rows[$i] = [pscustomobject]@{ Name = $rows[$i].Name; Detail = $d; Icon = '✗'; Color = '#FFF87171' }; $allOk = $false }
                }
                break
            }
        }
    }
    $st = Invoke-Core @('status')
    $win.FindName('CurrentAccount').Text = if ($st -match 'current=B') { 'B' } elseif ($st -match 'current=A') { 'A' } else { '未初始化' }
    if ($matched -lt $checkNames.Count) {
        Set-Status '检查未过' ([System.Windows.Media.Color]::FromRgb(0xF8,0x71,0x71))
        $win.FindName('Banner').Text = "检测输出不完整($matched/$($checkNames.Count))，请点重新检查"
    } elseif ($allOk) {
        Set-Status '环境安全' ([System.Windows.Media.Color]::FromRgb(0x22,0xC5,0x5E))
    } else {
        Set-Status '检查未过' ([System.Windows.Media.Color]::FromRgb(0xF8,0x71,0x71))
        $win.FindName('Banner').Text = '存在未通过项，可一键修复或手动处理后重试'
    }
}

function Switch-To($t) {
    Set-Status '切换中' ([System.Windows.Media.Color]::FromRgb(0x60,0xA5,0xFA))
    $win.FindName('Banner').Text = "正在切换到账号 $t…（归档约需几十秒）"
    $win.Dispatcher.Invoke([action]{}, 'Render')
    $r = Invoke-Core @('switch', $t)
    if ($script:lastCoreExit -ne 0 -or $r -match '(?m)^FAIL:' -or $r -notmatch '(?m)^(OK|INFO):') {
        Set-Status '检查未过' ([System.Windows.Media.Color]::FromRgb(0xF8,0x71,0x71))
        $win.FindName('Banner').Text = if ($r) { $r } else { '切换未返回成功结果，请重新检查' }
    } else {
        $win.FindName('CurrentAccount').Text = $t
        Set-Status '完成' ([System.Windows.Media.Color]::FromRgb(0x22,0xC5,0x5E))
        $win.FindName('Banner').Foreground = (New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(0x22,0xC5,0x5E)))
        $win.FindName('Banner').Text = "已切换到账号 $t，Claude 启动中。"
    }
}

function Show-CheckSettings {
    $configJson = Invoke-Core @('get-check-config')
    if ($script:lastCoreExit -ne 0 -or [string]::IsNullOrWhiteSpace($configJson)) {
        [void][System.Windows.MessageBox]::Show('无法读取检查设置，请确认核心脚本已更新。', '检查设置')
        return
    }
    try { $config = $configJson | ConvertFrom-Json -ErrorAction Stop } catch {
        [void][System.Windows.MessageBox]::Show('检查设置格式无效，请恢复默认设置。', '检查设置')
        return
    }
    $settingsXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="检查设置" Width="520" Height="650" ResizeMode="NoResize"
        WindowStartupLocation="CenterOwner" Background="#FF12141D" Foreground="White">
    <Grid Margin="22">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,14">
            <TextBlock Text="检查设置" FontSize="20" FontWeight="Bold"/>
            <TextBlock Text="硬性安全项始终执行；跳过不等于通过" FontSize="11" Foreground="#99FFFFFF" Margin="0,4,0,0"/>
        </StackPanel>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel>
                <Border CornerRadius="10" Background="#0DFFFFFF" Padding="14" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock Text="可自定义的非关键检查" FontWeight="Bold" Margin="0,0,0,10"/>
                        <CheckBox x:Name="Check_IP" Content="IP 与上次一致" Margin="0,5"/>
                        <CheckBox x:Name="Check_DNS" Content="DNS 走隧道" Margin="0,5"/>
                        <CheckBox x:Name="Check_WebRTC" Content="WebRTC" Margin="0,5"/>
                        <CheckBox x:Name="Check_Locale" Content="客户端语言" Margin="0,5"/>
                        <CheckBox x:Name="Check_ASN" Content="ASN 属性" Margin="0,5"/>
                        <CheckBox x:Name="Check_Eco" Content="生态可达性" Margin="0,5"/>
                        <TextBlock Text="关闭后会真正跳过探测，并以灰色显示。出口国家、代理/TUN、Kill-Switch、保镖、账号归档和更新校验不可关闭。" FontSize="11" Foreground="#99FFFFFF" TextWrapping="Wrap" Margin="0,8,0,0"/>
                    </StackPanel>
                </Border>
                <Border CornerRadius="10" Background="#0DFFFFFF" Padding="14" Margin="0,0,0,12">
                    <StackPanel>
                        <CheckBox x:Name="CheckAllow" Content="将上述非关键项的失败降为警告" Margin="0,5"/>
                        <TextBlock Text="只影响以上 6 项，不放宽硬性安全项，也不会自动关闭检测。" FontSize="11" Foreground="#99FFFFFF" TextWrapping="Wrap" Margin="0,0,0,8"/>
                        <CheckBox x:Name="CheckLogging" Content="记录脱敏客户端日志" Margin="0,5"/>
                        <TextBlock Text="仅记录版本、命令、退出码、耗时和检查状态，不记录 IP、凭据或账号内容。" FontSize="11" Foreground="#99FFFFFF" TextWrapping="Wrap"/>
                    </StackPanel>
                </Border>
                <Border CornerRadius="10" Background="#0DFFFFFF" Padding="14">
                    <StackPanel>
                        <Button x:Name="BtnExportInSettings" Content="导出脱敏诊断日志…" Padding="12,7" HorizontalAlignment="Left" Foreground="White" Background="#1AFFFFFF" BorderThickness="0" Cursor="Hand"/>
                        <TextBlock Text="%USERPROFILE%\.claude-switcher\logs\client.log" FontSize="10" Foreground="#80FFFFFF" Margin="0,8,0,0"/>
                    </StackPanel>
                </Border>
            </StackPanel>
        </ScrollViewer>
        <StackPanel Grid.Row="2" Margin="0,14,0,0">
            <TextBlock x:Name="SettingsMessage" Text="" FontSize="11" Foreground="#FFFACC15" TextWrapping="Wrap" Margin="0,0,0,8"/>
            <StackPanel Orientation="Horizontal">
                <Button x:Name="BtnDefaults" Content="恢复默认" Padding="12,7" Foreground="White" Background="#1AFFFFFF" BorderThickness="0" Cursor="Hand"/>
                <Button x:Name="BtnSaveSettings" Content="保存并重新检查" Padding="12,7" Margin="12,0,0,0" FontWeight="Bold" Foreground="White" Background="#FF6366F1" BorderThickness="0" Cursor="Hand"/>
            </StackPanel>
        </StackPanel>
    </Grid>
</Window>
"@
    try {
        $settingsReader = New-Object System.Xml.XmlNodeReader ([xml]$settingsXaml)
        $settingsWin = [Windows.Markup.XamlReader]::Load($settingsReader)
        $settingsWin.Owner = $win
    } catch {
        [void][System.Windows.MessageBox]::Show('无法打开检查设置窗口。', '检查设置')
        return
    }
    $map = @(
        @{ Name = 'IP一致'; Control = 'Check_IP' },
        @{ Name = 'DNS'; Control = 'Check_DNS' },
        @{ Name = 'WebRTC'; Control = 'Check_WebRTC' },
        @{ Name = '客户端语言'; Control = 'Check_Locale' },
        @{ Name = 'ASN属性'; Control = 'Check_ASN' },
        @{ Name = '生态可达性'; Control = 'Check_Eco' }
    )
    $disabled = @($config.disabled)
    foreach ($item in $map) {
        $settingsWin.FindName($item.Control).IsChecked = ($disabled -notcontains $item.Name)
    }
    $settingsWin.FindName('CheckAllow').IsChecked = [bool]$config.allowOptionalFailures
    $settingsWin.FindName('CheckLogging').IsChecked = [bool]$config.logging
    $settingsWin.FindName('BtnDefaults').Add_Click({
        foreach ($item in $map) { $settingsWin.FindName($item.Control).IsChecked = $true }
        $settingsWin.FindName('CheckAllow').IsChecked = $false
        $settingsWin.FindName('CheckLogging').IsChecked = $true
        $settingsWin.FindName('SettingsMessage').Text = '已恢复默认选项，点击保存后生效'
    })
    $settingsWin.FindName('BtnSaveSettings').Add_Click({
        $newDisabled = @()
        foreach ($item in $map) {
            if ($settingsWin.FindName($item.Control).IsChecked -ne $true) { $newDisabled += $item.Name }
        }
        $newConfig = [pscustomobject]@{
            disabled = @($newDisabled)
            allowOptionalFailures = [bool]$settingsWin.FindName('CheckAllow').IsChecked
            logging = [bool]$settingsWin.FindName('CheckLogging').IsChecked
        }
        $json = $newConfig | ConvertTo-Json -Depth 3 -Compress
        $saveButton = $settingsWin.FindName('BtnSaveSettings')
        $saveButton.IsEnabled = $false
        $saveResult = Invoke-Core @('set-check-config', $json)
        $saveExit = $script:lastCoreExit
        $saveButton.IsEnabled = $true
        if ($saveExit -ne 0 -or $saveResult -notmatch '(?m)^OK:') {
            $settingsWin.FindName('SettingsMessage').Text = '保存失败，请检查配置后重试'
            return
        }
        $settingsWin.FindName('SettingsMessage').Text = '设置已保存，正在重新检查'
        Refresh-Checks
    })
    $settingsWin.FindName('BtnExportInSettings').Add_Click({ Export-DiagnosticLog })
    [void]$settingsWin.ShowDialog()
}

function Export-DiagnosticLog {
    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.Title = '导出脱敏诊断日志'
    $dialog.FileName = 'claude-switcher-diagnostics.zip'
    $dialog.DefaultExt = '.zip'
    $dialog.Filter = 'ZIP 压缩包|*.zip'
    $dialog.AddExtension = $true
    if ($dialog.ShowDialog() -ne $true) { return }
    $result = Invoke-Core @('export-diagnostics', $dialog.FileName)
    if ($script:lastCoreExit -eq 0 -and $result -match '(?m)^OK:') {
        [void][System.Windows.MessageBox]::Show($result, '诊断日志已导出')
    } else {
        [void][System.Windows.MessageBox]::Show('诊断日志导出失败，请重试。', '导出失败')
    }
}

$script:checkJob = $null
$script:checkTimer = $null
$script:checkManual = $false
$script:updateJob = $null
$script:updateTimer = $null
$script:updateRunning = $false
$script:latestVersion = ''

function Get-UiVersion {
    $vf = Join-Path $BASE 'version.txt'
    if (Test-Path -LiteralPath $vf) {
        try {
            $raw = Get-Content -LiteralPath $vf -Raw -Encoding UTF8 -ErrorAction Stop
            if ($null -ne $raw) {
                $v = ([string]$raw).Trim()
                if ($v) { return $v }
            }
        } catch {}
    }
    return 'unknown'
}

function ConvertFrom-UpdateOutput([string]$text) {
    $map = @{}
    foreach ($line in ($text -split "`r?`n")) {
        $kv = $line -split '=', 2
        if ($kv.Count -eq 2) { $map[$kv[0].Trim()] = $kv[1].Trim() }
    }
    return $map
}

function Write-UpdateCache([string]$status, [string]$latest) {
    try {
        $obj = [pscustomobject]@{
            checkedAt = (Get-Date).ToString('o')
            latest = $latest
            status = $status
        }
        $p = Join-Path $BASE 'update-check.json'
        [System.IO.File]::WriteAllText($p, ($obj | ConvertTo-Json -Compress), (New-Object System.Text.UTF8Encoding($false)))
    } catch {}
}

function Read-UpdateCache {
    $p = Join-Path $BASE 'update-check.json'
    if (-not (Test-Path -LiteralPath $p)) { return $null }
    try { return (Get-Content -LiteralPath $p -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json) } catch { return $null }
}

function Test-UpdateCacheFresh($cache) {
    if (-not $cache -or -not $cache.checkedAt) { return $false }
    try {
        $checked = [DateTime]::Parse([string]$cache.checkedAt, [Globalization.CultureInfo]::InvariantCulture)
        $hours = ((Get-Date) - $checked).TotalHours
        return ($hours -ge 0 -and $hours -lt 24)
    } catch { return $false }
}

function Set-UpdateText([string]$text, [string]$hex) {
    $win.FindName('UpdateText').Text = $text
    $win.FindName('UpdateText').Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($hex)
}

function Show-UpdateAvailable([string]$latest) {
    $script:latestVersion = $latest
    $current = Get-UiVersion
    Set-UpdateText "发现新版本 v$latest（当前 v$current）" '#FFE0E7FF'
    $win.FindName('BtnUpdate').Visibility = 'Visible'
    $win.FindName('BtnUpdate').IsEnabled = $true
    $win.FindName('BtnLater').Content = '稍后'
    $win.FindName('BtnLater').Visibility = 'Visible'
    $win.FindName('UpdateBar').Visibility = 'Visible'
}

function Show-UpdateNote([string]$text, [bool]$isError) {
    $script:latestVersion = ''
    if ($isError) { Set-UpdateText $text '#FFF87171' } else { Set-UpdateText $text '#FFE0E7FF' }
    $win.FindName('BtnUpdate').Visibility = 'Collapsed'
    $win.FindName('BtnLater').Content = '关闭'
    $win.FindName('BtnLater').Visibility = 'Visible'
    $win.FindName('UpdateBar').Visibility = 'Visible'
}

function Show-UpdateChecking {
    Set-UpdateText '正在检查更新…' '#FFE0E7FF'
    $win.FindName('BtnUpdate').Visibility = 'Collapsed'
    $win.FindName('BtnLater').Content = '关闭'
    $win.FindName('BtnLater').Visibility = 'Visible'
    $win.FindName('UpdateBar').Visibility = 'Visible'
}

function Start-UpdateCheck([bool]$manual) {
    if ($script:updateRunning) { return }
    if ($script:checkJob) {
        $s = $script:checkJob.State
        if ($s -eq 'Running' -or $s -eq 'NotStarted') {
            if ($manual) { $script:checkManual = $true; Show-UpdateChecking }
            return
        }
        Remove-Job $script:checkJob -Force -ErrorAction SilentlyContinue
        $script:checkJob = $null
    }

    if (-not $manual) {
        $cache = Read-UpdateCache
        if (Test-UpdateCacheFresh $cache) {
            if ($cache.status -eq 'update_available' -and $cache.latest) {
                Show-UpdateAvailable ([string]$cache.latest)
                return
            }
            if ($cache.status -eq 'dismissed') { return }
        }
    }

    if ($script:checkTimer) {
        $script:checkTimer.Stop()
        $script:checkTimer = $null
    }
    $script:checkManual = $manual
    if ($manual) { Show-UpdateChecking }

    try {
        $script:checkJob = Start-Job -ScriptBlock {
            param($core)
            & powershell -NoProfile -ExecutionPolicy Bypass -File $core check-update 2>$null
        } -ArgumentList $CORE
    } catch {
        $script:checkJob = $null
        if ($manual) { Show-UpdateNote ("检查更新失败：" + $_.Exception.Message) $true }
        return
    }

    $script:checkTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:checkTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $script:checkTimer.Add_Tick({
        if (-not $script:checkJob) { $script:checkTimer.Stop(); return }
        $st = $script:checkJob.State
        if ($st -ne 'Completed' -and $st -ne 'Failed' -and $st -ne 'Stopped') { return }
        $script:checkTimer.Stop()
        $out = (Receive-Job $script:checkJob -ErrorAction SilentlyContinue | Out-String)
        Remove-Job $script:checkJob -Force -ErrorAction SilentlyContinue
        $script:checkJob = $null
        $kv = ConvertFrom-UpdateOutput $out
        $manualNow = [bool]$script:checkManual
        if ($kv['STATUS'] -eq 'update_available' -and $kv['LATEST']) {
            Show-UpdateAvailable ([string]$kv['LATEST'])
            Write-UpdateCache 'update_available' ([string]$kv['LATEST'])
        } elseif ($manualNow) {
            if ($kv['STATUS'] -eq 'latest') {
                Show-UpdateNote ("已是最新版本 v" + $kv['LATEST']) $false
                Write-UpdateCache 'latest' ([string]$kv['LATEST'])
            } else {
                $msg = if ($kv['MESSAGE']) { $kv['MESSAGE'] } else { '无法获取更新信息' }
                Show-UpdateNote ("检查更新失败：" + $msg) $true
            }
        } elseif ($kv['STATUS'] -eq 'latest') {
            Write-UpdateCache 'latest' ([string]$kv['LATEST'])
        }
    })
    $script:checkTimer.Start()
}

$win.FindName('BtnRefresh').Add_Click({ Refresh-Checks })
$win.FindName('BtnFix').Add_Click({
    Set-Status '修复中' ([System.Windows.Media.Color]::FromRgb(0xFB,0x92,0x3C))
    $win.FindName('Banner').Text = '正在修复…（会弹出管理员授权框）'
    $win.Dispatcher.Invoke([action]{}, 'Render')
    $fixOut = Invoke-Core @('fix')
    Refresh-Checks
    $ruleLine = $fixOut -split "`n" | Where-Object { $_ -match '^FIX:.*(FAIL|✗|无法|未恢复|未完全|未找到)' } | Select-Object -Last 1
    if (-not $ruleLine) {
        $ruleLine = $fixOut -split "`n" | Where-Object { $_ -match '^FIX:.*(模式|规则|TUN)' } | Select-Object -Last 1
    }
    if ($ruleLine) {
        $win.FindName('Banner').Text = $ruleLine.Trim()
        if ($ruleLine -match 'FAIL|✗|无法|未恢复|未完全|未找到') {
            $win.FindName('Banner').Foreground = (New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(0xF8,0x71,0x71)))
        } else {
            $win.FindName('Banner').Foreground = (New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(0x60,0xA5,0xFA)))
        }
    }
})
$win.FindName('BtnA').Add_Click({ Switch-To 'A' })
$win.FindName('BtnB').Add_Click({ Switch-To 'B' })
$win.FindName('BtnSettings').Add_Click({ Show-CheckSettings })
$win.FindName('BtnDiagnostics').Add_Click({ Export-DiagnosticLog })

$win.FindName('BtnCheckUpdate').Add_Click({
    if ($script:updateRunning) { return }
    Remove-Item -LiteralPath (Join-Path $BASE 'update-check.json') -Force -ErrorAction SilentlyContinue
    Start-UpdateCheck $true
})

$win.FindName('BtnLater').Add_Click({
    if ($script:checkJob) {
        Stop-Job $script:checkJob -ErrorAction SilentlyContinue
        Remove-Job $script:checkJob -Force -ErrorAction SilentlyContinue
        $script:checkJob = $null
    }
    if ($script:checkTimer) { $script:checkTimer.Stop() }
    $win.FindName('UpdateBar').Visibility = 'Collapsed'
    $latest = if ($script:latestVersion) { [string]$script:latestVersion } else { '' }
    Write-UpdateCache 'dismissed' $latest
})

$win.FindName('BtnUpdate').Add_Click({
    if ($script:updateRunning) { return }
    $script:updateRunning = $true
    $btn = $win.FindName('BtnUpdate')
    $btn.IsEnabled = $false
    $win.FindName('BtnLater').IsEnabled = $false
    $win.FindName('BtnCheckUpdate').IsEnabled = $false
    if ($script:updateTimer) { $script:updateTimer.Stop(); $script:updateTimer = $null }
    Set-UpdateText '正在下载并校验…' '#FFE0E7FF'

    try {
        $script:updateJob = Start-Job -ScriptBlock {
            param($core)
            & powershell -NoProfile -ExecutionPolicy Bypass -File $core update-now 2>$null
        } -ArgumentList $CORE
    } catch {
        $script:updateRunning = $false
        $btn.IsEnabled = $true
        $win.FindName('BtnLater').IsEnabled = $true
        $win.FindName('BtnCheckUpdate').IsEnabled = $true
        Set-UpdateText ("更新失败：" + $_.Exception.Message) '#FFF87171'
        return
    }

    $script:updateTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:updateTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $script:updateTimer.Add_Tick({
        if (-not $script:updateJob) { $script:updateTimer.Stop(); return }
        $st = $script:updateJob.State
        if ($st -ne 'Completed' -and $st -ne 'Failed' -and $st -ne 'Stopped') { return }
        $script:updateTimer.Stop()
        $out = (Receive-Job $script:updateJob -ErrorAction SilentlyContinue | Out-String)
        Remove-Job $script:updateJob -Force -ErrorAction SilentlyContinue
        $script:updateJob = $null
        $script:updateRunning = $false
        $kv = ConvertFrom-UpdateOutput $out
        if ($kv['STATUS'] -eq 'updated') {
            Set-UpdateText '更新完成，正在重启界面' '#FF22C55E'
            Write-UpdateCache 'latest' ([string]$kv['LATEST'])
            if ($script:checkJob) {
                Stop-Job $script:checkJob -ErrorAction SilentlyContinue
                Remove-Job $script:checkJob -Force -ErrorAction SilentlyContinue
                $script:checkJob = $null
            }
            $uiScript = "$BASE\SwitcherUI.ps1"
            Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',('"' + $uiScript + '"')
            $win.Close()
        } elseif ($kv['STATUS'] -eq 'latest') {
            $win.FindName('BtnUpdate').IsEnabled = $true
            $win.FindName('BtnLater').IsEnabled = $true
            $win.FindName('BtnCheckUpdate').IsEnabled = $true
            Show-UpdateNote '已是最新版本' $false
            Write-UpdateCache 'latest' ([string]$kv['LATEST'])
        } else {
            $msg = if ($kv['MESSAGE']) { $kv['MESSAGE'] } else { '更新失败，请稍后重试' }
            Set-UpdateText ("更新失败：" + $msg) '#FFF87171'
            $win.FindName('BtnUpdate').IsEnabled = $true
            $win.FindName('BtnLater').IsEnabled = $true
            $win.FindName('BtnCheckUpdate').IsEnabled = $true
        }
    })
    $script:updateTimer.Start()
})

$win.Add_ContentRendered({
    Start-UpdateCheck $false
    Refresh-Checks
})
$win.Add_Closed({
    if ($script:checkTimer) { $script:checkTimer.Stop() }
    if ($script:updateTimer) { $script:updateTimer.Stop() }
    foreach ($j in @($script:checkJob, $script:updateJob)) {
        if ($j) {
            Stop-Job $j -ErrorAction SilentlyContinue
            Remove-Job $j -Force -ErrorAction SilentlyContinue
        }
    }
})
[void]$win.ShowDialog()
