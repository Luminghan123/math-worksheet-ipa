import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../engine.dart';
import '../../models.dart';
import '../../state/app_state.dart';
import '../save_windows.dart';
import '../widgets/sheet_preview.dart';

/// 桌面「出题」页：左侧配置（年级 / 范围 / 题型比例 / 页数 / 分值），右侧 A4 预览 + 工具栏。
class GeneratePage extends StatefulWidget {
  const GeneratePage({super.key});

  @override
  State<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends State<GeneratePage> {
  String? _msg;
  InfoBarSeverity _severity = InfoBarSeverity.info;

  Future<void> _save(BuildContext context, Worksheet sheet) async {
    setState(() => _msg = null);
    final ok = await saveSheetToDisk(sheet);
    if (!mounted) return;
    setState(() {
      _msg = ok ? '已保存：PDF 写入你选择的位置' : '已取消保存';
      _severity = ok ? InfoBarSeverity.success : InfoBarSeverity.info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rule = gradeById(state.grade);
    final capOptions =
        [10, 20, 100, 1000].where((n) => n <= rule.max).toList();
    final sheet = state.currentSheet;
    final total = sheet?.pages.length ?? 0;
    final idx = total == 0 ? 1 : state.currentPage.clamp(1, total);

    return ScaffoldPage(
      header: const PageHeader(title: Text('出题')),
      content: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_msg != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InfoBar(title: Text(_msg!), severity: _severity),
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: _configCard(state, rule, capOptions),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 3,
                    child: _previewCard(state, sheet, idx),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _configCard(
    AppState state,
    GradeRule rule,
    List<int> capOptions,
  ) {
    final effectiveCap =
        capOptions.contains(state.cap) ? state.cap : capOptions.last;
    return Card(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('年级', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ComboBox<String>(
            value: state.grade,
            items: kGradeRules
                .map((g) =>
                    ComboBoxItem<String>(value: g.id, child: Text(g.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) state.setGrade(v);
            },
          ),
          const SizedBox(height: 6),
          Text(rule.note, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 16),
          const Text('数值范围（以内）',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ComboBox<int>(
            value: effectiveCap,
            items: capOptions
                .map((n) =>
                    ComboBoxItem<int>(value: n, child: Text('$n 以内')))
                .toList(),
            onChanged: (v) {
              if (v != null) state.setCap(v);
            },
          ),
          const SizedBox(height: 16),
          const Text('题型比例（合计 100%）',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...kAllTypes.map((t) => _typeRow(state, t)).toList(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('页数',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    NumberBox<int>(
                      value: state.pages,
                      min: 1,
                      max: 5,
                      onChanged: (v) {
                        if (v != null) {
                          state.pages = v;
                          state.notifyListeners();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('每题分值',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    NumberBox<int>(
                      value: state.score,
                      min: 1,
                      max: 10,
                      onChanged: (v) {
                        if (v != null) {
                          state.score = v;
                          state.notifyListeners();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton(
            child: const Text('生成试卷'),
            onPressed: state.busy
                ? null
                : () async {
                    await state.generateSheet();
                  },
          ),
        ],
      ),
    );
  }

  Widget _typeRow(AppState state, String t) {
    final on = state.types.contains(t);
    final w = state.weights[t] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: ToggleSwitch(
              checked: on,
              content: Text(t),
              onChanged: (_) => state.toggleType(t),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: NumberBox<int>(
              value: on ? w : 0,
              min: 5,
              max: 90,
              onChanged: (v) {
                if (v != null && on) state.adjustWeight(t, v - w);
              },
            ),
          ),
          const Text(' %', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _previewCard(AppState state, Worksheet? sheet, int idx) {
    return Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('预览', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (sheet != null) ...[
                Button(
                  child: const Text('上一页'),
                  onPressed: state.prevPage,
                ),
                const SizedBox(width: 8),
                Button(
                  child: const Text('换一批'),
                  onPressed: () => state.reshuffle(),
                ),
                const SizedBox(width: 8),
                Button(
                  child: const Text('下一页'),
                  onPressed: state.nextPage,
                ),
                const SizedBox(width: 8),
                FilledButton(
                  child: const Text('保存到本地'),
                  onPressed: () => _save(context, sheet),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              color: const Color(0xFFE7ECF5),
              padding: const EdgeInsets.all(14),
              alignment: Alignment.topCenter,
              child: sheet == null
                  ? const Center(
                      child: Text('点左侧「生成试卷」后，这里会显示 A4 预览'),
                    )
                  : LayoutBuilder(
                      builder: (c, _) => FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        child: SheetPreview(
                          sheet: sheet,
                          pageIndex: idx - 1,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
