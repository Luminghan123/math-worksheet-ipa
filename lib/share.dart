import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import 'models.dart';
import 'pdf/worksheet_pdf.dart';

/// ---------------------------------------------------------------------------
/// 保存到本地：完全照搬参考软件（呼吸治疗记录）的下载逻辑
///
///   await Printing.sharePdf(bytes: result.bytes, filename: filename);
///
/// PDF 在内存里生成 → 直接交给 iOS 系统分享面板 → 用户选「存储到文件」
/// 自己决定存哪，也能发到微信 / 邮箱 / 别的应用。
///
/// App 不往 Documents 写文件、不开 UIFileSharingEnabled、
/// 不在「文件」App 里新建任何文件夹。临时中转由系统分享面板自己管理。
/// ---------------------------------------------------------------------------

/// 生成整卷 PDF 的字节（供分享与预览共用）
Future<PdfBuildResult> buildSheetPdf(Worksheet sheet) async {
  final data = await rootBundle.load('assets/fonts/WorksheetCJK.ttf');
  final fontBytes = data.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );
  return buildWorksheetPdf(sheet, fontBytes);
}

/// 文件名：试卷_二年级下_2页.pdf
String sheetFileName(Worksheet sheet) =>
    '试卷_${sheet.gradeLabel}_${sheet.pages.length}页.pdf';

/// 调起系统分享面板（复用已生成的 PDF 字节，避免重复渲染）
Future<void> sharePdfBytes(Worksheet sheet, PdfBuildResult result) async {
  await Printing.sharePdf(
    bytes: result.bytes,
    filename: sheetFileName(sheet),
  );
}

/// 一步到位：生成 + 分享（预览页用）
Future<void> shareSheet(Worksheet sheet) async {
  final result = await buildSheetPdf(sheet);
  await sharePdfBytes(sheet, result);
}

/// 供设置页展示的字节大小文案
String humanSize(int n) {
  if (n < 1024) return '$n B';
  if (n < 1048576) return '${(n / 1024).round()} KB';
  return '${(n / 1048576).toStringAsFixed(1)} MB';
}
