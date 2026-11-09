import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import 'word_models.dart';
import 'word_pdf.dart';

/// ---------------------------------------------------------------------------
/// 生字练习卷：生成 PDF 字节 / 文件名 / 系统分享面板（iOS、Android）
/// 与口算卷 share.dart 完全平行的实现，只是换用扩展字体和 word_pdf 生成器。
/// ---------------------------------------------------------------------------

/// 生成整卷 PDF 字节（供分享、预览、桌面另存共用）
///
/// 扩展字体以 base64 文本（WorksheetCJK_Ext.ttf.b64）随源码入库，运行时解码成
/// 字节再交给 pdf 包：这样工程不依赖二进制字体文件，纯文本通道也能完整同步。
/// （口算卷用的 WorksheetCJK.ttf 仍是二进制，早已随仓库提交。）
Future<WordPdfBuildResult> buildWordSheetPdf(WordSheet sheet) async {
  final encoded =
      await rootBundle.loadString('assets/fonts/WorksheetCJK_Ext.ttf.b64');
  final fontBytes = base64Decode(encoded.trim());
  return buildWordPdf(sheet, fontBytes);
}

/// 文件名：生字卷_一年级上_练写字_2页.pdf
String wordSheetFileName(WordSheet sheet) =>
    '生字卷_${sheet.gradeLabel}_${sheet.mode == kModeWriteChar ? "练写字" : "练拼音"}_'
    '${sheet.pages.length}页.pdf';

/// 调起系统分享面板（复用已生成的 PDF 字节）
Future<void> shareWordPdfBytes(
    WordSheet sheet, WordPdfBuildResult result) async {
  await Printing.sharePdf(
    bytes: result.bytes,
    filename: wordSheetFileName(sheet),
  );
}

/// 一步到位：生成 + 分享（移动端预览页用）
Future<void> shareWordSheet(WordSheet sheet) async {
  final result = await buildWordSheetPdf(sheet);
  await shareWordPdfBytes(sheet, result);
}
