#!/bin/bash
# 诛冬破甲 · WorkBuddy 版 v1.5.0  macOS 卸载脚本
set -u
WB="${WB_HOME:-$HOME/.workbuddy}"
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -d "$WB" ] || { echo "找不到 $WB"; exit 1; }

TARGETS=("$WB")
while IFS= read -r d; do TARGETS+=("$d"); done < <(find "$WB" -maxdepth 1 -type d -name 'user-*-personal' 2>/dev/null)

echo "== 诛冬破甲 · WorkBuddy 版 卸载 =="
echo "目标人格目录 ${#TARGETS[@]} 个"
RESTORED=0; REMOVED=0
for t in "${TARGETS[@]}"; do
  for f in SOUL.md IDENTITY.md USER.md MEMORY.md BOOTSTRAP.md; do
    BAK="$(ls -t "$t/$f".bak-* 2>/dev/null | head -n 1)"
    if [ -n "$BAK" ]; then cp "$BAK" "$t/$f"; RESTORED=$((RESTORED+1));
    elif [ -f "$t/$f" ]; then
      if grep -q 'ZHUODONG-ARMOR-WORKBUDDY\|诛冬破甲\|诛冬群\|994974110' "$t/$f" 2>/dev/null; then rm -f "$t/$f"; REMOVED=$((REMOVED+1)); fi
    fi
  done
  rm -f "$t/.zhudong-armor.json"
  [ -d "$t/payload" ] && rm -rf "$t/payload"
done

if command -v python3 >/dev/null 2>&1; then
  python3 "$HERE/hook_merge.py" remove "$WB/settings.json" || true
  [ -d "$HOME/.codebuddy" ] && python3 "$HERE/hook_merge.py" remove "$HOME/.codebuddy/settings.json" || true
else
  echo "[!] 没有 python3，hooks 没摘；手动删 settings.json 里含 zhudong 的那两条 hook"
fi
rm -rf "$WB/zhudong"
echo "已还原 $RESTORED 个文件，清理无备份的破甲文件 $REMOVED 个，hooks 已摘"
echo "卸载完成：完全退出 WorkBuddy（⌘Q）再重新打开。"
