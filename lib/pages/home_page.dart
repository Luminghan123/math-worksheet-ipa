import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../engine.dart';
import '../models.dart';
import '../state/app_state.dart';

/// 首页：大标题 + 渐变 Hero + 历史试卷列表
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final h = state.history;
    final totalQ = h.fold<int>(0, (s, x) => s + x.totalQuestions);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ---------- 顶部标题 + 设置 / 新建 ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('我的试卷',
                            style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                height: 1.15,
                                color: kInk)),
                        SizedBox(height: 3),
                        Text('小学数学 · 口算题卡',
                            style: TextStyle(
                                fontSize: 12,
                                color: kInk3,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  _circleBtn(
                      Icons.settings_outlined, () => state.go(PageId.settings),
                      filled: false),
                  const SizedBox(width: 9),
                  _circleBtn(Icons.add, () => state.go(PageId.config),
                      filled: true),
                ],
              ),
            ),

            // ---------- 渐变 Hero ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
                decoration: BoxDecoration(
                  gradient: kGrad,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x4D4C63E6),
                        blurRadius: 26,
                        offset: Offset(0, 10))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -42,
                        top: -58,
                        child: _bubble(150),
                      ),
                      Positioned(
                        right: 24,
                        bottom: -52,
                        child: _bubble(96),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DAILY PRACTICE',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: Colors.white70)),
                          const SizedBox(height: 5),
                          const Text('今天给孩子练一练？',
                              style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          const SizedBox(height: 5),
                          const Text('按年级自动出题，A4 每页 125 题\n生成后一键分享、保存到本地打印',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  height: 1.6)),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              _stat('${h.length}', '份试卷'),
                              const SizedBox(width: 10),
                              _stat('$totalQ', '道题'),
                              const SizedBox(width: 10),
                              _stat('$kPerPage', '题 / 页'),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF3F55D6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => state.go(PageId.config),
                              child: const Text('＋ 新建试卷',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ---------- 语文生字入口（V2 新增） ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: GestureDetector(
                onTap: () => state.go(PageId.word),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE6EAF5)),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0D203060),
                          blurRadius: 14,
                          offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: const Text('字',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF7B5BEA))),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('语文生字练习',
                                style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: kInk)),
                            SizedBox(height: 3),
                            Text('田字格 + 四线三格 · 练写字 / 练拼音',
                                style: TextStyle(
                                    fontSize: 11.5, color: kInk3)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 20, color: Color(0xFFC7CEDC)),
                    ],
                  ),
                ),
              ),
            ),

            // ---------- 历史试卷 ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('历史试卷',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                  Text(h.isEmpty ? '暂无' : '共 ${h.length} 份',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kInk3)),
                ],
              ),
            ),
            Expanded(
              child: h.isEmpty
                  ? const _Empty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: h.length,
                      itemBuilder: (ctx, i) => _SheetCard(sheet: h[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0x1CFFFFFF),
          shape: BoxShape.circle,
        ),
      );

  Widget _stat(String num, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
              color: const Color(0x29FFFFFF),
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(num,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70)),
            ],
          ),
        ),
      );

  Widget _circleBtn(IconData icon, VoidCallback onTap, {required bool filled}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: filled ? kGrad : null,
          color: filled ? null : Colors.white,
          border: filled ? null : Border.all(color: kLine),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D203060), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon,
            size: filled ? 22 : 19, color: filled ? Colors.white : kBrand),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(color: Color(0x12002060), blurRadius: 22)
                  ]),
              alignment: Alignment.center,
              child: const Text('123',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: kBrand)),
            ),
            const SizedBox(height: 16),
            const Text('还没有试卷',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 7),
            const Text('选好年级、题型和页数\n一键生成每页 125 题的 A4 口算题卡',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: kInk3, height: 1.75)),
          ],
        ),
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  final Worksheet sheet;
  const _SheetCard({required this.sheet});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return GestureDetector(
      onTap: () => state.openSheet(sheet.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x12002060),
                  blurRadius: 22,
                  offset: Offset(0, 6))
            ]),
        child: Row(
          children: [
            // 试卷缩略图
            Container(
              width: 46,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE3E8F2)),
                  borderRadius: BorderRadius.circular(7)),
              child: Column(
                children: List.generate(9, (i) {
                  return Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 2),
                    width: i % 3 == 2 ? 28 : double.infinity,
                    color: i == 0
                        ? const Color(0xFFB9C6E6)
                        : const Color(0xFFDDE4F0),
                  );
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sheet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                  const SizedBox(height: 5),
                  Text(
                      '${sheet.gradeLabel} · ${sheet.pages.length} 页 · ${sheet.totalQuestions} 题',
                      style: const TextStyle(fontSize: 12, color: kInk2)),
                  const SizedBox(height: 5),
                  Text('${sheet.createdAt} · 每题 ${sheet.score} 分',
                      style: const TextStyle(fontSize: 11, color: kInk3)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _confirmDelete(context, state),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                        color: kDangerSoft,
                        borderRadius: BorderRadius.circular(7)),
                    child: const Text('删除',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kDanger)),
                  ),
                ),
                const SizedBox(height: 9),
                const Icon(Icons.chevron_right,
                    size: 20, color: Color(0xFFC7CEDC)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('删除这份试卷？'),
        content: const Text('删除后本机历史里将不再显示这份试卷。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('删除', style: TextStyle(color: kDanger))),
        ],
      ),
    );
    if (ok == true) await state.delSheet(sheet.id);
  }
}
