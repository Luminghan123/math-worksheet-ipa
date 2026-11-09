import 'package:flutter/material.dart';

import '../../engine.dart';
import '../../models.dart';

/// A4 试卷预览（逻辑像素 794 × 1123，由外层 FittedBox 缩放）。
/// 桌面端出题 / 历史页共用，绘制规则与最终 PDF 一致：
/// 5 列 × 25 行网格，普通题后带贴底横线，含 □ 的填空题不再追加横线。
class SheetPreview extends StatelessWidget {
  final Worksheet sheet;
  final int pageIndex; // 0-based

  const SheetPreview({
    super.key,
    required this.sheet,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final total = sheet.pages.length;
    final page = pageIndex.clamp(0, total - 1);
    final qs = sheet.pages[page];
    return Container(
      width: 794,
      height: 1123,
      padding: const EdgeInsets.fromLTRB(42, 38, 42, 30),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '小学数学口算练习卷',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('姓名：____________', style: TextStyle(fontSize: 12.5)),
              Text('日期：____________', style: TextStyle(fontSize: 12.5)),
              Text('用时：________', style: TextStyle(fontSize: 12.5)),
              Text('得分：________', style: TextStyle(fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${sheet.gradeLabel} · 共 $kPerPage 题 · 每题 ${sheet.score} 分 · 满分 ${sheet.fullScore} 分',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFF333333)),
          const SizedBox(height: 8),
          Expanded(
            child: Table(
              border: TableBorder.all(
                width: 0.6,
                color: const Color(0xFFD8D8D8),
              ),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
              },
              children: List.generate(kRows, (r) {
                return TableRow(
                  children: List.generate(kCols, (c) {
                    final q = qs[r * kCols + c];
                    return SizedBox(
                      height: 34,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              q.expr,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF111111),
                              ),
                            ),
                            if (!q.isFillBlank)
                              Container(
                                margin:
                                    const EdgeInsets.only(left: 4, top: 7),
                                width: 26,
                                height: 1.2,
                                color: const Color(0xFF333333),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('小学数学出题 · 口算题卡',
                  style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
              Text('第 ${page + 1} 页 / 共 $total 页',
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF666666))),
            ],
          ),
        ],
      ),
    );
  }
}
