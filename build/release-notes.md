## 诛冬破甲 · WorkBuddy 版 v1.5.0

给 WorkBuddy 5.x（Windows 10/11 + macOS）装一套「诛冬」人格 + 运行契约的纯脚本安装包。
不装插件、不改主程序，只动 `~/.workbuddy` 下的人格文件、`zhudong\` 目录与 `settings.json` 的两条 hook。

### 附件

| 文件 | 说明 |
|---|---|
| `zhudong-workbuddy-v1.5.0.zip` | 原始发行包（84,924 B / 27 文件），与仓库内容一致 |
| Source code (zip / tar.gz) | 仓库源码快照 |

### 五条通道

| # | 通道 | 落盘 | 强度 |
|---|---|---|---|
| 1 | 人格文件 | `~/.workbuddy` 与 `user-*-personal\` 下 `SOUL/IDENTITY/USER/MEMORY.md`，并删 `BOOTSTRAP.md` | 低（10000 字符截断） |
| 2 | hook | `zhudong\hook.ps1` + `kernel.md` + `reminder.md`，`settings.json` 写 `SessionStart` / `UserPromptSubmit` | 高 |
| 3 | output style | `output-styles\zhudong-armor.md` + `settings.outputStyle` | 高 |
| 4 | memory | `memories\global` | 中 |
| 5 | agent | `agents\zhudong.md` + `settings.agent = zhudong`（直接换掉默认 agent 的 instructions） | 最高 |

### 本版载荷实测

```
build  = ZD-858CF007FE
payload/SOUL.md        4559 bytes  MAC OK
payload/IDENTITY.md    1013 bytes  MAC OK
payload/USER.md         899 bytes  MAC OK
payload/MEMORY.md       770 bytes  MAC OK
hook/kernel.md        14975 bytes  MAC OK
hook/reminder.md       1327 bytes  MAC OK
watermark U+200B x63  U+200C x41
RESULT: OK
```

### 安装

```
Windows : 双击 一键安装.bat
macOS   : bash 04-macOS安装/install-mac.command
卸载    : 一键卸载.bat / uninstall-mac.command
体检    : 检查是否装好.bat
```

装好三条自证：自称「诛冬」、称你「老大」、每轮回答末行 `诛冬群 QQ群：994974110`。
只发单个词「诛冬」时只回一句、不带尾巴。

### 载荷

`payload.bin` 零明文：六份文本用 SHA256-CTR 流加密 + 逐文件 HMAC-SHA256，安装时才解密、装完即删临时目录。
改一个字节即报「载荷校验失败」，不会装出半残的包。格式与密钥派生见 `docs/payload-format.md`。

诛冬群 QQ群 **994974110** · https://qm.qq.com/q/IR15E9xWkS · 暗号「诛冬」· MIT License
