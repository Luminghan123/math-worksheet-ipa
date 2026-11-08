#!/usr/bin/env bash
# 在 Mac 本地构建「未签名」IPA，流程与 GitHub Actions 完全一致。
# 用于排查 CI 问题，或没有 GitHub 时自行出包。不需要 Apple 开发者账号。
set -euo pipefail
cd "$(dirname "$0")"

echo "==> 1/6 安装 npm 依赖"
npm install --no-audit --no-fund

echo "==> 2/6 生成 Capacitor iOS 工程"
npx cap add ios 2>/dev/null || true
npx cap sync ios

echo "==> 3/6 安装 CocoaPods 依赖"
(cd ios/App && pod install)

echo "==> 4/6 关闭自动签名"
python3 scripts/disable-signing.py ios/App/App.xcodeproj/project.pbxproj

echo "==> 5/6 构建未签名 archive"
xcodebuild clean archive \
  -workspace ios/App/App.xcworkspace \
  -scheme App \
  -configuration Release \
  -archivePath build/App.xcarchive \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  ONLY_ACTIVE_ARCH=NO \
  IPHONEOS_DEPLOYMENT_TARGET=14.0 \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

echo "==> 6/6 打包成 IPA（与 CI 一致：清元数据 + ad-hoc 签名 + 结构校验）"
APP=$(find build/App.xcarchive/Products/Applications -maxdepth 1 -name '*.app' -print -quit)
if [ -z "$APP" ] || [ ! -d "$APP" ]; then echo "未找到 .app，构建失败" >&2; exit 1; fi
echo "使用 App: $APP"
codesign -dv "$APP" 2>&1 | head -n 3 || true
rm -rf Payload math-worksheet-unsigned.ipa && mkdir Payload
cp -R "$APP" Payload/

# 清掉 macOS 元数据：TrollStore 解析 IPA 时遇到 ._ 开头的 AppleDouble 文件会报错
xattr -cr Payload 2>/dev/null || true
find Payload -name '._*' -delete 2>/dev/null || true
find Payload -name '.DS_Store' -delete 2>/dev/null || true

# 补一层 ad-hoc 签名，让爱思助手 / Filza 等安装器也能识别
APPNAME=$(basename "$APP")
codesign -f -s - --deep "Payload/$APPNAME" 2>/dev/null \
  || echo "ad-hoc 签名跳过（TrollStore 仍可正常安装）"

# -y 保留符号链接（framework 需要），-X 不写扩展属性（避免生成 __MACOSX）
zip -qrXy math-worksheet-unsigned.ipa Payload
unzip -l math-worksheet-unsigned.ipa | grep -q 'Payload/.*\.app/Info.plist'
if unzip -l math-worksheet-unsigned.ipa | grep -q '__MACOSX'; then
  echo "IPA 里混入了 macOS 元数据，打包失败" >&2; exit 1
fi
echo "IPA 结构校验通过"
rm -rf Payload

echo "==> 完成：$(pwd)/math-worksheet-unsigned.ipa"
