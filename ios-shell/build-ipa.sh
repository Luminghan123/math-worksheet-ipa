#!/usr/bin/env bash
# 在 macOS 上把 Capacitor 工程归档并导出为 .ipa
# 前置：npm install && npx cap add ios && npx cap sync ios
#       并在 Xcode 中完成一次 Signing 配置（Team / Bundle ID）
set -euo pipefail

SCHEME="App"
WORKSPACE="ios/App/App.xcworkspace"
ARCHIVE="./build/App.xcarchive"
EXPORT_PLIST="./ExportOptions.plist"
OUT="./build/ipa"

if [[ ! -d "$WORKSPACE" ]]; then
  echo "未找到 $WORKSPACE，请先执行：npx cap add ios && npx cap sync ios" >&2
  exit 1
fi

if grep -q "YOUR_TEAM_ID" "$EXPORT_PLIST"; then
  echo "请先把 ExportOptions.plist 里的 YOUR_TEAM_ID 改成你的 Apple Developer Team ID" >&2
  exit 1
fi

mkdir -p ./build

echo "==> 1/2 归档 Archive"
xcodebuild -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE" \
  clean archive

echo "==> 2/2 导出 ipa"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -exportPath "$OUT"

echo "==> 完成，ipa 输出目录：$OUT"
ls -lh "$OUT"
