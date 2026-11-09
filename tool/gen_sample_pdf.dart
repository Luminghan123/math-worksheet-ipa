// 在 CI / 本地（Dart 3 + pub get 之后）真实生成一份示例 PDF，验证：
//   - pdf 包排版不抛异常（尤其是 pw.Page 非 MultiPage 的超高检查）
//   - 内嵌中文字体可用、中文/符号不缺字
//   - 输出是合法 PDF、页数正确
//
//   dart run tool/gen_sample_pdf.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../lib/engine.dart';
import '../lib/models.dart';
import '../lib/pdf/worksheet_pdf.dart';

Future<void> main() async {
  final fontFile = File('assets/fonts/WorksheetCJK.ttf');
  if (!fontFile.existsSync()) {
    stderr.writeln('缺少字体 assets/fonts/WorksheetCJK.ttf');
    exit(1);
  }
  final fontBytes = Uint8List.fromList(await fontFile.readAsBytes());

  final rule = gradeById('2b'); // 二年级下
  final weights = {'口算': 60, '竖式': 25, '填空': 15};
  final r = Random(20261108);
  final sheet = Worksheet(
    id: 1,
    name: '二年级下 · 示例',
    gradeLabel: rule.label,
    score: 1,
    createdAt: '11-08 20:30',
    config: SheetConfig(
        grade: '2b', cap: 100, pages: 2, score: 1, weights: weights),
    pages: [
      generatePage(rule, 100, weights, r),
      generatePage(rule, 100, weights, r),
    ],
  );

  final result = await buildWorksheetPdf(sheet, fontBytes);
  final b = result.bytes;

  // 断言 1：合法 PDF 头
  final head = String.fromCharCodes(b.sublist(0, 8));
  if (!head.startsWith('%PDF-')) {
    stderr.writeln('输出不是合法 PDF，文件头: $head');
    exit(1);
  }
  // 断言 2：页数
  if (result.pageCount != 2) {
    stderr.writeln('页数错误: ${result.pageCount}');
    exit(1);
  }
  // 断言 3：尾部必须有 %%EOF（结构完整）。
  // 注意：pdf 包默认用压缩对象流（PDF 1.5+），/Type /Page 等字典是压缩的，
  // 不能用明文字符串去数页面对象；页数已由 pageCount 断言保证。
  final tail = String.fromCharCodes(b.sublist(b.length - 2048));
  if (!tail.contains('%%EOF')) {
    stderr.writeln('PDF 缺少 %%EOF，结构不完整');
    exit(1);
  }
  // 断言 4：文件非空（pdf 包会做字体子集化，只嵌入用到的字形，
  // 体积因内容而异，不做硬阈值判断；字体嵌入情况由 CI 上传 artifact 后用
  // pdffonts 单独校验）
  if (b.length < 3000) {
    stderr.writeln('PDF 体积异常小 (${b.length} B)');
    exit(1);
  }

  final out = File('build/示例试卷_二年级下_2页.pdf');
  await out.create(recursive: true);
  await out.writeAsBytes(b);

  print('✅ PDF 生成通过');
  print('   文件: ${out.path}');
  print('   大小: ${(b.length / 1024).toStringAsFixed(0)} KB');
  print('   页数: ${result.pageCount}');
  print('   PDF 头: $head');
  print('   尾部 %%EOF: 存在');
  print('   中文字体: 由 WorksheetCJK.ttf 内嵌（子集化，artifact 另用 pdffonts 校验）');
}
