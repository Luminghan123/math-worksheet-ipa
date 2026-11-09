import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../state/app_state.dart';
import '../save_windows.dart';
import '../widgets/sheet_preview.dart';

/// 桌面「历史试卷」页：左侧本机试卷列表，右侧预览 + 换一批 / 保存到本地。
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int? _selectedId;
  String? _msg;
  InfoBarSeverity _severity = InfoBarSeverity.info;

  Future<void> _save(Worksheet sheet) async {
    final ok = await saveSheetToDisk(sheet);
    if (!mounted) return;
    setState(() {
      _msg = ok ? '已保存 PDF 到所选位置' : '已取消保存';
      _severity = ok ? InfoBarSeverity.success : InfoBarSeverity.info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sheet = state.history
        .where((h) => h.id == _selectedId)
        .cast<Worksheet>()
        .toList();
    final current = sheet.isNotEmpty ? sheet.first : null;
    final previewPage = current == null
        ? 0
        : (state.currentPage - 1).clamp(0, current.pages.length - 1);

    return ScaffoldPage(
      header: const PageHeader(title: Text('历史试卷')),
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
                    child: Card(
                      padding: const EdgeInsets.all(8),
                      child: state.history.isEmpty
                          ? const Center(
                              child: Text('还没有试卷，去「出题」页生成一份吧'),
                            )
                          : ListView.builder(
                              itemCount: state.history.length,
                              itemBuilder: (c, i) {
                                final h = state.history[i];
                                final active = h.id == _selectedId;
                                return _item(state, h, active);
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 3,
                    child: Card(
                      padding: const EdgeInsets.all(12),
                      child: current == null
                          ? const Center(
                              child: Text('从左侧选择一份试卷查看预览'),
                            )
                          : Column(
                              children: [
                                Row(
                                  children: [
                                    const Text('预览',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    Button(
                                      child: const Text('换一批'),
                                      onPressed: () => state.reshuffle(),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      child: const Text('保存到本地'),
                                      onPressed: () => _save(current),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: Container(
                                    color: const Color(0xFFE7ECF5),
                                    padding: const EdgeInsets.all(14),
                                    alignment: Alignment.topCenter,
                                    child: LayoutBuilder(
                                      builder: (c, _) => FittedBox(
                                        fit: BoxFit.contain,
                                        alignment: Alignment.topCenter,
                                        child: SheetPreview(
                                          sheet: current,
                                          pageIndex: previewPage,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(AppState state, Worksheet h, bool active) {
    final theme = FluentTheme.of(context);
    final accent = theme.accentColor.defaultBrushFor(theme.brightness);
    return GestureDetector(
      onTap: () {
        setState(() => _selectedId = h.id);
        state.selectSheet(h.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? accent.withOpacity(0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${h.gradeLabel} · ${h.pages.length} 页 · 满分 ${h.fullScore} 分 · ${h.createdAt}',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(FluentIcons.delete),
              onPressed: () async {
                await state.delSheet(h.id);
                if (_selectedId == h.id) {
                  setState(() => _selectedId = null);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
