# 口算题卡（Flutter 版）· 小学数学口算 + 小学语文生字练习 App

家长自用，给小学生生成数学口算题卡与语文生字练习纸。A4 竖版打印，
口算卷每页固定 **125 题（5 列 × 25 行）**；生字卷用**田字格 + 四线三格**。
PDF 在内存里生成后通过**系统分享面板 / Windows「另存为」**保存到本地。

> 本版用 **Flutter** 重写，完整照搬参考软件（呼吸治疗记录 iOS 云构建包 V1.1）
> 的下载逻辑：`Printing.sharePdf(bytes: ...)`。App 不写文档目录、
> 不在手机里新建任何文件夹、不开文件共享开关。

---

## 一、为什么改成 Flutter

| | 旧版（Capacitor + 网页） | 本版（Flutter） |
|---|---|---|
| 保存通道 | 网页 `Filesystem` 写临时缓存 + `Share` 插件中转 | 原生 `Printing.sharePdf()`，一步交给系统面板 |
| 中转文件 | 需要往 CACHE 写临时文件、用完再删 | 无，PDF 字节直接从内存交给系统 |
| 出题/排版 | HTML + Canvas 画 A4 图片 | Dart 出题引擎 + `pdf` 包矢量排版（文字可选、不失真） |
| 双端 | 仅 iOS/Android | iOS / Android（Material）+ Windows（Fluent UI） |

---

## 二、功能

### 数学口算
- **按年级出题**：一年级上 ~ 六年级下，共 12 档，自动限定运算符与数值上限，避免超纲
- **三种题型**：口算 / 竖式 / 填空，比例可调（合计恒为 125 题）
- **含 0 运算**：每页固定 10 道（`0 + 5`、`8 − 0`、`0 × 8`、`0 ÷ 6` 等）
- **填空题**：如 `7 + □ = 12`，答案写在 □ 内，**不追加答案横线**；普通题后带**贴着算式文字底部**的横线
- **可调**：页数（1–5）、数值范围（10/20/100/1000 以内）、每题分值（1–10）
- **历史试卷**：本机 `shared_preferences` 保存，最多 12 份，不上传

### 语文生字（V2 新增）
- **两种卷子分开选**：
  - **练写字**：四线三格印带调拼音、田字格留空 → 照拼音写生字
  - **练拼音**：田字格印生字、四线三格留空 → 给生字标拼音
- **字表**：内置 1–6 年级共 12 册分级字表（每册 24 字），也可粘贴一课生字自定义
  （纯汉字自动补拼音，也支持 `天:tiān 地:dì` 格式）
- **可调**：每页字数（20 / 30 / 40）、页数（1–5）
- **独立历史**：生字练习卷用独立存储 key（`mwa_flutter_word_history_v1`），与口算试卷互不干扰
- **不含**：参考答案页、手机做题判分

## 三、页面

| 页面 | 内容 | 主要动作 |
|---|---|---|
| 首页 | 大标题、渐变统计卡、**语文生字入口**、历史试卷列表 | ⚙ 进设置、＋ 进配置、生字入口进生字模块 |
| 口算配置页 | 年级/知识点、题型比例、题量、分值 | 底部「生成试卷」→ 预览页 |
| 口算预览页 | A4 试卷 5×25 网格 | 翻页 / 换一批 / 右上「保存」 |
| 语文生字页 | 字表/模式/字数/页数/自定义字 + 最近练习卷 → A4 预览 | 生成练习纸 → 翻页 / 换一批 / 保存 |
| 设置页 | 分享 / 保存到本地、数据管理、关于 | 调起系统面板 |

桌面端（Windows）用 Fluent UI 左侧导航四页：**出题 / 语文生字 / 历史试卷 / 设置**，
配置与预览左右分栏；移动端（iOS/Android）用单壳页面切换，生字模块为「配置 → 预览」两态。

## 四、版式（A4 210 × 297 mm）

**口算卷**：标题「小学数学口算练习卷」→ 姓名/日期/用时/得分页眉 → 副标题 →
5 列 × 25 行网格（每格一道短算式 + 贴底答案横线）→ 页脚。
中文由内嵌字体 `assets/fonts/WorksheetCJK.ttf`（SimHei 子集，43KB）渲染。

**生字卷**：标题「小学语文生字练习卷」→ 姓名/班级/日期/得分页眉 → 副标题 →
每字一个单元（**上方四线三格**：4 条线，外实内虚，字母主体撑满中格、
**声调矢量符号单独画在上格并对准带调字母**，符合《汉语拼音字母书写规范》；
**下方田字格**：外框 + 横竖十字中线，虚线辅助，**无对角线**）→ 页脚。
中文与拼音字母由扩展字体渲染（595 字符，覆盖全部生字、基础拉丁字母、
无点 i `ı`、`ü` 及页眉字）；声调符号为矢量线条，不依赖字体字形。

> 字体说明：扩展字体以 **base64 文本** `assets/fonts/WorksheetCJK_Ext.ttf.b64`
> 随源码提交，`lib/chinese/word_share.dart` 在运行时 `base64Decode` 还原字节后
> 交给 `pdf` 包。这样工程全部文件都是文本，便于纯文本通道完整同步。
> 需要重新生成时运行 `python3 tool/build_ext_font.py`（依赖 `fonttools`），
> 它会同时输出 `.ttf` 与 `.ttf.b64`。

## 五、目录结构

```
math-worksheet-flutter/
├── pubspec.yaml                          # pdf / printing / shared_preferences / provider
│                                         # fluent_ui / file_selector（Windows）
├── assets/fonts/
│   ├── WorksheetCJK.ttf                  # 口算卷内嵌中文字体（子集，二进制）
│   └── WorksheetCJK_Ext.ttf.b64          # 生字卷扩展字体（base64 文本）
├── lib/
│   ├── main.dart                         # 入口、MultiProvider、平台分支、单壳五页切换
│   ├── app_theme.dart / widgets/common.dart   # 视觉体系与可复用组件
│   ├── engine.dart / models.dart         # 口算出题引擎与数据模型（纯 Dart）
│   ├── state/app_state.dart              # 口算配置 + 历史 + 持久化
│   ├── share.dart / pdf/worksheet_pdf.dart   # 系统分享 + A4 口算 PDF 生成
│   ├── pages/                            # home / config / preview / settings / word_page
│   ├── chinese/                          # ★ V2 生字模块（独立一套，不改动口算）
│   │   ├── word_bank.dart                #   内置分级字表 + 拼音索引
│   │   ├── word_models.dart              #   WordConfig / WordSheet / 模式常量
│   │   ├── word_engine.dart              #   抽字出题（纯 Dart）
│   │   ├── pinyin.dart                   #   拼音拆调 + 声调矢量 + 四线格排版（纯 Dart，两端共用）
│   │   ├── word_pdf.dart                 #   田字格 + 四线三格矢量 PDF
│   │   ├── grid_preview.dart             #   屏幕预览 CustomPainter
│   │   ├── word_share.dart               #   字体解码 + 生成 / 分享 / 文件名
│   │   └── word_state.dart               #   独立状态 + 独立历史 key
│   └── desktop/                          # Windows Fluent UI 外壳与各页
│       ├── app_desktop.dart / save_windows.dart
│       ├── widgets/sheet_preview.dart
│       └── pages/                        #   generate / word / history / settings
├── ios/                                  # Flutter iOS 工程（无签名、无文件共享开关）
├── scripts/disable-signing.py            # CI 关闭自动签名 + 注入 DEVELOPMENT_TEAM
├── tool/                                 # 出题引擎回归 + 示例 PDF + 扩展字体生成脚本
└── .github/workflows/
    ├── build-unsigned-ipa.yml            # macOS 云端打包未签名 IPA → ipa-latest
    └── windows-build.yml                 # Windows 云端打包绿色版 zip → win-latest
```

## 六、保存方式（重点）

**iOS / Android**：点「保存」→ `Printing.sharePdf` 调起系统分享面板 →
选「**存储到文件**」自己决定存哪；也能发微信、邮箱。App 全程不写 `Documents`、
不开 `UIFileSharingEnabled`，「文件」App 里不会出现「口算题卡」文件夹。

**Windows**：点「保存到本地」→ `file_selector.getSaveLocation()` 弹出系统「另存为」
→ PDF 字节直接写入你选的路径。不写注册表、不建快捷方式、不留临时文件。

## 七、构建与安装

把工程推到 GitHub 后，两个 Actions 工作流会自动构建：

| 工作流 | Runner | 产物 | Release 固定标签 |
|---|---|---|---|
| `build-unsigned-ipa.yml` | `macos-15` | `math-worksheet-unsigned.ipa` | `ipa-latest` |
| `windows-build.yml` | `windows-latest` | `math-worksheet-windows.zip` | `win-latest` |

- **iOS**：手机 Safari 打开 Release 下载 IPA，用 TrollStore / 巨魔助手安装；
  系统需 **iOS 15.0+**。未签名 IPA 主要给巨魔用，不需要 Apple 开发者证书。
- **Windows**：下载 zip 解压，双击 `math_worksheet.exe` 即可运行（绿色免安装版）。
- 详见 [TROLLSTORE-IPA.md](TROLLSTORE-IPA.md)。
- 仅做本地打包，不做应用商店上架与资质审核。
