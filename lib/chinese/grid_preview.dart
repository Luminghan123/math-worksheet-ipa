import 'package:flutter/material.dart';

import 'pinyin.dart';
import 'word_bank.dart';
import 'word_models.dart';
import 'word_pdf.dart'
    show kWordCols, wordRows; // 与 PDF 共用列数/行数，保证预览与打印一致

/// ---------------------------------------------------------------------------
/// A4 生字练习卷屏幕预览（逻辑像素 794 × 1123，由外层 FittedBox 缩放）
///
/// 绘制规则与 word_pdf.dart 完全一致：
///   - 每个单元：上方四线三格（标拼音）+ 下方田字格（写字）
///   - 练写字 char   ：四线三格印「字母主体（中格）+ 声调（上格）」，田字格留空
///   - 练拼音 pinyin ：田字格印生字，四线三格留空
///   - 四线三格按书写规范：字母主体撑满中格，声调矢量画在上格并对准带调字母
/// 用 Flutter CustomPainter 画格子，和 PDF 的矢量线条一一对应。
/// ---------------------------------------------------------------------------
class WordSheetPreview extends StatelessWidget {
  final WordSheet sheet;
  final int pageIndex; // 0-based

  const WordSheetPreview({
    super.key,
    required this.sheet,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final total = sheet.pages.length;
    final page = pageIndex.clamp(0, total - 1);
    final words = sheet.pages[page];
    final rows = wordRows(sheet.perPage);

    return Container(
      width: 794,
      height: 1123,
      padding: const EdgeInsets.fromLTRB(42, 32, 42, 26),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '小学语文生字练习卷',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 23, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
          ),
          const SizedBox(height: 9),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('姓名：____________', style: TextStyle(fontSize: 12)),
              Text('班级：____________', style: TextStyle(fontSize: 12)),
              Text('日期：____________', style: TextStyle(fontSize: 12)),
              Text('得分：________', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${sheet.gradeLabel} · ${modeLabel(sheet.mode)} · 共 ${sheet.perPage} 字 · '
            '第 ${page + 1} 页 / 共 $total 页',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 7),
          Container(height: 1, color: const Color(0xFF333333)),
          const SizedBox(height: 7),
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, cons) {
                final gridW = cons.maxWidth;
                final gridH = cons.maxHeight;
                final cellW = gridW / kWordCols;
                final cellH = gridH / rows;
                return Table(
                  border: TableBorder.all(
                      width: 0.5, color: const Color(0xFFEADCDC)),
                  columnWidths: {
                    for (var c = 0; c < kWordCols; c++) c: const FlexColumnWidth(1),
                  },
                  children: List.generate(rows, (r) {
                    return TableRow(
                      children: List.generate(kWordCols, (c) {
                        final i = r * kWordCols + c;
                        final h = i < words.length ? words[i] : const Hanzi('', '');
                        return SizedBox(
                          height: cellH,
                          child: _WordCell(
                            hanzi: h,
                            writeChar: sheet.mode == kModeWriteChar,
                            cellW: cellW,
                            cellH: cellH,
                          ),
                        );
                      }),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('小学语文生字练习 · 口算题卡',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF666666))),
              Text('第 ${page + 1} 页 / 共 $total 页',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF666666))),
            ],
          ),
        ],
      ),
    );
  }
}

/// 单个生字单元（四线三格 + 田字格）
class _WordCell extends StatelessWidget {
  final Hanzi hanzi;
  final bool writeChar;
  final double cellW;
  final double cellH;

  const _WordCell({
    required this.hanzi,
    required this.writeChar,
    required this.cellW,
    required this.cellH,
  });

  @override
  Widget build(BuildContext context) {
    final fourH = (9.0 / 250.0 * 1123).clamp(18.0, cellH * 0.26);
    final gap = 4.0;
    final side = _min(cellW - 12, cellH - fourH - gap - 6).clamp(20.0, cellW - 12);

    final PinyinLayout? ly = (writeChar && hanzi.pinyin.isNotEmpty)
        ? layoutPinyin(hanzi.pinyin, side, fourH)
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 四线三格
        SizedBox(
          width: side,
          height: fourH,
          child: CustomPaint(
            painter: _FourLinesPainter(ly: ly),
            child: ly == null ? null : _pinyinLetters(ly),
          ),
        ),
        SizedBox(height: gap),
        // 田字格
        SizedBox(
          width: side,
          height: side,
          child: CustomPaint(
            painter: _TianPainter(),
            child: Center(
              child: Text(
                writeChar ? '' : hanzi.char,
                style: TextStyle(fontSize: side * 0.62, color: const Color(0xFF1A1A1A)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 字母主体：逐字等宽分列（与 PDF 端一致），垂直落在中格。
  Widget _pinyinLetters(PinyinLayout ly) {
    final base = ly.parts.base;
    return Stack(
      children: [
        for (var i = 0; i < ly.letterCount; i++)
          Positioned(
            left: ly.x0 + i * ly.unitW,
            top: ly.cellH,
            child: SizedBox(
              width: ly.unitW,
              height: ly.cellH,
              child: Center(
                child: Text(
                  base[i],
                  style: TextStyle(fontSize: ly.fontSize, color: const Color(0xFF1A1A1A)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static double _min(double a, double b) => a < b ? a : b;
}

/// 四线三格：4 条水平线（1/4 实线、2/3 虚线）+ 上格声调矢量
class _FourLinesPainter extends CustomPainter {
  final PinyinLayout? ly;

  const _FourLinesPainter({this.ly});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final solid = Paint()
      ..color = const Color(0xFF777777)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, 0), Offset(w, 0), solid);
    canvas.drawLine(Offset(0, h), Offset(w, h), solid);
    final dash = Paint()
      ..color = const Color(0xFFB4B4B4)
      ..strokeWidth = 0.7;
    _dashedLine(canvas, Offset(0, h / 3), Offset(w, h / 3), dash, 4, 3);
    _dashedLine(canvas, Offset(0, 2 * h / 3), Offset(w, 2 * h / 3), dash, 4, 3);

    // 声调：Flutter Canvas 为「左上原点、y 向下」，直接用视觉坐标
    if (ly != null && ly!.parts.hasTone) {
      final tonePaint = Paint()
        ..color = const Color(0xFF1A1A1A)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      for (final s in toneSegments(ly!.parts.tone)) {
        final p1 = ly!.tonePoint(s[0], s[1]);
        final p2 = ly!.tonePoint(s[2], s[3]);
        canvas.drawLine(
            Offset(p1[0], p1[1]), Offset(p2[0], p2[1]), tonePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 田字格：外框 + 横竖十字中线（虚线），无对角线
class _TianPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final border = Paint()
      ..color = const Color(0xFFC98F8F)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), border);
    final dash = Paint()
      ..color = const Color(0xFFDCC0C0)
      ..strokeWidth = 0.8;
    _dashedLine(canvas, Offset(0, h / 2), Offset(w, h / 2), dash, 4, 3);
    _dashedLine(canvas, Offset(w / 2, 0), Offset(w / 2, h), dash, 4, 3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 画虚线（按长度分段），PDF 端用 setLineDashPattern，屏幕端手动画等效
void _dashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint,
    double dashW, double gapW) {
  final dx = p2.dx - p1.dx;
  final dy = p2.dy - p1.dy;
  final len = (dx * dx + dy * dy);
  if (len == 0) return;
  final dist = _sqrt(len);
  final ux = dx / dist;
  final uy = dy / dist;
  double start = 0;
  while (start < dist) {
    final end = (start + dashW) > dist ? dist : (start + dashW);
    canvas.drawLine(
      Offset(p1.dx + ux * start, p1.dy + uy * start),
      Offset(p1.dx + ux * end, p1.dy + uy * end),
      paint,
    );
    start = end + gapW;
  }
}

double _sqrt(double x) {
  // 避免 import dart:math 与 preview 里其它符号冲突，用牛顿迭代
  if (x <= 0) return 0;
  var v = x;
  for (var i = 0; i < 24; i++) {
    v = (v + x / v) / 2;
  }
  return v;
}
