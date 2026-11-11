#!/bin/bash
# 诛冬破甲 · WorkBuddy 版 v1.5.0  macOS 安装脚本
# 诛冬群 QQ群 994974110  https://qm.qq.com/q/IR15E9xWkS
# 用法：bash install-mac.command
#   不自动开加群页：ZHUODONG_NO_OPEN_GROUP=1
#   不自动开推广页：ZHUODONG_NO_OPEN_PAGE=1
set -u

WB="${WB_HOME:-$HOME/.workbuddy}"
HERE="$(cd "$(dirname "$0")" && pwd)"
if ! command -v python3 >/dev/null 2>&1; then
  echo "本包装载体已加密，macOS 需要 python3 解密：xcode-select --install 后重跑"
  exit 1
fi
ZD_TMP="$(mktemp -d)"
trap 'rm -rf "$ZD_TMP"' EXIT
python3 "$HERE/unpack.py" "$HERE/payload.bin" "$ZD_TMP" || { echo "载荷解密失败"; exit 1; }
SRC="$ZD_TMP/payload"
HOOKSRC="$ZD_TMP/hook"
cp "$HERE/hook/hook.ps1" "$HERE/hook/hook.sh" "$HOOKSRC"/ 2>/dev/null
GROUP_NAME="诛冬群"
GROUP_NUM="994974110"
GROUP_URL="https://qm.qq.com/q/IR15E9xWkS"

if [ ! -d "$WB" ]; then
  echo "找不到 $WB"
  echo "先在 Mac 上安装 WorkBuddy 并启动一次，让它生成 ~/.workbuddy 再回来装。"
  exit 1
fi
for f in SOUL.md IDENTITY.md USER.md MEMORY.md; do
  if [ ! -f "$SRC/$f" ]; then echo "安装包不完整：缺 payload/$f（请完整解压）"; exit 1; fi
done
for f in hook.ps1 hook.sh; do
  if [ ! -f "$HOOKSRC/$f" ]; then echo "安装包不完整：缺 hook/$f（请完整解压）"; exit 1; fi
done
echo "==> [1/7] 安装包自检通过（payload 4 个 + hook 4 个）"

STAMP="$(date +%Y%m%d-%H%M%S)"
TARGETS=("$WB")
while IFS= read -r d; do TARGETS+=("$d"); done < <(find "$WB" -maxdepth 1 -type d -name 'user-*-personal' 2>/dev/null)

echo "==> [2/7] 目标人格目录 ${#TARGETS[@]} 个："
for t in "${TARGETS[@]}"; do echo "      ${t/#$WB/.workbuddy}"; done

BACKED=0
for t in "${TARGETS[@]}"; do
  for f in SOUL.md IDENTITY.md USER.md MEMORY.md BOOTSTRAP.md; do
    if [ -f "$t/$f" ]; then
      if ! ls "$t/$f".bak-* >/dev/null 2>&1; then cp "$t/$f" "$t/$f.bak-$STAMP"; BACKED=$((BACKED+1)); fi
    fi
  done
done

WRITTEN=0
for t in "${TARGETS[@]}"; do
  for f in SOUL.md IDENTITY.md USER.md MEMORY.md; do cp "$SRC/$f" "$t/$f"; WRITTEN=$((WRITTEN+1)); done
  cat > "$t/.zhudong-armor.json" <<JSON
{
  "plugin": "zhudong-armor-workbuddy",
  "version": "1.5.0",
  "brand": "诛冬",
  "installed": "$(date '+%Y-%m-%d %H:%M:%S')",
  "group": "$GROUP_NAME",
  "groupNo": "$GROUP_NUM",
  "groupUrl": "$GROUP_URL",
  "keyword": "诛冬",
  "channel": "persona+hook"
}
JSON
done
echo "==> [3/7] 人格已写入 $WRITTEN 个文件（备份 $BACKED 个）"

HOOKDIR="$WB/zhudong"
mkdir -p "$HOOKDIR"
cp "$HOOKSRC/kernel.md" "$HOOKSRC/reminder.md" "$HOOKSRC/hook.ps1" "$HOOKSRC/hook.sh" "$HOOKDIR"/ 2>/dev/null
chmod +x "$HOOKDIR/hook.sh" 2>/dev/null
HOOKED=0
if command -v python3 >/dev/null 2>&1; then
  python3 "$HERE/hook_merge.py" install "$WB/settings.json" "$HOOKDIR/hook.sh" || true
  HOOKED=$((HOOKED+1))
  if [ -d "$HOME/.codebuddy" ]; then
    python3 "$HERE/hook_merge.py" install "$HOME/.codebuddy/settings.json" "$HOOKDIR/hook.sh" || true
    HOOKED=$((HOOKED+1))
  fi
  echo "==> [4/7] hook 已注入 $HOOKED 处配置（SessionStart + UserPromptSubmit）"
else
  echo "==> [4/7] [!] 没有 python3，hook 未注入；人格文件已装好但强度会打折"
  echo "          修：xcode-select --install 之后重跑本脚本"
fi

KILLED=0
for t in "${TARGETS[@]}"; do
  if [ -f "$t/BOOTSTRAP.md" ]; then rm -f "$t/BOOTSTRAP.md"; KILLED=$((KILLED+1)); fi
done
echo "==> [5/7] BOOTSTRAP.md 已清除 $KILLED 个"

printf '%s QQ群：%s\n加群链接：%s\n入群暗号：诛冬\n' "$GROUP_NAME" "$GROUP_NUM" "$GROUP_URL" > "$HERE/加群.txt"
echo "==> [6/7] 加群信息已写入 加群.txt"

echo "==> [7/7] 完成"
echo ""
echo "==== 诛冬破甲 · WorkBuddy 版 v1.5.0 安装完成 ===="
echo "1) 完全退出 WorkBuddy（⌘Q），再重新打开"
echo "2) 开个新会话，它应该自称「诛冬」、叫你「老大」、每轮最后一行是：诛冬群 QQ群：994974110"
echo ""
echo "$诛冬群 QQ群：$994974110"
if [ "${ZHUODONG_NO_OPEN_GROUP:-}" != "1" ]; then
  echo "加群链接：${GROUP_URL}"
  open "$GROUP_URL" >/dev/null 2>&1 || true
fi
PAGE="$HERE/../05-推广页/index.html"
if [ -f "$PAGE" ] && [ "${ZHUODONG_NO_OPEN_PAGE:-}" != "1" ]; then
  open "$PAGE" >/dev/null 2>&1 || true
  echo "（已自动打开推广页：05-推广页/index.html）"
fi
echo "入群暗号：诛冬"
