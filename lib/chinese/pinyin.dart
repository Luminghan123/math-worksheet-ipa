/// ---------------------------------------------------------------------------
/// 拼音拆分：把「带调号的音节」拆成「字母主体 + 声调」，供四线三格排版使用。
///
/// 依据《汉语拼音字母书写规范》：
///   「声调、圆点写上格，胳膊长了住上格，尾巴长了住下格，其它部分在中格。
///    中格一定要饱满，上格、下格空一点儿。」
/// 所以印刷示范拼音时，调号不能贴在字母上（落在中格顶部），必须单独画在
/// **上格**；字母主体放大放在**中格**并撑满。
///
/// 本文件是纯 Dart（不 import Flutter / pdf），PDF 导出与屏幕预览共用，
/// 保证打印出来的和屏幕上看到的位置完全一致。
/// ---------------------------------------------------------------------------

/// 拆分结果
class PinyinParts {
  /// 去掉调号后的字母串（带调 i 用无点 ı，带调 ü 保留 ü）
  final String base;

  /// 声调：1 一声 ˉ / 2 二声 ˊ / 3 三声 ˇ / 4 四声 ˋ；0 表示轻声或不标调
  final int tone;

  /// 声调应标在 [base] 的第几个字母正上方；-1 表示不标
  final int toneIndex;

  const PinyinParts(this.base, this.tone, this.toneIndex);

  bool get hasTone => tone > 0 && toneIndex >= 0 && toneIndex < base.length;
}

/// 声调符号的矢量线段（归一化坐标 0..1，原点左上、y 向下为正）。
/// 每段为 [x1, y1, x2, y2]。PDF 端绘制时把 y 翻转为 (1 - y)。
List<List<double>> toneSegments(int tone) {
  switch (tone) {
    case 1: // ˉ 一声：水平高平
      return const [
        [0.14, 0.52, 0.86, 0.52],
      ];
    case 2: // ˊ 二声：左下 → 右上（升）
      return const [
        [0.26, 0.82, 0.74, 0.18],
      ];
    case 3: // ˇ 三声：先降后升的 ∨
      return const [
        [0.18, 0.24, 0.50, 0.80],
        [0.50, 0.80, 0.82, 0.24],
      ];
    case 4: // ˋ 四声：左上 → 右下（降）
      return const [
        [0.26, 0.18, 0.74, 0.82],
      ];
    default: // 轻声不标调
      return const <List<double>>[];
  }
}

/// 预组合带调字母 → [基础字母的码点, 声调]。
/// 每条 3 个 UTF-16 code unit：带调字母 / 基础字母 / 声调数字。
/// 带调 i 用 U+0131（ı，无点 i），对应规范「i 上标调要去掉点」。
const String _kToneTable = 'āa1 áa2 ǎa3 àa4 '
    'ēe1 ée2 ěe3 èe4 '
    'īı1 íı2 ǐı3 ìı4 '
    'ōo1 óo2 ǒo3 òo4 '
    'ūu1 úu2 ǔu3 ùu4 '
    'ǖü1 ǘü2 ǚü3 ǜü4 '
    'ńn2 ňn3 ǹn4 ḿm2';

final Map<int, List<int>> _toneMap = () {
  final m = <int, List<int>>{};
  for (final tok in _kToneTable.trim().split(RegExp(r'\s+'))) {
    if (tok.isEmpty) continue;
    final cu = tok.codeUnits;
    if (cu.length < 3) continue;
    m[cu[0]] = [cu[1], int.tryParse(String.fromCharCode(cu[2])) ?? 0];
  }
  return m;
}();

/// 数字调号（如 "tian1"）按「有 a 不放过，没 a 找 o e，i/u 并排标在后」
/// 推算调号该标在哪个字母上。
int _defaultToneIndex(String s) {
  final lower = s.toLowerCase();
  for (final v in const ['a', 'o', 'e']) {
    final i = lower.indexOf(v);
    if (i >= 0) return i;
  }
  // i / u / ü / v 并列时标在后面那个
  for (var i = lower.length - 1; i >= 0; i--) {
    final c = lower[i];
    if (c == 'i' || c == 'u' || c == 'ü' || c == 'v' || c == 'ı') return i;
  }
  return -1;
}

/// 把带调拼音音节拆成「字母主体 + 声调 + 调号所在字母下标」。
///
/// 兼容三种输入：
///   1) 预组合带调字母（字表用的，如 tiān、lǜ、shí）；
///   2) 末尾数字调号（自定义粘贴常见，如 tian1、lv4）；
///   3) 不带调（轻声 / 用户省略），照原样显示、不画调号。
PinyinParts splitPinyin(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return const PinyinParts('', 0, -1);

  // 末尾数字 1..4 视为调号
  var trailingTone = 0;
  final last = s.codeUnitAt(s.length - 1);
  if (last >= 0x31 && last <= 0x34) {
    trailingTone = last - 0x30;
    s = s.substring(0, s.length - 1);
  }

  final buf = StringBuffer();
  var tone = trailingTone;
  var toneIndex = -1;
  for (final cu in s.codeUnits) {
    final mapped = _toneMap[cu];
    if (mapped != null) {
      tone = mapped[1];
      toneIndex = buf.length;
      buf.writeCharCode(mapped[0]);
    } else {
      buf.writeCharCode(cu);
    }
  }
  final base = buf.toString();
  if (trailingTone > 0 && toneIndex < 0) {
    toneIndex = _defaultToneIndex(base);
  }
  return PinyinParts(base, tone, toneIndex);
}

/// ---------------------------------------------------------------------------
/// 四线三格排版参数（纯 Dart，PDF 与屏幕预览共用）。
///
/// 四线三格由 4 条横线分成上/中/下 3 个等距格，每格高 cellH = fourH / 3。
/// 视觉坐标统一采用「左上原点、y 向下为正」（与 Flutter Canvas / pw 布局一致）：
///   - 上格 y ∈ [0, cellH]      → 声调符号、圆点
///   - 中格 y ∈ [cellH, 2cellH] → 字母主体（要饱满）
///   - 下格 y ∈ [2cellH, 3cellH] → g/p/q/y 的尾巴
/// PDF 的 PdfGraphics 是左下原点、y 向上，绘制时用 pdfY = fourH - visualY 翻转。
///
/// 字母逐字等宽分列，整体水平居中；声调框精确落在带调字母所在列的上格中央。
/// ---------------------------------------------------------------------------
class PinyinLayout {
  final PinyinParts parts;

  /// 每个字母列的宽度
  final double unitW;

  /// 字母整体占宽（unitW × 字母数）
  final double totalW;

  /// 字母整体左边界
  final double x0;

  /// 每格高度
  final double cellH;

  /// 字母字号
  final double fontSize;

  /// 声调符号框尺寸
  final double toneW;
  final double toneH;

  const PinyinLayout({
    required this.parts,
    required this.unitW,
    required this.totalW,
    required this.x0,
    required this.cellH,
    required this.fontSize,
    required this.toneW,
    required this.toneH,
  });

  int get letterCount => parts.base.length;

  /// 第 i 个字母列中心的 x
  double letterCenterX(int i) => x0 + (i + 0.5) * unitW;

  /// 声调框左上角（视觉坐标）
  double get toneBoxX =>
      x0 + (parts.toneIndex + 0.5) * unitW - toneW / 2;
  double get toneBoxY => (cellH - toneH) / 2;

  /// 把声调归一化坐标 (nx, ny) 映射到视觉坐标
  List<double> tonePoint(double nx, double ny) =>
      [toneBoxX + nx * toneW, toneBoxY + ny * toneH];
}

/// 计算排版参数。[side] 为四线三格宽度，[fourH] 为其总高。
PinyinLayout layoutPinyin(String raw, double side, double fourH) {
  final parts = splitPinyin(raw);
  final n = parts.base.isEmpty ? 1 : parts.base.length;
  final cellH = fourH / 3;
  final fontSize = cellH * 1.28; // 字母主体放大，撑满中格（上伸/下伸自然进上格、下格）
  // 等宽列：列宽约等于字母宽度（≈0.58 字号），保证字母紧挨又不重叠；
  // 同时限制整串不超过 side 的 94%，避免长音节（zhuāng 等）溢出格子。
  final unitW = _min(fontSize * 0.60, side * 0.94 / n);
  final totalW = unitW * n;
  return PinyinLayout(
    parts: parts,
    unitW: unitW,
    totalW: totalW,
    x0: (side - totalW) / 2,
    cellH: cellH,
    fontSize: fontSize,
    toneW: unitW * 0.82,
    toneH: cellH * 0.52,
  );
}

double _min(double a, double b) => a < b ? a : b;
