#!/usr/bin/env python3
"""让 `flutter build ios --no-codesign` 能真正通过，并保证失败时能看到真实错误。

背景（Flutter 3.47.9 源码 packages/flutter_tools/lib/src/ios/mac.dart）：
  _missingDevelopmentTeam() 只检查 `xcodebuild -showBuildSettings` 的输出里
  有没有 DEVELOPMENT_TEAM / PROVISIONING_PROFILE 这两个【键】。
  一旦缺失，xcodebuild 失败时 Flutter 就只打印「Building a deployable iOS app
  requires a selected Development Team ...」这条兜底提示，并把真实的 Xcode
  错误（stdout/stderr）吞掉，导致完全无法定位。
所以本脚本做两件事：
  1) CODE_SIGN_STYLE = Automatic → Manual，并关掉签名开关；
  2) 保证工程里存在 DEVELOPMENT_TEAM 键（空值即可，配合 --no-codesign 不会真签名）。

幂等：重复执行不会重复注入。旧版 Capacitor 工程的同名脚本已跑通 3 次。

用法：python3 scripts/disable-signing.py ios/Runner.xcodeproj/project.pbxproj
"""
import pathlib
import re
import sys


def main():
    if len(sys.argv) < 2:
        print('用法：python3 disable-signing.py <project.pbxproj 路径>', file=sys.stderr)
        sys.exit(1)
    path = pathlib.Path(sys.argv[1])
    text = path.read_text(encoding='utf-8')

    # 1) 自动签名 → 手动；并在同一 buildSettings 块追加两道无签名开关
    style_re = re.compile(r'CODE_SIGN_STYLE\s*=\s*Automatic\s*;')
    addon = ('CODE_SIGN_STYLE = Manual;\n'
             '\t\t\t\tCODE_SIGNING_ALLOWED = NO;\n'
             '\t\t\t\tCODE_SIGNING_REQUIRED = NO;')
    text, n_style = style_re.subn(addon, text)

    # 2) 清空可能触发 Xcode 找 profile 的设置
    rules = [
        (r'DEVELOPMENT_TEAM\s*=\s*[^;]+;', 'DEVELOPMENT_TEAM = "";'),
        (r'"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]"\s*=\s*[^;]+;',
         '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "-";'),
        (r'CODE_SIGN_IDENTITY\s*=\s*[^;]+;', 'CODE_SIGN_IDENTITY = "";'),
        (r'PROVISIONING_PROFILE_SPECIFIER\s*=\s*[^;]+;',
         'PROVISIONING_PROFILE_SPECIFIER = "";'),
    ]
    counts = []
    for pattern, replacement in rules:
        text, n = re.subn(pattern, replacement, text)
        counts.append((pattern, n))

    # 3) 关键：补一个 DEVELOPMENT_TEAM 键，消除 Flutter 的误判并让真实错误可见
    if 'DEVELOPMENT_TEAM' not in text:
        manual_re = re.compile(r'(CODE_SIGN_STYLE\s*=\s*Manual\s*;)')

        def _add_team(m):
            return m.group(1) + '\n\t\t\t\tDEVELOPMENT_TEAM = "";'

        text, n_team = manual_re.subn(_add_team, text)
    else:
        n_team = 0

    path.write_text(text, encoding='utf-8')

    print('已关闭工程自动签名：%s' % path)
    print('  CODE_SIGN_STYLE Automatic→Manual + 注入无签名开关: %d 处' % n_style)
    for pattern, n in counts:
        print('  %-52s %d 处' % (pattern, n))
    print('  注入 DEVELOPMENT_TEAM 键: %d 处（0 表示工程里原本已有）' % n_team)
    if n_style == 0:
        print('  （工程已是 Manual，本次仅做幂等校验）')


if __name__ == '__main__':
    main()
