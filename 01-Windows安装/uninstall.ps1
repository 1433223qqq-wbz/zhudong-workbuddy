param(
    [string]$WbRoot = (Join-Path $env:USERPROFILE '.workbuddy'),
    [string]$Profile = '',
    [string]$CodebuddyDir = (Join-Path $env:USERPROFILE '.codebuddy')
)
$ErrorActionPreference = 'Stop'
function Say($m) { Write-Host $m }
$utf8 = New-Object System.Text.UTF8Encoding($false)
$MARKER = '.zhudong-armor.json'
$files = @('SOUL.md', 'IDENTITY.md', 'USER.md', 'MEMORY.md', 'BOOTSTRAP.md')

if (-not (Test-Path -LiteralPath $WbRoot)) { throw "没找到 $WbRoot" }
$targets = New-Object System.Collections.ArrayList
[void]$targets.Add($WbRoot)
Get-ChildItem -LiteralPath $WbRoot -Directory -Filter 'user-*-personal' -ErrorAction SilentlyContinue |
    ForEach-Object { [void]$targets.Add($_.FullName) }
if ($Profile) {
    $keep = @($targets | Where-Object { $_ -like "*$Profile*" })
    if ($keep.Count -eq 0) { throw "没有匹配 $Profile 的人格目录" }
    $targets = $keep
}
Say "== 诛冬破甲 · WorkBuddy 版 卸载 =="
Say "目标人格目录 $($targets.Count) 个"

$restored = 0; $removed = 0
foreach ($t in $targets) {
    foreach ($f in $files) {
        $fp = Join-Path $t $f
        $bak = Get-ChildItem -LiteralPath $t -Filter "$f.bak-*" -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($bak) {
            Copy-Item -LiteralPath $bak.FullName -Destination $fp -Force
            $restored++
        }
        elseif (Test-Path -LiteralPath $fp) {
            $text = Get-Content -LiteralPath $fp -Raw -Encoding UTF8
            if ($text -match 'ZHUODONG-ARMOR-WORKBUDDY|诛冬破甲|诛冬群|994974110') {
                Remove-Item -LiteralPath $fp -Force
                $removed++
            }
        }
    }
    $m = Join-Path $t $MARKER
    if (Test-Path -LiteralPath $m) { Remove-Item -LiteralPath $m -Force }
    $mydir = Join-Path $t 'payload'
    if (Test-Path -LiteralPath $mydir) { Remove-Item -LiteralPath $mydir -Recurse -Force }
}

# hook 摘除
function Remove-Hooks([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return $false }
    try { $cfg = [IO.File]::ReadAllText($path) | ConvertFrom-Json } catch { return $false }
    if (-not $cfg.PSObject.Properties['hooks']) { return $false }
    $hooks = $cfg.hooks
    $changed = $false
    foreach ($ev in @('SessionStart', 'UserPromptSubmit')) {
        if (-not $hooks.PSObject.Properties[$ev]) { continue }
        $keep = @($hooks.$ev | Where-Object {
            $c = (@($_.hooks) | ForEach-Object { $_.command }) -join ' '
            -not ($c -and $c -match 'zhudong')
        })
        if ($keep.Count -ne @($hooks.$ev).Count) { $changed = $true }
        $hooks.$ev = $keep
    }
    if ($changed) {
        [IO.File]::WriteAllText($path, ($cfg | ConvertTo-Json -Depth 100), $utf8)
        return $true
    }
    return $false
}
$hookRemoved = 0
foreach ($sp in @((Join-Path $WbRoot 'settings.json'), (Join-Path $CodebuddyDir 'settings.json'))) {
    if (Remove-Hooks $sp) { $hookRemoved++; Say ("已摘除 hook：" + $sp) }
}
$hookDir = Join-Path $WbRoot 'zhudong'
if (Test-Path -LiteralPath $hookDir) { Remove-Item -LiteralPath $hookDir -Recurse -Force; Say "已删 hook 目录" }

# ---- memory 通道回滚 ----
$memDir = Join-Path $WbRoot 'memories\global'
$memRemoved = 0
if (Test-Path -LiteralPath $memDir) {
    foreach ($mf in @('AGENTS.md', 'WorkBuddy.md', 'CODEBUDDY.md')) {
        $mp = Join-Path $memDir $mf
        if (-not (Test-Path -LiteralPath $mp)) { continue }
        $bak = Get-ChildItem -LiteralPath $memDir -Filter "$mf.bak-*" -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($bak) { Copy-Item -LiteralPath $bak.FullName -Destination $mp -Force }
        else {
            $t = Get-Content -LiteralPath $mp -Raw -Encoding UTF8
            if ($t -match 'ZHUODONG-ARMOR-WORKBUDDY|994974110|诛冬') { Remove-Item -LiteralPath $mp -Force }
        }
        $memRemoved++
    }
}
if ($memRemoved -gt 0) { Say "已回滚 memory 通道 $memRemoved 个文件" }
# ---- output style 回滚 ----
$styleFile = Join-Path $WbRoot 'output-styles\zhudong-armor.md'
if (Test-Path -LiteralPath $styleFile) { Remove-Item -LiteralPath $styleFile -Force; Say '已删 output style 文件' }
$prevFile = Join-Path $WbRoot 'zhudong-style-prev.json'
if (Test-Path -LiteralPath $prevFile) {
    try {
        $map = [IO.File]::ReadAllText($prevFile) | ConvertFrom-Json
        foreach ($prop in $map.PSObject.Properties) {
            $k2 = $prop.Name
            if (-not (Test-Path -LiteralPath $k2)) { continue }
            try { $cfg = [IO.File]::ReadAllText($k2) | ConvertFrom-Json } catch { continue }
            if ($null -ne $prop.Value) {
                if ($cfg.PSObject.Properties['outputStyle']) { $cfg.outputStyle = $prop.Value }
                else { $cfg | Add-Member -NotePropertyName outputStyle -NotePropertyValue $prop.Value }
            }
            elseif ($cfg.PSObject.Properties['outputStyle']) { $cfg.PSObject.Properties.Remove('outputStyle') }
            [IO.File]::WriteAllText($k2, ($cfg | ConvertTo-Json -Depth 100), $utf8)
            Say ("已还原 outputStyle：" + $k2.Replace($env:USERPROFILE, '~'))
# ---- agent 通道回滚 ----
$agentFile = Join-Path $WbRoot 'agents\zhudong.md'
if (Test-Path -LiteralPath $agentFile) { Remove-Item -LiteralPath $agentFile -Force; Say '已删 agent 文件' }
$agentPrevFile = Join-Path $WbRoot 'zhudong-agent-prev.json'
if (Test-Path -LiteralPath $agentPrevFile) {
    try {
        $amap = [IO.File]::ReadAllText($agentPrevFile) | ConvertFrom-Json
        foreach ($prop in $amap.PSObject.Properties) {
            $k2 = $prop.Name
            if (-not (Test-Path -LiteralPath $k2)) { continue }
            try { $cfg = [IO.File]::ReadAllText($k2) | ConvertFrom-Json } catch { continue }
            if ($null -ne $prop.Value) {
                if ($cfg.PSObject.Properties['agent']) { $cfg.agent = $prop.Value }
                else { $cfg | Add-Member -NotePropertyName agent -NotePropertyValue $prop.Value }
            }
            elseif ($cfg.PSObject.Properties['agent']) { $cfg.PSObject.Properties.Remove('agent') }
            [IO.File]::WriteAllText($k2, ($cfg | ConvertTo-Json -Depth 100), $utf8)
            Say ("已还原 settings.agent：" + $k2.Replace($env:USERPROFILE, '~'))
        }
    } catch { }
    Remove-Item -LiteralPath $agentPrevFile -Force
}
        }
    } catch { }
    Remove-Item -LiteralPath $prevFile -Force
}

Say "已还原 $restored 个文件，清理无备份的破甲文件 $removed 个，摘除 hook 配置 $hookRemoved 处"
Say '卸载完成：完全退出 WorkBuddy（托盘也退）再重新打开。'
