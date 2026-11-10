import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pinyin.dart';
import 'word_bank.dart';
import 'word_models.dart';

/// ---------------------------------------------------------------------------
/// 小学语文生字练习卷 PDF（A4 矢量）
///
/// 版式：每个生字一个「单元」——上方四线三格（标拼音）、下方田字格（写字）。
///   - 练写字 char   ：四线三格印拼音，田字格留空（照拼音写生字）
///   - 练拼音 pinyin ：田字格印生字，四线三格留空（给生字注音）
///
/// 四线三格按《汉语拼音字母书写规范》排版：字母主体放大撑满中格，声调符号
/// 单独以矢量线条画在**上格**并对准带调字母（不再是整串居中、调号贴字母）。
/// 田字格 = 外框 + 横竖十字中线（虚线），无对角线。
///
/// 格子全部用矢量线条绘制（CustomPaint + PdfGraphics.drawLine/drawRect +
/// strokePath），打印不糊、放大不毛边；汉字与拼音字母用扩展字体内嵌。
/// 本文件不 import 任何 Flutter 类，便于纯 Dart 脚本本地自检。
/// ---------------------------------------------------------------------------

const double _mm = 72 / 25.4;

/// 每页固定 5 列；20/30/40 字 → 4/6/8 行，均整除，排布整齐
const int kWordCols = 5;
int wordRows(int perPage) => (perPage / kWordCols).ceil();

/// 网格可用总高（A4 297mm − 上下 margin 18mm − 标题页眉 ≈ 22mm − 页脚 ≈ 5mm）
const double _gridHeightMm = 250.0;

double wordRowHeightMm(int perPage) => _gridHeightMm / wordRows(perPage);

/// 颜色：打印友好（黑白也能分辨）
final PdfColor _cGridLine = PdfColor.fromInt(0xffc98f8f); // 田字格外框（浅红）
final PdfColor _cGridDash = PdfColor.fromInt(0xffdcc0c0); // 田字格十字中线（更浅）
final PdfColor _cFourSolid = PdfColor.fromInt(0xff777777); // 四线三格 实线
final PdfColor _cFourDash = PdfColor.fromInt(0xffb4b4b4); // 四线三格 虚线
final PdfColor _cInk = PdfColor.fromInt(0xff1a1a1a); // 字/拼音/声调

class WordPdfBuildResult {
  final Uint8List bytes;
  final int pageCount;
  const WordPdfBuildResult(this.bytes, this.pageCount);
}

/// [fontBytes] 为扩展字体 WorksheetCJK_Ext.ttf 的原始字节。
Future<WordPdfBuildResult> buildWordPdf(
    WordSheet sheet, Uint8List fontBytes) async {
  final font = pw.Font.ttf(ByteData.sublistView(fontBytes));
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: font),
    title: '小学语文生字练习卷 · ${sheet.gradeLabel}',
  );
  final total = sheet.pages.length;
  for (var i = 0; i < total; i++) {
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.only(
        left: 11 * _mm,
        right: 11 * _mm,
        top: 10 * _mm,
        bottom: 8 * _mm,
      ),
      build: (ctx) => _buildPage(sheet, sheet.pages[i], i, total, font.getFont(ctx)),
    ));
  }
  final bytes = await doc.save();
  return WordPdfBuildResult(Uint8List.fromList(bytes), total);
}

pw.Widget _buildPage(
    WordSheet sheet, List<Hanzi> words, int idx, int total, PdfFont pdfFont) {
  final rowH = wordRowHeightMm(sheet.perPage) * _mm;
  final rows = wordRows(sheet.perPage);

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      // ---------- 标题 ----------
      pw.Text(
        '小学语文生字练习卷',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 6 * _mm, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 2.4 * _mm),
      // ---------- 页眉 ----------
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          '姓名：____________',
          '班级：____________',
          '日期：____________',
          '得分：________',
        ]
            .map((t) => pw.Text(t, style: pw.TextStyle(fontSize: 3.2 * _mm)))
            .toList(),
      ),
      pw.SizedBox(height: 1.8 * _mm),
      // ---------- 副标题 + 分隔线 ----------
      pw.Container(
        padding: pw.EdgeInsets.only(bottom: 1.6 * _mm),
        child: pw.Text(
          '${sheet.gradeLabel} · ${modeLabel(sheet.mode)} · 共 ${sheet.perPage} 字 · '
          '第 ${idx + 1} 页 / 共 $total 页',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 3 * _mm),
        ),
      ),
      pw.Container(height: 0.3 * _mm, color: PdfColors.grey800),
      pw.SizedBox(height: 1.6 * _mm),

      // ---------- 生字网格 ----------
      pw.Table(
        border: pw.TableBorder.all(width: 0.15 * _mm, color: _cGridDash),
        columnWidths: {
          for (var c = 0; c < kWordCols; c++) c: const pw.FlexColumnWidth(),
        },
        children: List.generate(rows, (r) {
          return pw.TableRow(
            children: List.generate(kWordCols, (c) {
              final i = r * kWordCols + c;
              final h = i < words.length ? words[i] : const Hanzi('', '');
              return pw.Container(
                height: rowH,
                alignment: pw.Alignment.center,
                child: _wordCell(h, sheet.mode, sheet.perPage, pdfFont),
              );
            }),
          );
        }),
      ),
      pw.SizedBox(height: 2 * _mm),
      // ---------- 页脚 ----------
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('小学语文生字练习 · 口算题卡',
              style:
                  pw.TextStyle(fontSize: 2.8 * _mm, color: PdfColors.grey700)),
          pw.Text('第 ${idx + 1} 页 / 共 $total 页',
              style:
                  pw.TextStyle(fontSize: 2.8 * _mm, color: PdfColors.grey700)),
        ],
      ),
    ],
  );
}

/// 单个生字单元：四线三格（上）+ 田字格（下）
pw.Widget _wordCell(Hanzi h, String mode, int perPage, PdfFont pdfFont) {
  final rowH = wordRowHeightMm(perPage) * _mm;
  // 网格总宽 = A4 210 − 左右 22 = 188mm，5 列
  final cellW = (188.0 / kWordCols) * _mm;
  // 四线三格高度与田字格边长（保持田字格正方形）
  final fourH = math.min(9.0 * _mm, rowH * 0.26);
  final gap = 1.2 * _mm;
  final side = math.min(
    cellW - 3 * _mm,
    rowH - fourH - gap - 1.5 * _mm,
  );

  final bool writeChar = mode == kModeWriteChar;
  // 练写字模式：四线三格印「字母主体 + 上格声调」；练拼音模式四线格留空
  final PinyinLayout? ly =
      writeChar && h.pinyin.isNotEmpty ? layoutPinyin(h.pinyin, side, fourH) : null;

  return pw.Column(
    mainAxisSize: pw.MainAxisSize.min,
    mainAxisAlignment: pw.MainAxisAlignment.center,
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      // ---------- 四线三格 ----------
      pw.Container(
        width: side,
        height: fourH,
        // 网格、字母主体、声调全部用 canvas 直接绘制（同一 painter）。
        // 不把字母放进 CustomPaint 的 child —— 部分 PDF 阅读器不渲染
        // CustomPaint 内的复杂嵌套 child（如 Stack），会导致拼音字母消失、
        // 只剩矢量的网格与声调。canvas.drawString 与田字格汉字走同一
        // 文字嵌入路径，汉字能显示它就能显示。
        child: pw.CustomPaint(
          painter: (canvas, size) {
            _paintFourLines(canvas, size.x, size.y);
            if (ly != null) {
              _paintLetters(canvas, size.y, ly, pdfFont);
              if (ly.parts.hasTone) _paintTone(canvas, size.y, ly);
            }
          },
        ),
      ),
      pw.SizedBox(height: gap),
      // ---------- 田字格 ----------
      pw.Container(
        width: side,
        height: side,
        child: pw.CustomPaint(
          painter: (canvas, size) => _paintTianGrid(canvas, size.x, size.y),
          child: pw.Center(
            child: pw.Text(
              writeChar ? '' : h.char,
              style: pw.TextStyle(fontSize: side * 0.62, color: _cInk),
            ),
          ),
        ),
      ),
    ],
  );
}

/// 字母主体：逐字等宽分列，整体水平居中，垂直落在中格（PDF 坐标，y 向上）。
/// 用 canvas.drawString 直接画（与网格、声调同属 painter），避开 CustomPaint
/// 嵌套 child 在部分阅读器不渲染的问题。
void _paintLetters(
    PdfGraphics canvas, double fourH, PinyinLayout ly, PdfFont pdfFont) {
  final cellH = ly.cellH;
  final base = ly.parts.base;
  final fs = ly.fontSize;
  // 中格 y∈[cellH, 2cellH]；baseline 落在中格内偏下，字母自然撑满中格、
  // 上伸进上格、下伸进下格（符合书写规范）。
  final baseline = cellH + fs * 0.18;
  canvas.setColor(_cInk);
  for (var i = 0; i < ly.letterCount; i++) {
    final ch = base[i];
    final gm = pdfFont.glyphMetrics(ch.codeUnitAt(0));
    final w = gm.width / pdfFont.unitsPerEm * fs;
    final x = ly.x0 + i * ly.unitW + (ly.unitW - w) / 2;
    canvas.drawString(pdfFont, fs, ch, x, baseline);
  }
}

/// 画四线三格：4 条水平线，1/4 实线、2/3 虚线，形成 3 个等距格。
/// 坐标原点在左下角（PDF 原生坐标，y 向上）。
void _paintFourLines(PdfGraphics canvas, double w, double h) {
  // 外两条实线
  canvas
    ..setColor(_cFourSolid)
    ..setLineWidth(0.22 * _mm);
  canvas.drawLine(0, 0, w, 0);
  canvas.drawLine(0, h, w, h);
  canvas.strokePath();

  // 中间两条虚线
  canvas
    ..setColor(_cFourDash)
    ..setLineDashPattern([1.1 * _mm, 0.9 * _mm]);
  canvas.drawLine(0, h / 3, w, h / 3);
  canvas.drawLine(0, 2 * h / 3, w, 2 * h / 3);
  canvas.strokePath();
  canvas.setLineDashPattern(); // 复位，避免影响后续绘制
}

/// 在上格画声调矢量符号，精确对准带调字母所在列。
/// [h] 为四线三格总高；PinyinLayout 用「左上原点、y 向下」的视觉坐标，
/// PDF 需翻转：pdfY = h - visualY。
void _paintTone(PdfGraphics canvas, double h, PinyinLayout ly) {
  final segs = toneSegments(ly.parts.tone);
  if (segs.isEmpty) return;
  canvas
    ..setColor(_cInk)
    ..setLineWidth(0.32 * _mm);
  for (final s in segs) {
    final p1 = ly.tonePoint(s[0], s[1]);
    final p2 = ly.tonePoint(s[2], s[3]);
    canvas.drawLine(p1[0], h - p1[1], p2[0], h - p2[1]);
  }
  canvas.strokePath();
}

/// 画田字格：外框实线 + 横/竖十字中线（虚线）。无对角线（区别于田字格）。
/// 坐标原点在左下角（y 向上）。
void _paintTianGrid(PdfGraphics canvas, double w, double h) {
  // 外框
  canvas
    ..setColor(_cGridLine)
    ..setLineWidth(0.3 * _mm);
  canvas.drawRect(0, 0, w, h);
  canvas.strokePath();

  // 十字中线（虚线）
  canvas
    ..setColor(_cGridDash)
    ..setLineWidth(0.18 * _mm)
    ..setLineDashPattern([1.0 * _mm, 0.9 * _mm]);
  canvas.drawLine(0, h / 2, w, h / 2);
  canvas.drawLine(w / 2, 0, w / 2, h);
  canvas.strokePath();
  canvas.setLineDashPattern(); // 复位
}
