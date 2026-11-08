# 用 GitHub Actions 制作巨魔（TrollStore）可安装的 ipa

巨魔利用 CoreTrust 漏洞给应用做**永久签名**，能安装**未签名**的 ipa。所以只要在 GitHub 的 macOS 云端构建机上关闭代码签名、把 `.app` 打成 ipa，就能直接装——**不需要 Apple 开发者账号、不需要证书、不需要 Mac、不需要 7 天重签**。

本目录已经配好整套自动化：push 到 GitHub 后，Actions 自动出包并发布到 Releases。

---

## 一、先确认你的手机能装

| 检查项 | 要求 |
|---|---|
| iOS 版本 | **14.0–16.6.1、16.7 RC (20H18)、17.0**；**iOS 17.0.1 及以上不支持巨魔**，装了也没用 |
| TrollStore | 已安装并可使用 |
| ldid | **TrollStore → Settings → Install ldid 必须先装好**，未签名 ipa 靠它修补代码签名，缺了会安装失败 |
| 持久化助手 | 建议同时设置 Persistence Helper，重启后应用不失效 |

> 如果系统已经是 iOS 17.0.1+，巨魔这条路走不通，只能改走签名路线（见 README 第七节，需要 Mac + 开发者账号）。

## 二、准备 GitHub 仓库（一条命令）

> **为什么需要你自己推**：本会话连接的 GitHub 是**只读**集成，只能读账号和仓库，没有创建仓库、建分支、推送文件的权限（实测创建仓库与创建分支均返回 403）。所以这一步要在你自己已登录 GitHub 的电脑 / 环境里执行。文件已打包成 `math-worksheet-ipa-repo.zip`，下载解压即可。

1. 把**整个 `math-worksheet-app` 目录**作为仓库根目录（`.github/workflows/` 必须位于仓库根，不能放进子目录）。
2. 建议先把 `ios-shell/capacitor.config.json` 里的 `appId` 改成你自己的，例如 `com.zhangsan.mathworksheet`（避免和别的应用撞 ID）。
3. **推荐：GitHub CLI 一条命令**自动建仓库并推送（公开仓库的 macOS 构建机免费）：

```bash
cd math-worksheet-app
gh auth login                 # 仅首次需要，按提示在浏览器完成登录
gh repo create math-worksheet-ipa --public --source=. --remote=origin --push
```

4. **没装 `gh` 时**：先到 https://github.com/new 建一个**空的 Public 仓库**（**不要**勾选 README / .gitignore / license），再执行：

```bash
cd math-worksheet-app
git init
git add .
git commit -m "口算题卡 APP + 未签名 IPA 自动构建"
git branch -M main
git remote add origin https://github.com/Luminghan123/math-worksheet-ipa.git
git push -u origin main
```

> `.gitignore` 已排除 `node_modules/`、`ios/`、`build/`、`*.ipa`，这些由 CI 自己生成，不要提交。但 `ios-shell/www/index.html`（APP 本体）必须提交。
>
> 推送后 workflow 会自动触发（`on.push` 监听所有分支，且只在 `index.html`、`ios-shell/**`、workflow 文件变更时构建，改文档不会白跑一次构建）。

## 三、触发构建、拿到 ipa

1. push 后，仓库 **Actions** 页会自动跑「构建未签名 IPA（TrollStore 巨魔）」；也可手动点 **Run workflow**。
2. 大约 10–20 分钟跑完（首次要装 CocoaPods，会慢一些）。
3. 成功后有两个下载入口：
   - **Releases** 里固定标签 `ipa-latest`，附件 `math-worksheet-unsigned.ipa`（推荐，手机 Safari 可直接下载）
   - Actions 本次运行的 **Artifacts** 里 `math-worksheet-unsigned-ipa`（保留 30 天）

## 四、装到手机

1. 手机 Safari 打开仓库的 Releases 页面，下载 `math-worksheet-unsigned.ipa`。
2. 下载完成后，在「文件」App 里找到这个 ipa → **长按 → 共享 → TrollStore**。
3. TrollStore 打开后点安装，桌面出现「口算题卡」，完成。

也可以把 ipa 通过任意方式（AirDrop、微信文件传输等）存到手机，再长按分享给 TrollStore。

---

## 五、这套自动化做了什么

| 步骤 | 动作 |
|---|---|
| 环境 | `macos-15` 云端构建机（用 runner 自带 Xcode，不再固定版本）+ Node 20 |
| 工程 | `npm install` → `npx cap add ios` → `npx cap sync ios` → `pod install` |
| 去签名 | `scripts/disable-signing.py` 把 `project.pbxproj` 改成 Manual 签名、清空 Team / Identity / Profile |
| 构建 | `xcodebuild archive` 带 `CODE_SIGNING_ALLOWED=NO`、`CODE_SIGNING_REQUIRED=NO`、`CODE_SIGN_IDENTITY=""`，最低系统 iOS 14.0 |
| 打包 | `*.app` 拷进 `Payload/` → 清除 `._*` / `.DS_Store` 等 macOS 元数据 → 补一层 ad-hoc 签名 → `zip -qrXy` 成 ipa |
| 校验 | 检查 `Payload/*.app/Info.plist` 存在且不含 `__MACOSX`，避免巨魔解析 IPA 报错 |
| 发布 | 上传 Artifact，并用 `gh` 发布/更新 Releases 标签 `ipa-latest`（此步失败不影响 ipa 产出） |

> 打包这几步（清 AppleDouble 元数据、ad-hoc 签名、`zip -X`、结构校验）来自本账号 `rt-records-ios` 仓库里已跑通的未签名 IPA 工作流：少了它们，TrollStore 打开 ipa 时常见「解析失败 / 安装报错」，或爱思助手、Filza 认不出文件。

核心文件：

| 文件 | 说明 |
|---|---|
| `.github/workflows/build-unsigned-ipa.yml` | GitHub Actions 工作流 |
| `ios-shell/scripts/disable-signing.py` | 关闭 Xcode 自动签名 |
| `ios-shell/build-unsigned-ipa.sh` | 在 Mac 本地跑同一套流程（排错用） |
| `ios-shell/www/index.html` | APP 本体，打包进 ipa 的网页内容 |
| `ios-shell/capacitor.config.json` | appId / appName / webDir |

## 六、常见失败排查

| 现象 | 处理 |
|---|---|
| Actions 报 `No profiles ... were found` / `requires a development team` | 确认「关闭 Xcode 工程里的自动签名」这步执行了；检查日志里 `disable-signing.py` 的替换数量 |
| `pod install` 失败 | 看日志是否 CocoaPods 版本问题；可在该步前加 `sudo gem install cocoapods` |
| `macos-15` 构建机被弃用 / 找不到 Xcode | 改 workflow 里的 `runs-on` 为 `macos-latest`；本流程不固定 Xcode 版本，用 runner 自带即可 |
| `未找到 .app` | archive 失败，往上翻日志看编译错误；常见是 Capacitor 版本与 Xcode 不匹配 |
| 「校验 IPA 结构」这步报混入 `__MACOSX` | `zip` 漏了 `-X`，或 `.app` 里有 `._*` 元数据；确认打包那步的清理命令执行了 |
| 手机上 TrollStore 安装报错 | 多半是 **ldid 没装**，去 TrollStore → Settings → Install ldid；其次看 IPA 是否混入 macOS 元数据 |
| 爱思助手 / Filza 认不出 ipa | 正常现象，未签名 ipa 主要给 TrollStore 用；打包已补 ad-hoc 签名提升兼容性 |
| 安装后闪退 | 确认系统版本在支持范围；确认 `IPHONEOS_DEPLOYMENT_TARGET=14.0` 不高于你的系统 |
| 私有仓库跑不动 / 分钟数不够 | 改成公开仓库 |

## 七、说明

- 这个 ipa 是**未签名**的，只能给自己设备上的巨魔安装，不能上架 App Store，也不建议对外分发。
- 每次改完 `index.html` 或配置，push 一次就会重新构建并更新 Releases 里的 ipa。
- 若想同时保留正规签名路线（archive + exportArchive 出签名 ipa），见 README 第七节与 `ios-shell/build-ipa.sh`。
