import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../engine.dart';
import '../models.dart';
import '../share.dart';
import '../state/app_state.dart';

/// 预览页：A4 试卷缩略图 + 翻页 / 换一批 + 右上「保存」
class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sheet = state.currentSheet;
    if (sheet == null) {
      // 没有当前试卷时回到首页
      WidgetsBinding.instance
          .addPostFrameCallback((_) => state.go(PageId.home));
      return const Scaffold(body: SizedBox.shrink());
    }
    final total = sheet.pages.length;
    final page = state.currentPage.clamp(1, total);
    final qs = sheet.pages[page - 1];

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => state.go(PageId.home),
          child: const Text('‹ 返回',
              style: TextStyle(
                  fontSize: 15, color: kBrand, fontWeight: FontWeight.w600)),
        ),
        title: Text('$page / $total'),
        leadingWidth: 80,
        actions: [
          TextButton(
            onPressed: state.busy ? null : () => _save(context, state, sheet),
            child: Text(state.busy ? '生成中…' : '保存',
                style: const TextStyle(
                    fontSize: 15, color: kBrand, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ---------- 工具栏 ----------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                _tool('‹ 上一页', state.prevPage),
                const SizedBox(width: 8),
                _tool('换一批', () => state.reshuffle()),
                const SizedBox(width: 8),
                _tool('下一页 ›', state.nextPage),
              ],
            ),
          ),
          // ---------- 试卷 ----------
          Expanded(
            child: Container(
              color: const Color(0xFFE7ECF5),
              padding: const EdgeInsets.all(14),
              alignment: Alignment.topCenter,
              child: LayoutBuilder(
                builder: (context, c) {
                  return FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 794,
                      height: 1123,
                      child: _SheetView(
                          sheet: sheet, qs: qs, idx: page - 1, total: total),
                    ),
                  );
                },
              ),
            ),
          ),
          // ---------- 底部说明 ----------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
            color: Colors.white,
            child: const Text(
              'A4 210 × 297 mm · 每页 125 题（5 列 × 25 行）\n'
              '点右上「保存」调起系统分享面板，选「存储到文件」即可把整卷 PDF 存到你选的位置',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: kInk3, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(
      BuildContext context, AppState state, Worksheet sheet) async {
    state.setBusy(true, '正在生成 PDF…');
    try {
      await shareSheet(sheet);
      state.setBusy(false);
      state.setStatus(
          '已调起系统分享面板。选「存储到文件」即可保存整卷 PDF；也可直接发到微信、邮箱。App 不会在手机里新建文件夹。');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已打开系统分享面板')),
        );
      }
    } catch (e) {
      state.setBusy(false);
      state.setStatus('分享失败：$e', true);
    }
  }

  Widget _tool(String label, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: kBg,
                border: Border.all(color: kLine),
                borderRadius: BorderRadius.circular(10)),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: kInk2)),
          ),
        ),
      );
}

/// 逻辑像素 794 × 1123 的 A4 纸张（由 FittedBox 缩放）
class _SheetView extends StatelessWidget {
  final Worksheet sheet;
  final List<Question> qs;
  final int idx;
  final int total;
  const _SheetView({
    required this.sheet,
    required this.qs,
    required this.idx,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 794,
      height: 1123,
      padding: const EdgeInsets.fromLTRB(42, 38, 42, 30),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('小学数学口算练习卷',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111))),
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
          // 5 列 × 25 行网格
          Expanded(
            child: Table(
              border:
                  TableBorder.all(width: 0.6, color: const Color(0xFFD8D8D8)),
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
                            Text(q.expr,
                                style: const TextStyle(
                                    fontSize: 12.5, color: Color(0xFF111111))),
                            if (!q.isFillBlank)
                              Container(
                                margin: const EdgeInsets.only(left: 4, top: 7),
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
              Text('第 ${idx + 1} 页 / 共 $total 页',
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF666666))),
            ],
          ),
        ],
      ),
    );
  }
}
