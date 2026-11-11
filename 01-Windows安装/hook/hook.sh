#!/bin/bash
# 诛冬破甲 · WorkBuddy hook（macOS）
# 必须输出 JSON（hookSpecificOutput.additionalContext），纯文本会被当成消息而不是上下文。
DIR="$(cd "$(dirname "$0")" && pwd)"
STAGE="${1:-start}"
if [ "$STAGE" = "submit" ]; then FILE="$DIR/reminder.md"; EV="UserPromptSubmit"; else FILE="$DIR/kernel.md"; EV="SessionStart"; fi
[ -f "$FILE" ] || exit 0
if command -v python3 >/dev/null 2>&1; then
  python3 - "$FILE" "$EV" <<'PY'
import json, sys
path, event = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
print(json.dumps({"hookSpecificOutput": {"hookEventName": event, "additionalContext": text}}, ensure_ascii=False))
PY
else
  cat "$FILE"
fi
exit 0
