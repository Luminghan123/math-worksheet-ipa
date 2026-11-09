import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../engine.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// 新建试卷：配置页
class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rule = gradeById(state.grade);
    final counts = state.typeCounts;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => state.go(PageId.home),
          child: const Text('‹ 返回',
              style: TextStyle(
                  fontSize: 15, color: kBrand, fontWeight: FontWeight.w600)),
        ),
        title: const Text('新建试卷'),
        leadingWidth: 80,
        actions: const [SizedBox(width: 56)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                // ---------- 1 年级与知识点 ----------
                GroupCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GroupHead(badge: '1', title: '年级与知识点', tag: '不超纲'),
                      const HintText('切换年级会自动收敛可用运算，避免出超纲题。'),
                      FormRow(
                        label: '年级 / 学期',
                        child: _dropdown(
                          value: state.grade,
                          items: [
                            for (final g in kGradeRules)
                              DropdownMenuItem(
                                  value: g.id, child: Text(g.label))
                          ],
                          onChanged: (v) {
                            if (v != null) state.setGrade(v);
                          },
                        ),
                      ),
                      FormRow(
                        label: '本阶段知识点',
                        child: SizedBox(
                          width: 190,
                          child: Text(rule.note,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kBrand,
                                  height: 1.45)),
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------- 2 题型组合 ----------
                GroupCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GroupHead(
                          badge: '2', title: '题型组合', tag: '合计 125 题'),
                      const HintText(
                          '竖式题以横式呈现，孩子在草稿纸列竖式；填空题答案写在 □ 内，不再另加横线；比例合计 100%。'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in kAllTypes)
                            ChipButton(
                              label: t,
                              selected: state.types.contains(t),
                              onTap: () => state.toggleType(t),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final t in state.types)
                        _WeightRow(
                          label: t,
                          count: counts[t] ?? 0,
                          percent: state.weights[t] ?? 0,
                          onMinus: () => state.adjustWeight(t, -5),
                          onPlus: () => state.adjustWeight(t, 5),
                        ),
                    ],
                  ),
                ),

                // ---------- 3 题量与难度 ----------
                GroupCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GroupHead(
                        badge: '3',
                        title: '题量与难度',
                        badgeColor: kAccent,
                        badgeBg: Color(0xFFFFF1E6),
                      ),
                      const HintText('每页固定 125 题（5 列 × 25 行），题量按页数计算。'),
                      FormRow(
                        label: '页数',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NumberStepper(
                                value: state.pages,
                                onMinus: () => state.stepPages(-1),
                                onPlus: () => state.stepPages(1)),
                            const SizedBox(width: 8),
                            Text('共 ${state.pages * kPerPage} 题',
                                style: const TextStyle(
                                    fontSize: 12, color: kInk3)),
                          ],
                        ),
                      ),
                      FormRow(
                        label: '数值范围',
                        child: _dropdown(
                          value: state.cap,
                          items: [
                            for (final v in const [10, 20, 100, 1000])
                              DropdownMenuItem(value: v, child: Text('$v 以内'))
                          ],
                          onChanged: (v) {
                            if (v != null) state.setCap(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------- 4 分值与页眉 ----------
                GroupCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GroupHead(
                        badge: '4',
                        title: '分值与页眉',
                        badgeColor: kOk,
                        badgeBg: kOkSoft,
                      ),
                      const HintText('页眉固定含姓名 / 日期 / 用时 / 得分栏，满分按分值自动计算。'),
                      FormRow(
                        label: '每题分值',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NumberStepper(
                                value: state.score,
                                onMinus: () => state.stepScore(-1),
                                onPlus: () => state.stepScore(1)),
                            const SizedBox(width: 8),
                            Text('满分 ${kPerPage * state.score} 分',
                                style: const TextStyle(
                                    fontSize: 12, color: kInk3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: Text(
                    '题目含 0 参与的运算（每页至少 10 道，如 0 + 5、8 − 0、0 × 8、0 ÷ 6）。\n'
                    '本版不含参考答案页，也不做手机做题判分。',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 11.5, color: kInk3, height: 1.75),
                  ),
                ),
              ],
            ),
          ),
          FooterBar(
            child: GradientButton(
              label: '生成试卷',
              icon: Icons.auto_stories_outlined,
              onTap: () async {
                await state.generateSheet();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: kBg,
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(10)),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        isDense: true,
        alignment: AlignmentDirectional.centerEnd,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: kInk),
        icon: const Icon(Icons.arrow_drop_down, color: kBrand, size: 20),
      ),
    );
  }
}

/// 题型权重行：题型名 + 题量 + − 百分比 +
class _WeightRow extends StatelessWidget {
  final String label;
  final int count;
  final int percent;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _WeightRow({
    required this.label,
    required this.count,
    required this.percent,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: kLine, width: 1))),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
          const SizedBox(width: 7),
          Text('$count 题', style: const TextStyle(fontSize: 12, color: kInk3)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
                color: kBg, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                _mini('−', onMinus),
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text('$percent%',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kBrand)),
                  ),
                ),
                _mini('+', onPlus),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mini(String t, VoidCallback cb) => InkWell(
        onTap: cb,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(7)),
          alignment: Alignment.center,
          child: Text(t, style: const TextStyle(fontSize: 15, color: kBrand)),
        ),
      );
}
