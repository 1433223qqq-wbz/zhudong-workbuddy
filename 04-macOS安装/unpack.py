# -*- coding: utf-8 -*-
"""解 payload.bin（SHA256-CTR + 逐文件 HMAC）。用法：python3 unpack.py <payload.bin> <输出目录>"""
import base64
import hashlib
import hmac
import json
import os
import sys

K = ["Vk5GdWNrL0pLTmg=", "R0J3eGkrbHNLVWE=", "MVhWU2dHdC81dw=="]

def main():
    if len(sys.argv) < 3:
        print("用法: unpack.py <payload.bin> <outdir>")
        return 2
    blob = json.load(open(sys.argv[1], encoding="utf-8"))
    outdir = sys.argv[2]
    secret = "".join(base64.b64decode(k)[::-1].decode() for k in K)
    key = hashlib.sha256(secret.encode() + base64.b64decode(blob["salt"])).digest()

    def stream(n):
        buf, i = b"", 0
        while len(buf) < n:
            buf += hashlib.sha256(key + i.to_bytes(8, "little")).digest()
            i += 1
        return buf[:n]

    for name, b64 in blob["files"].items():
        cipher = base64.b64decode(b64)
        plain = bytes(a ^ b for a, b in zip(cipher, stream(len(cipher))))
        if blob.get("fileMac", {}).get(name) != hmac.new(key, plain, hashlib.sha256).hexdigest():
            print("载荷校验失败:", name)
            return 3
        path = os.path.join(outdir, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, "wb").write(plain)
    print("解密完成:", len(blob["files"]), "个文件")
    return 0

if __name__ == "__main__":
    sys.exit(main())
