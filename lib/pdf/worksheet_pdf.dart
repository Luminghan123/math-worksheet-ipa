import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../engine.dart';
import '../models.dart';

/// ---------------------------------------------------------------------------
/// A4 口算试卷 PDF 生成（用 pdf 包绘制矢量文字，内嵌中文字体，不会乱码）
///
/// 本文件刻意不 import 任何 Flutter 类：字体字节由调用方传入，这样本地可以
/// 用纯 Dart 脚本直接生成 PDF 校验版式，App 里则从 assets 加载后调用。
///
/// 版式与旧版 index.html 一致：
///   - A4 竖版 210 × 297 mm
///   - 标题「小学数学口算练习卷」+ 姓名/日期/用时/得分 页眉
///   - 副标题：年级 · 共 125 题 · 每题 X 分 · 满分 Y 分
///   - 5 列 × 25 行网格，每格一道短算式
///   - 普通题后带答案横线；含 □ 的填空题不追加横线
///   - 页脚：小学数学出题 · 口算题卡 / 第 X 页 / 共 Y 页
/// ---------------------------------------------------------------------------

/// PDF 坐标单位换算：1 mm = 72/25.4 pt
const double _mm = 72 / 25.4;

class PdfBuildResult {
  final Uint8List bytes;
  final int pageCount;

  const PdfBuildResult(this.bytes, this.pageCount);
}

/// [fontBytes] 为内嵌中文字体（WorksheetCJK.ttf）的原始字节。
/// doc.save() 是异步的，故本函数返回 Future。
Future<PdfBuildResult> buildWorksheetPdf(
    Worksheet sheet, Uint8List fontBytes) async {
  final font = pw.Font.ttf(ByteData.sublistView(fontBytes));
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: font),
    title: '小学数学口算练习卷 · ${sheet.gradeLabel}',
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
      build: (ctx) => _buildSheetPage(sheet, sheet.pages[i], i, total),
    ));
  }

  final bytes = await doc.save();
  return PdfBuildResult(Uint8List.fromList(bytes), total);
}

pw.Widget _buildSheetPage(
    Worksheet sheet, List<Question> qs, int idx, int total) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      // ---------- 标题 ----------
      pw.Text(
        '小学数学口算练习卷',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 6 * _mm, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 3 * _mm),

      // ---------- 页眉：姓名 / 日期 / 用时 / 得分 ----------
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          '姓名：____________',
          '日期：____________',
          '用时：________',
          '得分：________',
        ]
            .map((t) => pw.Text(t, style: pw.TextStyle(fontSize: 3.3 * _mm)))
            .toList(),
      ),
      pw.SizedBox(height: 2 * _mm),

      // ---------- 副标题（下带一条细分隔线） ----------
      pw.Container(
        padding: pw.EdgeInsets.only(bottom: 2 * _mm),
        child: pw.Text(
          '${sheet.gradeLabel} · 共 $kPerPage 题 · 每题 ${sheet.score} 分 · 满分 ${sheet.fullScore} 分',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 3 * _mm),
        ),
      ),
      pw.Container(height: 0.3 * _mm, color: PdfColors.grey800),
      pw.SizedBox(height: 2 * _mm),

      // ---------- 5 列 × 25 行网格 ----------
      pw.Table(
        border: pw.TableBorder.all(width: 0.2 * _mm, color: PdfColors.grey400),
        columnWidths: {
          for (var c = 0; c < kCols; c++) c: const pw.FlexColumnWidth(),
        },
        children: List.generate(kRows, (r) {
          return pw.TableRow(
            children: List.generate(kCols, (c) {
              final q = qs[r * kCols + c];
              return _questionCell(q);
            }),
          );
        }),
      ),
      pw.SizedBox(height: 2 * _mm),

      // ---------- 页脚 ----------
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('小学数学出题 · 口算题卡',
              style:
                  pw.TextStyle(fontSize: 2.9 * _mm, color: PdfColors.grey700)),
          pw.Text('第 ${idx + 1} 页 / 共 $total 页',
              style:
                  pw.TextStyle(fontSize: 2.9 * _mm, color: PdfColors.grey700)),
        ],
      ),
    ],
  );
}

/// 单个题目格：算式 + 答案横线（填空题不加）
/// 行高 9.6mm × 25 行 = 240mm，加上标题/页眉/页脚仍留有余量，
/// 避免 pw.Page（非 MultiPage）因内容超高而抛 "won't fit" 错误。
pw.Widget _questionCell(Question q) {
  return pw.Container(
    height: 9.6 * _mm,
    padding: pw.EdgeInsets.only(left: 1.6 * _mm),
    alignment: pw.Alignment.centerLeft,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(q.expr, style: pw.TextStyle(fontSize: 3.2 * _mm)),
        if (!q.isFillBlank)
          // 答案横线：一段贴文字基线的细线，宽 7mm，紧跟算式之后
          pw.Container(
            margin: pw.EdgeInsets.only(left: 1 * _mm, top: 1.1 * _mm),
            width: 7 * _mm,
            height: 0.28 * _mm,
            color: PdfColors.grey900,
          ),
      ],
    ),
  );
}
