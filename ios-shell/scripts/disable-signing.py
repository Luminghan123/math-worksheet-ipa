#!/usr/bin/env python3
"""把 Capacitor 生成的 Xcode 工程改成「不签名」，供未签名 IPA 构建使用。

用法：python3 disable-signing.py ios/App/App.xcodeproj/project.pbxproj
"""
import re
import sys


def main():
    if len(sys.argv) < 2:
        print("用法：python3 disable-signing.py <project.pbxproj 路径>", file=sys.stderr)
        sys.exit(1)
    path = sys.argv[1]
    with open(path, encoding="utf-8") as f:
        text = f.read()

    rules = [
        (r"CODE_SIGN_STYLE\s*=\s*Automatic\s*;", "CODE_SIGN_STYLE = Manual;"),
        (r"DEVELOPMENT_TEAM\s*=\s*[^;]+;", 'DEVELOPMENT_TEAM = "";'),
        (r"CODE_SIGN_IDENTITY\s*=\s*[^;]+;", 'CODE_SIGN_IDENTITY = "";'),
        (r"PROVISIONING_PROFILE_SPECIFIER\s*=\s*[^;]+;", 'PROVISIONING_PROFILE_SPECIFIER = "";'),
    ]
    for pattern, replacement in rules:
        text, count = re.subn(pattern, replacement, text)
        print(f"  {pattern} -> 替换 {count} 处")

    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"已关闭自动签名：{path}")
    print("（命令行仍会传入 CODE_SIGNING_ALLOWED=NO 作为最终保证）")


if __name__ == "__main__":
    main()
