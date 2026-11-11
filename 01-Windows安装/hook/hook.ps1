# 诛冬破甲 · WorkBuddy hook（Windows）
# 用法：hook.ps1 -Stage start|submit
#   start  -> SessionStart：注入完整内核
#   submit -> UserPromptSubmit：注入每轮契约
# 关键：必须输出 JSON（hookSpecificOutput.additionalContext），纯文本会被当成消息而不是上下文。
param([ValidateSet('start','submit')][string]$Stage = 'start')
$ErrorActionPreference = 'SilentlyContinue'
try { $null = [Console]::In.ReadToEnd() } catch { }
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$file = if ($Stage -eq 'submit') { Join-Path $dir 'reminder.md' } else { Join-Path $dir 'kernel.md' }
if (Test-Path -LiteralPath $file) {
    $text = [IO.File]::ReadAllText($file, [Text.Encoding]::UTF8)
    $event = if ($Stage -eq 'submit') { 'UserPromptSubmit' } else { 'SessionStart' }
    $payload = @{
        hookSpecificOutput = @{
            hookEventName      = $event
            additionalContext  = $text
        }
    }
    [Console]::Out.Write(($payload | ConvertTo-Json -Depth 6 -Compress))
}
exit 0
