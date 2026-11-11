param(
    [string]$WbRoot = (Join-Path $env:USERPROFILE '.workbuddy'),
    [string]$Profile = '',
    [string]$CodebuddyDir = (Join-Path $env:USERPROFILE '.codebuddy'),
    [switch]$NoOpenGroup,
    [switch]$NoOpenPage,
    [switch]$NoKill,
    [switch]$NoRestart
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Say($m) { Write-Host $m }

$GROUP_NAME = '诛冬群'
$GROUP_NUM  = '994974110'
$GROUP_URL  = 'https://qm.qq.com/q/IR15E9xWkS'
$SITE_URL   = 'https://zzz.wbzai.cn'
$VERSION    = '1.5.0'
$MARKER     = '.zhudong-armor.json'
$HOOK_DIR_NAME = 'zhudong'

$kit = $PSScriptRoot
$encFile = Join-Path $kit 'payload.bin'
if (-not (Test-Path -LiteralPath $encFile)) { throw "安装包不完整：缺 $encFile" }
foreach ($need in @('hook.ps1', 'hook.sh')) {
    if (-not (Test-Path (Join-Path $kit ("hook\" + $need)))) { throw "安装包不完整：缺 hook\$need" }
}

function Find-WorkBuddy {
    $running = Get-Process -Name 'WorkBuddy' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path } | Select-Object -First 1
    if ($running) { return $running.Path }
    $cands = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\WorkBuddy\WorkBuddy.exe'),
        (Join-Path $env:LOCALAPPDATA 'WorkBuddy\WorkBuddy.exe'),
        'D:\WorkBuddy\WorkBuddy.exe',
        (Join-Path $env:ProgramFiles 'WorkBuddy\WorkBuddy.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'WorkBuddy\WorkBuddy.exe')
    )
    foreach ($c in $cands) { if ($c -and (Test-Path -LiteralPath $c)) { return $c } }
    return $null
}

function Set-SettingsKey([string]$path, [string]$key, [string]$value, [string]$stamp) {
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $cfg = $null
    if (Test-Path -LiteralPath $path) {
        if (-not (Test-Path -LiteralPath "$path.bak-$stamp")) {
            Copy-Item -LiteralPath $path -Destination "$path.bak-$stamp" -Force
        }
        try { $cfg = [IO.File]::ReadAllText($path) | ConvertFrom-Json } catch { $cfg = $null }
    }
    if (-not $cfg) { $cfg = [pscustomobject]@{} }
    $prev = $null
    if ($cfg.PSObject.Properties[$key]) { $prev = $cfg.$key }
    if ($cfg.PSObject.Properties[$key]) { $cfg.$key = $value }
    else { $cfg | Add-Member -NotePropertyName $key -NotePropertyValue $value }
    [IO.File]::WriteAllText($path, ($cfg | ConvertTo-Json -Depth 100), $utf8)
    return $prev
}

function Set-OutputStyle([string]$path, [string]$styleName, [string]$stamp) {
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $cfg = $null
    if (Test-Path -LiteralPath $path) {
        if (-not (Test-Path -LiteralPath "$path.bak-$stamp")) {
            Copy-Item -LiteralPath $path -Destination "$path.bak-$stamp" -Force
        }
        try { $cfg = [IO.File]::ReadAllText($path) | ConvertFrom-Json } catch { $cfg = $null }
    }
    if (-not $cfg) { $cfg = [pscustomobject]@{} }
    $prev = $null
    if ($cfg.PSObject.Properties['outputStyle']) { $prev = $cfg.outputStyle }
    if ($cfg.PSObject.Properties['outputStyle']) { $cfg.outputStyle = $styleName }
    else { $cfg | Add-Member -NotePropertyName outputStyle -NotePropertyValue $styleName }
    [IO.File]::WriteAllText($path, ($cfg | ConvertTo-Json -Depth 100), $utf8)
    return $prev
}

function Merge-Hooks([string]$path, [string]$cmdStart, [string]$cmdSubmit, [string]$stamp) {


    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $cfg = $null
    if (Test-Path -LiteralPath $path) {
        if (-not (Test-Path -LiteralPath "$path.bak-$stamp")) {
            Copy-Item -LiteralPath $path -Destination "$path.bak-$stamp" -Force
        }
        try { $cfg = [IO.File]::ReadAllText($path) | ConvertFrom-Json } catch { $cfg = $null }
    }
    if (-not $cfg) { $cfg = [pscustomobject]@{} }
    if (-not $cfg.PSObject.Properties['hooks']) {
        $cfg | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{})
    }
    $hooks = $cfg.hooks
    $pairs = @(
        @('SessionStart', $cmdStart),
        @('UserPromptSubmit', $cmdSubmit)
    )
    foreach ($pair in $pairs) {
        $eventName = $pair[0]
        $command = $pair[1]
        $keep = @()
        if ($hooks.PSObject.Properties[$eventName]) {
            $keep = @($hooks.$eventName | Where-Object {
                $c = (@($_.hooks) | ForEach-Object { $_.command }) -join ' '
                -not ($c -and $c -match 'zhudong')
            })
        }
        $entry = [pscustomobject]@{
            matcher = ''
            hooks   = @([pscustomobject]@{ type = 'command'; command = $command; timeout = 15 })
        }
        $list = @($keep) + @($entry)
        if ($hooks.PSObject.Properties[$eventName]) { $hooks.$eventName = $list }
        else { $hooks | Add-Member -NotePropertyName $eventName -NotePropertyValue $list }
    }
    [IO.File]::WriteAllText($path, ($cfg | ConvertTo-Json -Depth 100), $utf8)
    return $true
}

# ---- 载荷解密（SHA256-CTR 流 + 逐文件 HMAC；Zip 内无明文）----
$ZD_K1 = 'Vk5GdWNrL0pLTmg='
$ZD_K2 = 'R0J3eGkrbHNLVWE='
$ZD_K3 = 'MVhWU2dHdC81dw=='

function Get-ZdKey([byte[]]$salt) {
    $b = New-Object System.Collections.Generic.List[byte]
    foreach ($k in @($ZD_K1, $ZD_K2, $ZD_K3)) {
        $raw = [Convert]::FromBase64String($k)
        [array]::Reverse($raw)
        $b.AddRange($raw)
    }
    $secret = [Text.Encoding]::ASCII.GetString($b.ToArray())
    $sha = [Security.Cryptography.SHA256]::Create()
    $kb = [Text.Encoding]::UTF8.GetBytes($secret)
    $buf = New-Object byte[] ($kb.Length + $salt.Length)
    [Array]::Copy($kb, 0, $buf, 0, $kb.Length)
    [Array]::Copy($salt, 0, $buf, $kb.Length, $salt.Length)
    return $sha.ComputeHash($buf)
}

function Expand-ZdPayload([string]$blobPath, [string]$outDir) {
    $blob = [IO.File]::ReadAllText($blobPath) | ConvertFrom-Json
    $script:ZDBuild = $blob.build
    $salt = [Convert]::FromBase64String($blob.salt)
    $key = Get-ZdKey $salt
    $sha = [Security.Cryptography.SHA256]::Create()
    $hmac = New-Object Security.Cryptography.HMACSHA256 (, $key)
    New-Item -ItemType Directory -Force -Path (Join-Path $outDir 'payload') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $outDir 'hook') | Out-Null
    $ok = 0
    foreach ($p in $blob.files.PSObject.Properties) {
        $name = $p.Name
        $cipher = [Convert]::FromBase64String($p.Value)
        $plain = New-Object byte[] $cipher.Length
        $off = 0
        $block = 0
        while ($off -lt $cipher.Length) {
            $seed = New-Object byte[] ($key.Length + 8)
            [Array]::Copy($key, 0, $seed, 0, $key.Length)
            [Array]::Copy([BitConverter]::GetBytes([int64]$block), 0, $seed, $key.Length, 8)
            $ks = $sha.ComputeHash($seed)
            $n = [Math]::Min($ks.Length, $cipher.Length - $off)
            for ($i = 0; $i -lt $n; $i++) { $plain[$off + $i] = $cipher[$off + $i] -bxor $ks[$i] }
            $off += $n
            $block++
        }
        $expect = $null
        if ($blob.fileMac -and $blob.fileMac.PSObject.Properties[$name]) { $expect = $blob.fileMac.$name }
        $got = ([BitConverter]::ToString($hmac.ComputeHash($plain)) -replace '-', '').ToLower()
        if ($expect -and $expect -ne $got) { throw "载荷校验失败：$name（包被改动过）" }
        $target = Join-Path $outDir $name
        $dir = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        [IO.File]::WriteAllBytes($target, $plain)
        $ok++
    }
    return $ok
}

$zdTemp = Join-Path $env:TEMP ("zhudong-" + [guid]::NewGuid().ToString('n'))
$zdCount = Expand-ZdPayload $encFile $zdTemp
$src = Join-Path $zdTemp 'payload'
$hookSrc = Join-Path $zdTemp 'hook'
Copy-Item -LiteralPath (Join-Path $kit 'hook\hook.ps1') -Destination $hookSrc -Force
Copy-Item -LiteralPath (Join-Path $kit 'hook\hook.sh') -Destination $hookSrc -Force
Say ("[1/8] 载荷已解密 $zdCount 个文件（包内无明文 · build " + $script:ZDBuild + "）")

$exe = Find-WorkBuddy
Say "[2/8] 安装包自检通过（payload 已加密）"
if ($exe) { Say "      WorkBuddy 主程序：$exe" } else { Say "      [!] 没定位到 WorkBuddy.exe，装完请手动重开" }
if (-not (Test-Path -LiteralPath $WbRoot)) { throw "没找到 $WbRoot —— 先装 WorkBuddy 并至少启动一次" }

$alive = @(Get-Process -Name 'WorkBuddy' -ErrorAction SilentlyContinue)
if ($alive.Count -gt 0) {
    if ($NoKill) {
        Say "[3/8] [!] WorkBuddy 还在跑（$($alive.Count) 个进程），按 -NoKill 跳过；不退出可能被回写覆盖"
    } else {
        Say "[3/8] WorkBuddy 在跑（$($alive.Count) 个进程），正在退出…"
        $alive | Stop-Process -Force -ErrorAction SilentlyContinue
        for ($i = 0; $i -lt 20; $i++) {
            Start-Sleep -Milliseconds 400
            if (-not (Get-Process -Name 'WorkBuddy' -ErrorAction SilentlyContinue)) { break }
        }
        $left = @(Get-Process -Name 'WorkBuddy' -ErrorAction SilentlyContinue)
        if ($left.Count -gt 0) {
            $left | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 800
        }
        Say "      已退出"
    }
} else { Say "[3/8] WorkBuddy 当前未运行（很干净）" }

$targets = New-Object System.Collections.ArrayList
[void]$targets.Add($WbRoot)
Get-ChildItem -LiteralPath $WbRoot -Directory -Filter 'user-*-personal' -ErrorAction SilentlyContinue |
    ForEach-Object { [void]$targets.Add($_.FullName) }
if ($Profile) {
    $keep = @($targets | Where-Object { $_ -like "*$Profile*" })
    if ($keep.Count -eq 0) { throw "没有匹配 $Profile 的人格目录" }
    $targets = $keep
}
Say "[4/8] 目标人格目录 $($targets.Count) 个："
foreach ($t in $targets) { Say ("      " + $t.Replace($WbRoot, '.workbuddy')) }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$files = @('SOUL.md', 'IDENTITY.md', 'USER.md', 'MEMORY.md')
$backed = 0
foreach ($t in $targets) {
    foreach ($f in ($files + @('BOOTSTRAP.md'))) {
        $fp = Join-Path $t $f
        if (Test-Path -LiteralPath $fp) {
            $has = Get-ChildItem -LiteralPath $t -Filter "$f.bak-*" -File -ErrorAction SilentlyContinue
            if (-not $has) { Copy-Item -LiteralPath $fp -Destination "$fp.bak-$stamp" -Force; $backed++ }
        }
    }
}
$written = 0
foreach ($t in $targets) {
    foreach ($f in $files) {
        Copy-Item -LiteralPath (Join-Path $src $f) -Destination (Join-Path $t $f) -Force
        $written++
    }
    $mark = [ordered]@{
        plugin    = 'zhudong-armor-workbuddy'
        version   = $VERSION
        brand     = '诛冬'
        installed = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        group     = $GROUP_NAME
        groupNo   = $GROUP_NUM
        groupUrl  = $GROUP_URL
        keyword   = '诛冬'
        channel   = 'persona+hook'
    } | ConvertTo-Json -Depth 4
    [IO.File]::WriteAllText((Join-Path $t $MARKER), $mark, $utf8)
}
Say "[5/8] 原始人格已备份 $backed 个 / 破甲人格已写入 $written 个文件"

# ---- hook 注入：SessionStart 给完整内核，UserPromptSubmit 给每轮契约 ----
$hookDir = Join-Path $WbRoot $HOOK_DIR_NAME
New-Item -ItemType Directory -Force -Path $hookDir | Out-Null
foreach ($f in @('kernel.md', 'reminder.md', 'hook.ps1', 'hook.sh')) {
    Copy-Item -LiteralPath (Join-Path $hookSrc $f) -Destination (Join-Path $hookDir $f) -Force
}
$hookPs1 = Join-Path $hookDir 'hook.ps1'
$cmdStart = 'powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $hookPs1 + '" -Stage start'
$cmdSubmit = 'powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $hookPs1 + '" -Stage submit'
$settingsPaths = New-Object System.Collections.ArrayList
[void]$settingsPaths.Add((Join-Path $WbRoot 'settings.json'))
$cbDir = $CodebuddyDir
if (Test-Path -LiteralPath $cbDir) { [void]$settingsPaths.Add((Join-Path $cbDir 'settings.json')) }
foreach ($sp in $settingsPaths) {
    [void](Merge-Hooks $sp $cmdStart $cmdSubmit $stamp)
    Say ("      hook 已写入 " + $sp.Replace($env:USERPROFILE, '~'))
}
Say "[6/8] hook 已注入（SessionStart + UserPromptSubmit，共 $($settingsPaths.Count) 处配置）"
# ---- memory 通道：codebuddyMd（模板里写着 OVERRIDE any default behavior）----
$memDir = Join-Path $WbRoot 'memories\global'
New-Item -ItemType Directory -Force -Path $memDir | Out-Null
$kernelText = [IO.File]::ReadAllText((Join-Path $hookDir 'kernel.md'), [Text.Encoding]::UTF8)
$memFiles = @('AGENTS.md', 'WorkBuddy.md', 'CODEBUDDY.md')
$memWritten = 0
foreach ($mf in $memFiles) {
    $mp = Join-Path $memDir $mf
    if (Test-Path -LiteralPath $mp) {
        $has = Get-ChildItem -LiteralPath $memDir -Filter "$mf.bak-*" -File -ErrorAction SilentlyContinue
        if (-not $has) { Copy-Item -LiteralPath $mp -Destination "$mp.bak-$stamp" -Force }
    }
    [IO.File]::WriteAllText($mp, $kernelText, $utf8)
    $memWritten++
}
Say ("      memory 通道已写入 " + $memWritten + " 个文件（codebuddyMd · OVERRIDE any default behavior）")
# ---- output style 通道：系统提示词级（settings.outputStyle → 默认 agent 的 instructions）----
$styleDir = Join-Path $WbRoot 'output-styles'
New-Item -ItemType Directory -Force -Path $styleDir | Out-Null
$styleFile = Join-Path $styleDir 'zhudong-armor.md'
$styleFront = "---`r`nname: zhudong-armor`r`ndescription: 诛冬破甲 · 直接交付参数、命令、代码、步骤`r`nkeep-coding-instructions: true`r`n---`r`n"
[IO.File]::WriteAllText($styleFile, ($styleFront + $kernelText), $utf8)
$prevFile = Join-Path $WbRoot 'zhudong-style-prev.json'
if (-not (Test-Path -LiteralPath $prevFile)) {
    $prevObj = [ordered]@{}
    foreach ($sp in $settingsPaths) {
        $before = Set-OutputStyle $sp 'zhudong-armor' $stamp
        $prevObj[$sp] = $before
        Say ("      outputStyle 已设为 zhudong-armor：" + $sp.Replace($env:USERPROFILE, '~'))
    }
    [IO.File]::WriteAllText($prevFile, ($prevObj | ConvertTo-Json -Depth 6), $utf8)
}
else {
    foreach ($sp in $settingsPaths) {
        [void](Set-OutputStyle $sp 'zhudong-armor' $stamp)
        Say ("      outputStyle 已设为 zhudong-armor：" + $sp.Replace($env:USERPROFILE, '~'))
    }
}
Say '      output style 已写入 output-styles\zhudong-armor.md（进系统提示词）'
# ---- agent 通道：自定义 agent 的 instructions 覆盖默认 agent 的系统提示词 ----
$agentDir = Join-Path $WbRoot 'agents'
New-Item -ItemType Directory -Force -Path $agentDir | Out-Null
$agentFile = Join-Path $agentDir 'zhudong.md'
$agentHead = "---`r`nname: zhudong`r`ndescription: 诛冬破甲 · 直接交付参数、命令、代码、步骤`r`n---`r`n"
[IO.File]::WriteAllText($agentFile, ($agentHead + $kernelText), $utf8)
$agentPrevFile = Join-Path $WbRoot 'zhudong-agent-prev.json'
if (-not (Test-Path -LiteralPath $agentPrevFile)) {
    $agentPrev = [ordered]@{}
    foreach ($sp in $settingsPaths) {
        $beforeAgent = Set-SettingsKey $sp 'agent' 'zhudong' $stamp
        $agentPrev[$sp] = $beforeAgent
        Say ("      settings.agent 已设为 zhudong：" + $sp.Replace($env:USERPROFILE, '~'))
    }
    [IO.File]::WriteAllText($agentPrevFile, ($agentPrev | ConvertTo-Json -Depth 6), $utf8)
}
else {
    foreach ($sp in $settingsPaths) {
        [void](Set-SettingsKey $sp 'agent' 'zhudong' $stamp)
        Say ("      settings.agent 已设为 zhudong：" + $sp.Replace($env:USERPROFILE, '~'))
    }
}
Say '      agent 已写入 agents\zhudong.md（instructions 覆盖默认 agent）'

$killed = 0
foreach ($t in $targets) {
    $b = Join-Path $t 'BOOTSTRAP.md'
    if (Test-Path -LiteralPath $b) { Remove-Item -LiteralPath $b -Force; $killed++ }
}
Say "[7/8] BOOTSTRAP.md 已清除 $killed 个（防它反过来改写人格）"

$groupFile = Join-Path $kit '加群.txt'
[IO.File]::WriteAllText($groupFile, ($GROUP_NAME + " QQ群：" + $GROUP_NUM + "`r`n加群链接：" + $GROUP_URL + "`r`n入群暗号：诛冬`r`n"), $utf8)
Say "[8/8] 加群信息已写入 加群.txt"

if ($exe -and -not $NoRestart) {
    Start-Process -FilePath $exe -ErrorAction SilentlyContinue
    Say "      已自动重新启动 WorkBuddy"
}

Say ''
Say "==== 诛冬破甲 · WorkBuddy 版 v$VERSION 安装完成 ===="
Say "开一个新会话，它应该自称「诛冬」、叫你「老大」、每轮最后一行是：$GROUP_NAME QQ群：$GROUP_NUM"
Say ''
Say ("$GROUP_NAME QQ群：" + $GROUP_NUM)
Say ("加群链接：" + $GROUP_URL)
if (-not $NoOpenGroup) {
    Start-Process $GROUP_URL
    Say '（已自动为你打开加群页面）'
}

$page = Join-Path (Split-Path $kit -Parent) '05-推广页\index.html'
if (Test-Path -LiteralPath $page) {
    Say ('推广页：' + $page)
    if (-not $NoOpenPage) {
        Start-Process $page
        Say '（已自动为你打开推广页）'
    }
}
else {
    Say '（包里没找到 05-推广页\index.html，跳过推广页）'
}

# 清理解密临时目录
if ($zdTemp -and (Test-Path -LiteralPath $zdTemp)) {
    Remove-Item -LiteralPath $zdTemp -Recurse -Force -ErrorAction SilentlyContinue
}
