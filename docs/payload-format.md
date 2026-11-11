# payload.bin 格式 · 加解密与校验

`01-Windows安装/payload.bin` 与 `04-macOS安装/payload.bin` 是同一份（SHA256 相同），
结构是一个 JSON 文本：

```json
{
  "v": 1,
  "build": "ZD-858CF007FE",
  "salt": "wvZFWHvSwXapKSLp/+v+aQ==",
  "files": {
    "payload/SOUL.md":      "<base64 密文>",
    "payload/IDENTITY.md":  "...",
    "payload/USER.md":      "...",
    "payload/MEMORY.md":    "...",
    "hook/kernel.md":       "...",
    "hook/reminder.md":     "..."
  },
  "fileMac": { "payload/SOUL.md": "<hmac hex>", ... }
}
```

## 1. 密钥派生

安装器里三段 base64 常量，各自**字节反转**后按序拼接，得到 ASCII 主密钥：

```powershell
$ZD_K1 = 'Vk5GdWNrL0pLTmg='   # reversed -> RNkJ/cuFgNV
$ZD_K2 = 'R0J3eGkrbHNLVWE='   # reversed -> aUKsl+ixwBG
$ZD_K3 = 'MVhWU2dHdC81dw=='   # reversed -> w5/tGgSVX1
# 拼起来：hNKJ/kcuFNVaUKsl+ixwBGw5/tGgSVX1
```

真正用于加密的密钥 = `SHA256(secret_bytes || salt_bytes)`，长度 32 字节。
`salt` 每次构建可换。

## 2. 加密：SHA256 计数器流（CTR 构造）

对每个文件，密文 = 明文 XOR 密钥流：

```
for block = 0,1,2,...:
    seed      = key(32B) || int64_le(block)
    keystream = SHA256(seed)          # 32 字节
    plaintext ^= keystream            # 截断到密文长度
```

因为 `block` 用 `int64` 小端、从 0 起连续递增，所以同一个密钥 + 同一个文件必然复现同一串密钥流 —— 这是标准的 CTR 用法，等价于「用 SHA256 造一个无限长的流密码」。

## 3. 校验：逐文件 HMAC-SHA256

`fileMac.<路径>` 是 `HMACSHA256(key = 派生出的 32 字节密钥, data = 明文)` 的十六进制小写。
安装器先解出来，再算一遍，不等就 `throw "载荷校验失败：<路径>（包被改动过）"` 并整体中止 —— 所以包被改一个字节不会装出「半个破甲」。

注意 MAC 是对**明文**算的，解不出来就无法伪造 MAC 通过校验。

## 4. 水印

每份构建的内核里嵌了零宽字符（不可见、不影响模型行为），编码 build id：

- `U+200B`（ZERO WIDTH SPACE）
- `U+200C`（ZERO WIDTH NON-JOINER）

本发行包实测：`kernel.md` 里 `U+200B`×63、`U+200C`×41。
把内核抄出去传播，用配套 meta 能对上是哪一版流出的；按买家发不同水印只需重跑构建脚本。

## 5. 自己解开看

仓库自带 [tools/inspect-payload.ps1](../tools/inspect-payload.ps1)：解密 + 验 MAC + 落盘，不做任何安装动作。

```powershell
powershell -ExecutionPolicy Bypass -File tools\inspect-payload.ps1 -Out .\unpacked
```

输出形如：

```
secret = hNKJ/kcuFNVaUKsl+ixwBGw5/tGgSVX1
build  = ZD-858CF007FE
payload/SOUL.md        4559 bytes  MAC OK  sha256=1DC3B1C5D3E4B02D
payload/IDENTITY.md    1013 bytes  MAC OK  sha256=669104FCF2CBF7B0
payload/USER.md         899 bytes  MAC OK  sha256=8864B4E2AA0F6768
payload/MEMORY.md       770 bytes  MAC OK  sha256=DF09C5636FD5122D
hook/kernel.md        14975 bytes  MAC OK  sha256=B6C0E3337EEC0D32
hook/reminder.md       1327 bytes  MAC OK  sha256=CEAEE5874A246EBE
```

## 6. 边界（要说清的）

- 主密钥随安装器一起发，只是拆开、反转、分段存放 —— 提高门槛，不是不可逆的密码学保护。
- 装机后明文必须落到 `~/.workbuddy` 才能被产品读取，这一段任何本地提示词包都挡不住。
- 真要按台数 / 有效期控制，只能上服务端校验；本包不做，也不建议在本地硬做。
