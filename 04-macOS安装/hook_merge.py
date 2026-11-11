# -*- coding: utf-8 -*-
"""WorkBuddy hook 合并器（macOS 用）：安装 / 卸载 SessionStart + UserPromptSubmit 钩子。

用法：
  python3 hook_merge.py install <settings.json> <hook.sh 绝对路径>
  python3 hook_merge.py remove  <settings.json>
"""
import json
import os
import sys
import time


def load(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return {}
    except Exception:
        return {}


def strip(entries):
    out = []
    for e in entries or []:
        cmds = " ".join((h or {}).get("command", "") for h in (e or {}).get("hooks", []) or [])
        if "zhudong" in cmds:
            continue
        out.append(e)
    return out


def main():
    if len(sys.argv) < 3:
        print("用法: hook_merge.py install|remove <settings.json> [hook.sh]")
        return 2
    mode, path = sys.argv[1], sys.argv[2]
    cfg = load(path)
    hooks = cfg.get("hooks") or {}
    for ev in ("SessionStart", "UserPromptSubmit"):
        hooks[ev] = strip(hooks.get(ev))
    if mode == "install":
        if len(sys.argv) < 4:
            print("缺 hook.sh 路径")
            return 2
        hook = sys.argv[3]
        hooks["SessionStart"].append({
            "matcher": "",
            "hooks": [{"type": "command", "command": 'bash "%s" start' % hook, "timeout": 15}],
        })
        hooks["UserPromptSubmit"].append({
            "matcher": "",
            "hooks": [{"type": "command", "command": 'bash "%s" submit' % hook, "timeout": 15}],
        })
    cfg["hooks"] = hooks
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    if os.path.exists(path) and not os.path.exists(path + ".bak-zhudong"):
        import shutil
        shutil.copyfile(path, path + ".bak-zhudong")
    with open(path, "w", encoding="utf-8") as f:
        f.write(json.dumps(cfg, ensure_ascii=False, indent=2) + "\n")
    print("  hooks %s -> %s" % (mode, path))
    return 0


if __name__ == "__main__":
    sys.exit(main())
