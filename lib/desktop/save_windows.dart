import 'dart:io';

import 'package:file_selector/file_selector.dart';

import '../models.dart';
import '../share.dart';

/// ---------------------------------------------------------------------------
/// Windows 保存：调起系统「另存为」对话框，把 PDF 字节直接写到用户选定路径。
///
/// 与 iOS 的 Printing.sharePdf（系统分享面板）不同，桌面端用 file_selector 更贴合
/// Windows 习惯：用户自己选文件名与位置，App 不写任何默认目录、不留临时文件。
/// ---------------------------------------------------------------------------

/// 生成 PDF 字节并弹出系统「另存为」，成功返回 true；用户取消返回 false。
Future<bool> saveSheetToDisk(Worksheet sheet) async {
  final result = await buildSheetPdf(sheet); // 内存里生成 PDF 字节
  final location = await getSaveLocation(
    suggestedName: sheetFileName(sheet),
    acceptedTypeGroups: const [
      XTypeGroup(label: 'PDF 文档', extensions: ['pdf']),
    ],
  );
  if (location == null) return false;
  final file = File(location.path);
  await file.writeAsBytes(result.bytes, flush: true);
  return true;
}
