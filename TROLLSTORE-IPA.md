# 口算题卡 · 未签名 IPA 构建与安装（Flutter 版）

本 App 用 **Flutter** 重写，PDF 保存逻辑照搬参考软件
（呼吸治疗记录 iOS 云构建包 V1.1）的 `Printing.sharePdf(bytes:...)`：
PDF 在内存里生成 → 直接交给 iOS 系统分享面板 → 用户选「存储到文件」自己决定存哪。
**App 不写文档目录、不在「文件」App 里新建任何文件夹。**

---

## 一、安装前提

| 项 | 要求 |
|---|---|
| 设备 | iPhone / iPad，**已装 TrollStore（巨魔助手 / TrollStore）** |
| 系统 | **iOS 15.0 或更高**（Flutter 3.47 的最低部署目标；参考软件同） |
| 巨魔支持范围 | iOS 14.0–16.6.1 / 16.7 RC / 17.0；17.0.1+ 巨魔不可用 |
| 证书 | **不需要** Apple Developer 账号、证书、描述文件 |
| ldid | 手机 TrollStore → Settings → Install ldid（装不上 ipa 时先做这步） |

> 未签名 / ad-hoc 签名的 ipa 主要给巨魔用；安卓 APK 可直接安装，iOS 无巨魔则需要
> 开发者证书或 TestFlight。本工程只做本地打包，不做上架与资质审核。

## 二、下载与安装

手机 Safari 打开下载页，点 IPA 下载，在「文件」App 里把 ipa 分享给 TrollStore 即可安装。

- **下载页**：https://github.com/Luminghan123/math-worksheet-ipa/releases/tag/ipa-latest
- **IPA 直链**：https://github.com/Luminghan123/math-worksheet-ipa/releases/download/ipa-latest/math-worksheet-unsigned.ipa
- **仓库 / Actions**：https://github.com/Luminghan123/math-worksheet-ipa/actions

装新版前**先删掉旧版**（旧 Capacitor 版与 Flutter 版 Bundle ID 不同，可并存，
但为避免混淆建议删旧留新）。

## 三、GitHub Actions 怎么出包

工作流：`.github/workflows/build-unsigned-ipa.yml`

| 步骤 | 说明 |
|---|---|
| 构建机 | `macos-15`（GitHub 提供，公开仓库免费） |
| Flutter | `subosito/flutter-action@v2` 固定 `3.47.9`（与参考软件一致，避免版本漂移） |
| 依赖 | `flutter config --enable-swift-package-manager` → `flutter pub get` → 按需 `pod install` |
| 自检 | `dart run tool/verify_engine.dart` 出题回归 + `dart run tool/gen_sample_pdf.dart` 真实生成 A4 PDF |
| 关闭签名 | `python3 scripts/disable-signing.py`（见下方说明） |
| 编译 | `flutter build ios --release --no-codesign --no-pub -v` |
| 打包 | `Runner.app` 拷进 `Payload/` → 清 `._*` / `.DS_Store` / `xattr -cr` → `codesign -f -s - --deep` 补 ad-hoc 签名 → `zip -qrXy` |
| 校验 | 检查 `Payload/Runner.app/Info.plist` 与 `Runner` 存在、不含 `__MACOSX` |
| 发布 | 上传 Artifact；用 `gh release` 更新固定标签 `ipa-latest`（手机 Safari 可直接下载） |

> 与旧版 Capacitor 工作流的差别：改用 `flutter build ios --no-codesign` 直接产出 `Runner.app`，
> 不再需要 `xcodebuild archive`。但**保留了** `scripts/disable-signing.py`：它把工程改成
> `CODE_SIGN_STYLE = Manual` + 无签名开关，并注入一个空的 `DEVELOPMENT_TEAM` 键。
> 原因是 Flutter 3.47 在编译失败时若发现工程缺这个键，会**吞掉真实的 Xcode / Dart 错误**，
> 只打印误导性的 `requires a selected Development Team`。补上这个键后，真实错误才会显形
> （再配合编译 `-v` 与「静态检查 Dart 代码」步骤，一次就能定位）。
> `Info.plist` 里 **不含** `UIFileSharingEnabled` / `LSSupportsOpeningDocumentsInPlace`，
> 这是「不建文件夹」的关键。

触发方式：

- 推送到任意分支且改动命中 `lib/**`、`pubspec.yaml`、`assets/**`、`ios/**`、`scripts/**`、`tool/**`、workflow 文件 → 自动构建
- 或到 Actions 页手动 **Run workflow**

## 四、自己在 Mac 上打包（可选）

```bash
cd math-worksheet-flutter
flutter pub get
flutter config --enable-swift-package-manager
python3 scripts/disable-signing.py ios/Runner.xcodeproj/project.pbxproj
flutter build ios --release --no-codesign --no-pub

APP=build/ios/iphoneos/Runner.app
rm -rf Payload math-worksheet-unsigned.ipa && mkdir Payload && cp -R "$APP" Payload/
xattr -cr Payload; find Payload -name '._*' -delete; find Payload -name '.DS_Store' -delete
codesign -f -s - --deep Payload/Runner.app
zip -qrXy math-worksheet-unsigned.ipa Payload
```

## 五、常见失败排查

| 现象 | 处理 |
|---|---|
| `requires a selected Development Team` | **这不是真正原因**，是 Flutter 在编译失败后的兜底提示。真实错误通常是 Dart 代码报错（类型不匹配、组件与 material 重名等）被它盖住了。看 workflow 里「静态检查 Dart 代码」和「打印编译失败详情」两步的输出，或本地跑 `flutter build ios -v`。工程已注入 `DEVELOPMENT_TEAM` 键消除误判 |
| `No profiles ... were found` | 确认用了 `--no-codesign`；本流程不需要证书 |
| `pod install` 失败 | 看 CocoaPods 版本；工作流已做「有 Podfile 才装」的兜底 |
| `macos-15` 被弃用 / 找不到 Xcode | 把 `runs-on` 改成 `macos-latest` |
| 找不到 `Runner.app` | 往上翻日志看 `flutter build ios` 的编译错误 |
| 「校验 IPA 结构」报混入 `__MACOSX` | `zip` 漏了 `-X`，或 `.app` 里有 `._*`；确认清理步骤执行了 |
| 手机上 TrollStore 安装报错 | 多半 **ldid 没装** → TrollStore → Settings → Install ldid；其次看 IPA 是否混入 macOS 元数据 |
| 安装后闪退 | 确认系统 ≥ iOS 15.0；确认 `IPHONEOS_DEPLOYMENT_TARGET = 15.0` 不高于系统 |
| 爱思助手 / Filza 认不出 ipa | 正常，未签名 ipa 主要给巨魔用；已补 ad-hoc 签名提升兼容性 |
| 分享面板里找不到「存储到文件」 | 在系统分享面板里上滑或点「更多」 |

## 六、保存逻辑边界

- 只提供**一个**保存出口：设置页「生成并分享 / 保存 PDF」（预览页右上「保存」是同一函数）
- PDF 由 `pdf` 包 + 内嵌中文字体在内存里生成，交给 `Printing.sharePdf`
- 系统分享面板负责中转临时文件，**App 不主动写任何目录**，用完不留痕
- 已分享保存出去的文件与 App 本机历史互不影响；清空历史不会删那些文件

---

## 七、当前构建结果

`run #10` 全部 18 步 **success**，已发布到 `ipa-latest`。本地校验结论：

| 校验项 | 结果 |
|---|---|
| 体积 | 7360.7 KB |
| `Payload/Runner.app/Info.plist`、`Runner`（arm64 Mach-O） | 存在 |
| `Flutter.framework` / `App.framework` | 47 个条目 |
| 显示名 / Bundle ID / 最低系统 | 口算题卡 / com.workbuddy.mathworksheet / iOS 15.0 |
| `UIFileSharingEnabled`、`LSSupportsOpeningDocumentsInPlace` | 均不存在（不建文件夹） |
| 内嵌中文字体 `WorksheetCJK.ttf` | 已在 `flutter_assets` 内 |
| 混入 `__MACOSX` / `._*` | 无 |
