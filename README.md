# 口算题卡（Flutter 版）· 小学数学 A4 口算题生成 App

家长自用，给小学生生成数学口算题卡。按年级自动收敛知识点，A4 竖版打印，
每页固定 **125 题（5 列 × 25 行）**，PDF 通过**系统分享面板**保存到本地。

> 本版把整个 App 用 **Flutter** 重写，并完整照搬参考软件
> （呼吸治疗记录 iOS 云构建包 V1.1）的下载逻辑：
> `Printing.sharePdf(bytes: ...)` —— PDF 在内存里生成，直接交给系统分享面板，
> App 不写文档目录、不在手机里新建任何文件夹。

---

## 一、为什么改成 Flutter

| | 旧版（Capacitor + 网页） | 本版（Flutter） |
|---|---|---|
| 保存通道 | 网页 `Filesystem` 写临时缓存 + `Share` 插件中转 | 原生 `Printing.sharePdf()`，一步交给系统面板 |
| 中转文件 | 需要往 CACHE 写一个临时文件、用完再删 | 无，PDF 字节直接从内存交给系统 |
| 手机里 | 虽不建文件夹，但仍有一层网页桥接 | 干净：不碰 Documents、不开文件共享开关 |
| 出题/排版 | HTML + Canvas 画 A4 图片 | Dart 出题引擎 + `pdf` 包矢量排版（文字可选、不失真） |

参考软件的核心代码（`lib/pages/export_page.dart`）：

```dart
final result = await buildRtPdf(...);
await Printing.sharePdf(bytes: result.bytes, filename: filename);
```

本工程 `lib/share.dart` 与之对齐：

```dart
final result = await buildSheetPdf(sheet);     // 内存里生成 PDF
await Printing.sharePdf(bytes: result.bytes, filename: sheetFileName(sheet));
```

设置页是**唯一的保存出口**，预览页右上「保存」是同一函数的快捷入口。
没有下载中心、下载记录、格式切换、打印另存等多余入口。

---

## 二、功能

- **按年级出题**：一年级上 ~ 六年级下，共 12 档，自动限定运算符与数值上限，避免超纲
- **三种题型**：口算 / 竖式 / 填空，比例可调（合计恒为 125 题）
- **含 0 运算**：每页固定 10 道（`0 + 5`、`8 − 0`、`0 × 8`、`0 ÷ 6` 等）
- **填空题**：如 `7 + □ = 12`，答案写在 □ 内，**不追加答案横线**；普通题后带贴底横线
- **可调**：页数（1–5）、数值范围（10/20/100/1000 以内）、每题分值（1–10）
- **页眉固定**：姓名 / 日期 / 用时 / 得分栏，满分按分值自动计算
- **历史试卷**：本机 `shared_preferences` 保存，最多 12 份，不上传
- **不含**：参考答案页、手机做题判分

## 三、页面

| 页面 | 内容 | 主要动作 |
|---|---|---|
| 首页 | 大标题、渐变统计卡、历史试卷列表 | 右上 ⚙ 进设置、＋ 进配置；点卡片进预览 |
| 配置页 | 年级/知识点、题型组合与比例、题量与难度、分值与页眉 | 底部「生成试卷」→ 预览页 |
| 预览页 | A4 试卷 5×25 网格、页码 | 上一页 / 换一批 / 下一页；右上「保存」 |
| 设置页 | **分享 / 保存到本地**（选试卷 → 生成并分享 PDF）、数据管理、关于 | 「生成并分享 / 保存 PDF」调起系统面板 |

## 四、版式（A4 210 × 297 mm）

- 标题「小学数学口算练习卷」居中
- 页眉：姓名 / 日期 / 用时 / 得分（下划线栏）
- 副标题：年级 · 共 125 题 · 每题 X 分 · 满分 Y 分
- 主体：5 列 × 25 行网格，每格一道短算式（矢量文字，缩放不失真）
- 页脚：小学数学出题 · 口算题卡 / 第 X 页 / 共 Y 页
- 中文由内嵌字体 `assets/fonts/WorksheetCJK.ttf`（SimHei 子集，43KB）渲染，不会乱码

## 五、目录结构

```
math-worksheet-flutter/
├── pubspec.yaml                       # pdf / printing / shared_preferences / provider
├── assets/fonts/WorksheetCJK.ttf      # PDF 内嵌中文字体（子集）
├── lib/
│   ├── main.dart                      # 入口、MaterialApp、单壳四页切换
│   ├── app_theme.dart                 # 蓝紫渐变配色
│   ├── engine.dart                    # 出题引擎（纯 Dart，可单测）
│   ├── models.dart                    # 试卷/配置模型 + JSON
│   ├── share.dart                     # ★ 系统分享面板保存（sharePdf）
│   ├── state/app_state.dart           # 配置 + 历史 + 持久化
│   ├── pdf/worksheet_pdf.dart         # A4 PDF 生成（pdf 包）
│   ├── widgets/common.dart            # 分组卡/表单行/步进器/主按钮
│   └── pages/                         # home / config / preview / settings
├── ios/                               # Flutter iOS 工程（无签名、无文件共享开关）
│   └── Runner/Info.plist              # 显示名「口算题卡」，不含 UIFileSharingEnabled
├── scripts/disable-signing.py         # CI 关闭自动签名 + 注入 DEVELOPMENT_TEAM 键
├── tool/                              # 出题引擎回归 + 示例 A4 PDF 生成（CI 真跑）
└── .github/workflows/build-unsigned-ipa.yml   # macOS 云端打包
```

## 六、保存方式（重点）

1. 在设置页选好试卷，点「生成并分享 / 保存 PDF」
2. PDF 在内存里生成（`pdf` 包 + 内嵌中文字体）
3. `Printing.sharePdf` 调起 **iOS 系统分享面板**
4. 选「**存储到文件**」自己决定存哪；也能发微信、邮箱、别的应用
5. App 全程不写 `Documents`、不开 `UIFileSharingEnabled` / `LSSupportsOpeningDocumentsInPlace`，
   「文件」App 里不会出现「口算题卡」文件夹，也不留任何临时文件

首次分享若没看到「存储到文件」，在系统面板里上滑或点「更多」即可找到。

## 七、构建与安装

见 [TROLLSTORE-IPA.md](TROLLSTORE-IPA.md)。简言之：把本工程推到 GitHub，
Actions 在 `macos-15` 上用 `flutter build ios --release --no-codesign` 编译，
打包成未签名 IPA 发布到 Releases 的 `ipa-latest`，手机 Safari 打开下载，
用 TrollStore / 巨魔助手安装。

- 手机系统需 **iOS 15.0 或更高**（Flutter 3.47 的最低部署目标）
- 未签名 IPA 主要给巨魔用；不需要 Apple 开发者证书
- 仅做本地打包，不做应用商店上架与资质审核
