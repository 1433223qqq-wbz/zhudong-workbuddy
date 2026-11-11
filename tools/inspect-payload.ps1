# inspect-payload.ps1 -- decrypt payload.bin, verify per-file HMAC, write plaintext to -Out
# Does NOT install anything, does NOT touch ~/.workbuddy.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\inspect-payload.ps1 -Out .\unpacked
#   powershell -ExecutionPolicy Bypass -File tools\inspect-payload.ps1 -Bin <payload.bin> -Out <dir>
#
# ASCII-only on purpose: UTF-8-without-BOM scripts are mis-decoded by Windows PowerShell 5.1.

[CmdletBinding()]
param(
    [string]$Bin,
    [string]$Out
)

$ErrorActionPreference = 'Stop'

if (-not $Out) { $Out = Join-Path (Get-Location) 'unpacked' }
if (-not $Bin) {
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    $repo = Split-Path -Parent $here
    $hit = Get-ChildItem -LiteralPath $repo -Recurse -File -Filter 'payload.bin' -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $hit) { throw "payload.bin not found under $repo; pass -Bin explicitly" }
    $Bin = $hit.FullName
}

if (Test-Path -LiteralPath $Out) { Remove-Item -LiteralPath $Out -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Out | Out-Null

# --- key material (obfuscated the same way the installer ships it) ---
$ZD_K1 = 'Vk5GdWNrL0pLTmg='
$ZD_K2 = 'R0J3eGkrbHNLVWE='
$ZD_K3 = 'MVhWU2dHdC81dw=='

$acc = New-Object System.Collections.Generic.List[byte]
foreach ($k in @($ZD_K1, $ZD_K2, $ZD_K3)) {
    $raw = [Convert]::FromBase64String($k)
    [array]::Reverse($raw)
    $acc.AddRange($raw)
}
$secret = [Text.Encoding]::ASCII.GetString($acc.ToArray())

$blob = [IO.File]::ReadAllText($Bin) | ConvertFrom-Json
$salt = [Convert]::FromBase64String($blob.salt)

$sha = [Security.Cryptography.SHA256]::Create()
$kb = [Text.Encoding]::UTF8.GetBytes($secret)
$buf = New-Object byte[] ($kb.Length + $salt.Length)
[Array]::Copy($kb, 0, $buf, 0, $kb.Length)
[Array]::Copy($salt, 0, $buf, $kb.Length, $salt.Length)
$key = $sha.ComputeHash($buf)
$hmac = New-Object Security.Cryptography.HMACSHA256 (, $key)

Write-Output ("payload = {0}" -f $Bin)
Write-Output ("secret  = {0}" -f $secret)
Write-Output ("build   = {0}  (v={1})" -f $blob.build, $blob.v)
Write-Output ''

$fail = 0
$n = 0
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
        $step = [Math]::Min($ks.Length, $cipher.Length - $off)
        for ($i = 0; $i -lt $step; $i++) { $plain[$off + $i] = $cipher[$off + $i] -bxor $ks[$i] }
        $off += $step
        $block++
    }

    $expect = $null
    if ($blob.fileMac -and $blob.fileMac.PSObject.Properties[$name]) { $expect = [string]$blob.fileMac.$name }
    $got = ([BitConverter]::ToString($hmac.ComputeHash($plain)) -replace '-', '').ToLower()
    $mac = 'MAC n/a'
    if ($expect) { if ($expect -eq $got) { $mac = 'MAC OK' } else { $mac = 'MAC FAIL'; $fail++ } }

    $target = Join-Path $Out ($name -replace '/', '\')
    $dir = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [IO.File]::WriteAllBytes($target, $plain)

    $h = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    Write-Output ("{0,-26} {1,7} bytes  {2}  sha256={3}" -f $name, $plain.Length, $mac, $h.Substring(0, 16))
    $n++
}

# watermarks
try {
    $kernelPath = Join-Path $Out 'hook\kernel.md'
    if (Test-Path -LiteralPath $kernelPath) {
        $raw = [IO.File]::ReadAllText($kernelPath)
        $zw = @($raw.ToCharArray() | Where-Object { [int]$_ -in 0x200B, 0x200C, 0x200D, 0xFEFF, 0x2060 })
        $zwsp = @($zw | Where-Object { [int]$_ -eq 0x200B }).Count
        $zwnj = @($zw | Where-Object { [int]$_ -eq 0x200C }).Count
        Write-Output ''
        Write-Output ("watermark U+200B x{0}  U+200C x{1}" -f $zwsp, $zwnj)
    }
} catch { Write-Verbose 'watermark scan skipped' }

Write-Output ''
Write-Output ("files = {0}   failed = {1}   out = {2}" -f $n, $fail, $Out)
if ($fail -gt 0) { Write-Output 'RESULT: FAIL'; exit 1 }
Write-Output 'RESULT: OK'
