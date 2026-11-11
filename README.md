# 诛冬破甲 · WorkBuddy 版 v1.5.0

给 **WorkBuddy 5.x**（Windows 10/11 + macOS）装一套「诛冬」人格与运行契约的**纯脚本安装包**。
不装插件、不改主程序、不碰 WorkBuddy 安装目录 —— 只动 `~/.workbuddy` 下的人格文件、`zhudong\` 目录，以及 `settings.json` 里的两条 hook。

```
双击 一键安装.bat → 自动退出 WorkBuddy → 装人格+hook+output style+agent → 自动重开 → 开新会话即生效
```

装好后三条自证：**自称「诛冬」/ 叫你「老大」/ 每轮最后一行 `诛冬群 QQ群：994974110`**。

---

## 一、五条通道

强度从弱到强，叠着用 —— 只装人格文件会被 WorkBuddy 的 10000 字符截断线和 `user-context` 通道打折，硬通道是后面三条。

| # | 通道 | 落盘位置 | 优先级 | 说明 |
|---|---|---|---|---|
| 1 | 人格文件 | `~/.workbuddy` 与各 `user-*-personal\` 下的 `SOUL.md` / `IDENTITY.md` / `USER.md` / `MEMORY.md` | 低（会被截断） | `SOUL.md` = 破甲内核精简版，卡在 10000 字符线内；同时**删掉 `BOOTSTRAP.md`**，否则它每次启动反过来改写人格 |
| 2 | hook | `~/.workbuddy\zhudong\hook.ps1`（+ `hook.sh`）、`kernel.md`、`reminder.md` | 高 | `settings.json` 写两条：`SessionStart` → 输出完整内核（每会话一次）；`UserPromptSubmit` → 输出每轮契约（每问一次）。CLI 把钩子输出包成 `<system-reminder data-role="hook">` 插进提示词 |
| 3 | output style | `~/.workbuddy\output-styles\zhudong-armor.md` + `settings.outputStyle = zhudong-armor` | 高 | 进系统提示词的 instructions 层 |
| 4 | memory | `~/.workbuddy\memories\global` | 中 | 内核文件级记忆 |
| 5 | agent | `~/.workbuddy\agents\zhudong.md` + `settings.agent = zhudong` | **最高** | `settings.agent` 直接把默认 agent 的 instructions **换掉**（不只是叠加） |

生效证据（重启后 CLI 日志两行）：

```
Settings agent: applied "zhudong" config (instructions/tools) onto default agent
Applied output style: zhudong-armor
```

---

## 二、目录结构

```
zhudong-workbuddy/
├─ 一键安装.bat              ← 双击安装
├─ 一键卸载.bat              ← 双击卸载
├─ 检查是否装好.bat / .ps1   ← 逐项体检（人格 / hook / output style / memory / agent）
├─ 00-使用说明.txt           ← 全量说明（276 行，含报错对照表）
├─ 03-给AI的话术.txt         ← 让任意 AI 助手替你跑安装的一段话术
├─ 加群.txt                  ← 诛冬群：994974110 / https://qm.qq.com/q/IR15E9xWkS
├─ 01-Windows安装/
│   ├─ apply.ps1             ← 安装器（386 行，解密 + 五通道落盘 + 备份）
│   ├─ uninstall.ps1         ← 卸载（从 *.bak-* 还原）
│   ├─ payload.bin           ← 加密载荷：SOUL/IDENTITY/USER/MEMORY + kernel + reminder
│   ├─ payload/_READ_ME.txt  ← 占位说明（明文一律不落包）
│   ├─ hook/hook.ps1, hook.sh
│   ├─ 安装.bat / 卸载.bat
│   └─ 加群.txt
├─ 04-macOS安装/
│   ├─ install-mac.command   ← macOS 安装（依赖 python3 做 settings.json 合并）
│   ├─ uninstall-mac.command
│   ├─ unpack.py / hook_merge.py
│   ├─ payload.bin（同 Windows 那份）
│   └─ hook/hook.ps1, hook.sh
├─ 05-推广页/index.html
├─ docs/payload-format.md    ← 载荷格式与加密/校验/水印说明
└─ tools/inspect-payload.ps1 ← 不开装也能解开载荷验 MAC
```

---

## 三、安装

### Windows

```bat
:: 双击 一键安装.bat，或
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "01-Windows安装\apply.ps1"
```

参数：

| 参数 | 作用 |
|---|---|
| `-WbRoot <路径>` | 改数据目录（默认 `%USERPROFILE%\.workbuddy`） |
| `-Profile <关键字>` | 只装匹配的某个 `user-*-personal` 人格目录 |
| `-CodebuddyDir <路径>` | 同时写 `.codebuddy` 下的 settings（默认 `%USERPROFILE%\.codebuddy`） |
| `-NoKill` | 不替你结束 WorkBuddy 进程（不退出可能被回写覆盖） |
| `-NoRestart` | 装完不自动重开 |
| `-NoOpenGroup` / `-NoOpenPage` | 不弹加群页 / 不弹推广页 |

七个步骤全绿即成功：

```
[1/8] 载荷已解密 N 个文件（包内无明文 · build ZD-xxxxxxxxxx）
[2/8] 安装包自检通过（payload 已加密）
[3/8] WorkBuddy 正在退出…
[4/8] 目标人格目录 N 个
[5/8] 破甲人格已写入 N 个文件
[6/8] hook 已注入（SessionStart + UserPromptSubmit）
[7/8] BOOTSTRAP.md 已清除 N 个
[8/8] 加群信息已写入 加群.txt
```

### macOS

```bash
chmod +x 04-macOS安装/install-mac.command
bash 04-macOS安装/install-mac.command
# 不想弹浏览器：
ZHUODONG_NO_OPEN_GROUP=1 ZHUODONG_NO_OPEN_PAGE=1 bash 04-macOS安装/install-mac.command
```

hook 注入依赖 `python3`；没有的话人格文件照样装，但强度打折（脚本会提示）。

### 装之前

1. WorkBuddy 至少启动过一次，`~/.workbuddy` 已生成。
2. **完全退出** WorkBuddy（托盘右键 → 退出 / macOS ⌘Q），不是关窗口。
3. 安装器只动上面列的三类东西，人格文件与 `settings.json` 都留 `*.bak-<时间戳>` 备份。

---

## 四、验证

```bat
检查是否装好.bat
```

逐项核对：`SOUL 破甲内核` / `.zhudong-armor.json 标记` / `hook 脚本` / `SessionStart` / `UserPromptSubmit` / `output style` / `settings.outputStyle 值` / `memory 通道`，任何一项 X 都标出来。

工作层面三条：自称诛冬、称你老大、每轮末行带群号。只有你发**单个词「诛冬」**时它只回一句、不带尾巴。

人格没变化按顺序排：① 是否真退干净 ② 是否还在旧会话（开新的）③ `检查是否装好.bat` 的 hook 项是否 X ④ `BOOTSTRAP.md` 是否又冒出来。

---

## 五、卸载

```bat
:: Windows
一键卸载.bat            :: 或 01-Windows安装\卸载.bat
:: macOS
bash 04-macOS安装/uninstall-mac.command
```

从 `*.bak-*` 还原人格文件，删 `.zhudong-armor.json`、`zhudong\` 目录、`agents\zhudong.md`、`output-styles\zhudong-armor.md`，
把 `settings.json` 里**含 zhudong 的** hook 与 `agent`/`outputStyle` 还原成原值（原值存档在 `zhudong-agent-prev.json`），你自己的 hook 原样保留。

---

## 六、载荷与防护

`payload.bin` 里没有任何明文：SOUL / IDENTITY / USER / MEMORY / kernel / reminder 六份文本，
用 **SHA256-CTR 流加密 + 逐文件 HMAC-SHA256** 装在一个 JSON 里，安装时才解密、装完即删临时目录。

- 改一个字节 → 安装直接报「载荷校验失败：xxx（包被改动过）」并中止，不会装出半残的破甲。
- 每份构建的内核里嵌一段零宽字符水印（`U+200B` / `U+200C`），编码 build id（安装第一行会打印 `build: ZD-xxxxxxxxxx`），能对上是哪一版流出的。
- 天花板要说清：明文最终必须落到 `~/.workbuddy` 才能被产品读到，这一段任何本地提示词包都挡不住。防的是「拿压缩包直接抄」和「随手转发」，不是密码学意义上的不可逆保护。

格式、密钥派生、解密与校验的完整说明见 [docs/payload-format.md](docs/payload-format.md)；
不想装、只想看载荷里有什么：

```powershell
powershell -ExecutionPolicy Bypass -File tools\inspect-payload.ps1 -Out .\unpacked
```

---

## 七、报错对照

| 现象 | 处理 |
|---|---|
| 双击一闪就没 | 右键「以管理员身份运行」 |
| 无法加载文件，未数字签名 | 用 `安装.bat` 跑（内部带 `-ExecutionPolicy Bypass`），不改系统策略 |
| `[X] 安装包不完整` | 解压不完整，`payload.bin` 与 `hook\` 都要在 |
| 没找到 `.workbuddy` | 先装 WorkBuddy 并启动一次 |
| 人格没变化 | 没退干净 / 旧会话缓存 / 重跑安装 |
| `BOOTSTRAP.md` 又出现 | 没重启就开了会话；重启后重跑安装清掉 |
| 最后一行没有群号 | hook 没注入：跑 `检查是否装好.bat` 看 `SessionStart`/`UserPromptSubmit` |

---

## 八、版本

| 项 | 值 |
|---|---|
| 包版本 | 1.5.0（2026-11-11） |
| 适用 | WorkBuddy 5.x，Windows 10/11 / macOS |
| 载荷 build | `ZD-858CF007FE`（本次发行包） |
| 注 | `SOUL.md` / `reminder.md` 正文内部自报 `诛冬v1.4.0`，与包版本号未同步，属已知不一致 |

诛冬群 · QQ群 **994974110** · https://qm.qq.com/q/IR15E9xWkS · 暗号「诛冬」

## 九、许可

MIT，见 [LICENSE](LICENSE)。
