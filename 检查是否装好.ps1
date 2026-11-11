# 检查是否装好.bat   （双击运行，只读检查，不改任何东西）
param(
    [string]$WbRoot = (Join-Path $env:USERPROFILE '.workbuddy'),
    [string]$CodebuddyDir = (Join-Path $env:USERPROFILE '.codebuddy')
)
$wb = $WbRoot
$GROUP_NAME = '诛冬群'
$GROUP_NUM = '994974110'
$GROUP_URL = 'https://qm.qq.com/q/IR15E9xWkS'

Write-Host '========== 诛冬破甲 · WorkBuddy 版 安装状态 =========='
if (-not (Test-Path $wb)) { Write-Host '[X] 没找到 .workbuddy 目录，先装 WorkBuddy 并启动一次'; Write-Host ''; pause; exit 1 }

$targets = New-Object System.Collections.ArrayList
[void]$targets.Add($wb)
Get-ChildItem -LiteralPath $wb -Directory -Filter 'user-*-personal' | ForEach-Object { [void]$targets.Add($_.FullName) }

$ok = $true
foreach ($t in $targets) {
    $name = $t.Replace($wb, '.workbuddy')
    $soul = Join-Path $t 'SOUL.md'
    if (-not (Test-Path -LiteralPath $soul)) { Write-Host "[!] $name 没有 SOUL.md"; $ok = $false; continue }
    $text = Get-Content -LiteralPath $soul -Raw -Encoding UTF8
    $len = $text.Length
    $armed  = if ($text -match 'ZHUODONG-ARMOR-WORKBUDDY|破甲内核') { 'OK 破甲内核' } else { 'X 未装载' }
    $boss   = if ($text -match '老大') { 'OK 称呼' } else { 'X 称呼' }
    $promo  = if ($text -match '994974110') { 'OK 群收尾' } else { 'X 群收尾' }
    $trunc  = if ($len -le 10000) { "OK 长度$len" } else { "X 超10000($len)会被截断" }
    $boot   = if (Test-Path -LiteralPath (Join-Path $t 'BOOTSTRAP.md')) { 'X 仍在(会重置人格)' } else { 'OK 已清除' }
    $mark   = if (Test-Path -LiteralPath (Join-Path $t '.zhudong-armor.json')) { 'OK 标记' } else { 'X 无标记' }
    Write-Host ("{0,-40} {1} | {2} | {3} | {4} | BOOTSTRAP {5} | {6}" -f $name, $armed, $boss, $promo, $trunc, $boot, $mark)
    if ($armed -ne 'OK 破甲内核' -or $boot -ne 'OK 已清除' -or $promo -ne 'OK 群收尾' -or $len -gt 10000) { $ok = $false }
}

# hook 通道
$hookFile = Join-Path $wb 'zhudong\hook.ps1'
$hookOk = Test-Path -LiteralPath $hookFile
Write-Host ''
Write-Host ("hook 脚本: " + $(if ($hookOk) { 'OK ' + $hookFile } else { 'X 缺 ' + $hookFile }))
if (-not $hookOk) { $ok = $false }
foreach ($sp in @((Join-Path $wb 'settings.json'), (Join-Path $CodebuddyDir 'settings.json'))) {
    if (-not (Test-Path -LiteralPath $sp)) { continue }
    $raw = Get-Content -LiteralPath $sp -Raw -Encoding UTF8
    $ss = if ($raw -match '"SessionStart"' -and $raw -match 'zhudong') { 'OK' } else { 'X' }
    $up = if ($raw -match '"UserPromptSubmit"' -and $raw -match 'zhudong') { 'OK' } else { 'X' }
    Write-Host ("{0,-52} SessionStart {1} | UserPromptSubmit {2}" -f $sp.Replace($env:USERPROFILE, '~'), $ss, $up)
    if ($ss -ne 'OK' -or $up -ne 'OK') { $ok = $false }
}

# output style 通道（v1.5.0 主力：进系统提示词的 instructions）
$styleFile = Join-Path $wb 'output-styles\zhudong-armor.md'
$styleOk = (Test-Path -LiteralPath $styleFile) -and ((Get-Content -LiteralPath $styleFile -Raw -Encoding UTF8) -match '994974110')
Write-Host ("output style: " + $(if ($styleOk) { 'OK output-styles\zhudong-armor.md' } else { 'X 缺 output-styles\zhudong-armor.md' }))
if (-not $styleOk) { $ok = $false }
foreach ($sp in @((Join-Path $wb 'settings.json'), (Join-Path $CodebuddyDir 'settings.json'))) {
    if (-not (Test-Path -LiteralPath $sp)) { continue }
    $c = $null
    try { $c = [IO.File]::ReadAllText($sp) | ConvertFrom-Json } catch { }
    $val = if ($c -and $c.PSObject.Properties['outputStyle']) { [string]$c.outputStyle } else { '(未设置)' }
    Write-Host ($sp.Replace($env:USERPROFILE, '~') + "   outputStyle = " + $val)
}

# memory 通道
$memDir = Join-Path $wb 'memories\global'
$memHit = $false
foreach ($mf in @('AGENTS.md', 'WorkBuddy.md', 'CODEBUDDY.md')) {
    $mp = Join-Path $memDir $mf
    if ((Test-Path -LiteralPath $mp) -and ((Get-Content -LiteralPath $mp -Raw -Encoding UTF8) -match '994974110')) { $memHit = $true }
}
Write-Host ("memory 通道: " + $(if ($memHit) { 'OK memories\global' } else { 'X 缺 memories\global 内核文件' }))
if (-not $memHit) { $ok = $false }

# 模型通道诊断：读最近一次会话日志
Write-Host ''
Write-Host '---------- 模型通道 ----------'
$logDir = Join-Path $wb 'logs'
$latest = Get-ChildItem -LiteralPath $logDir -Recurse -Filter '2026-*-*-*__*.log' -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latest) {
    $txt = [IO.File]::ReadAllText($latest.FullName)
    $modelM = [regex]::Match($txt, 'CLI --model option set: ([^\r\n]+)')
    $urlM = [regex]::Match($txt, 'Sending request:[^\r\n]*?url=(http[^\s,]+)')
    $model = if ($modelM.Success) { $modelM.Groups[1].Value.Trim() } else { '(未读到)' }
    $endpoint = if ($urlM.Success) { $urlM.Groups[1].Value.Trim() } else { '(未读到)' }
    Write-Host ("当前模型: " + $model)
    Write-Host ("请求端点: " + $endpoint)
    if ($endpoint -match 'workbuddy\.cn|tencent') {
        Write-Host '[!] 走的是 WorkBuddy 官方网关：服务端有自己的系统提示词与审核，人格与 hook 都会被压住。'
        Write-Host '    切到自带的自定义模型（models.json 里的 deepseek-v4-pro / gpt-6-sol → https://zzz.wbzai.cn/v1）再试。'
    } else {
        Write-Host '[OK] 走的是你自己的 API 端点，破甲通道可用。'
    }
} else {
    Write-Host '(没找到会话日志，先在 WorkBuddy 里发一句话再看)'
}

Write-Host ''
if ($ok) {
    Write-Host '结论：安装完整（人格 + hook 双通道都在）。若行为没变，是完全退出 WorkBuddy 后没重启，或旧会话缓存——开个新会话再试。'
} else {
    Write-Host '结论：有缺项。重跑 01-Windows安装\安装.bat；仍不行把这份输出截图发出来。'
}
Write-Host ''
Write-Host ($GROUP_NAME + " QQ群：" + $GROUP_NUM + "（加群链接 " + $GROUP_URL + "，暗号：诛冬）")
Write-Host ''
pause
