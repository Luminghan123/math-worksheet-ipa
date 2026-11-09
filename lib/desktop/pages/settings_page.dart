import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../state/app_state.dart';
import '../save_windows.dart';

/// 桌面「设置」页：保存 PDF（系统另存为）、数据管理、关于。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int? _saveId;
  String? _msg;
  InfoBarSeverity _severity = InfoBarSeverity.info;

  Future<void> _clear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('清空历史试卷'),
        content: const Text(
          '将删除本机保存的全部试卷（最多 12 份），且不可恢复。'
          '已导出到本地的 PDF 不受影响。',
        ),
        actions: [
          Button(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          FilledButton(
            child: const Text('清空'),
            onPressed: () async {
              await context.read<AppState>().clearAllHistory();
              if (mounted) Navigator.pop(ctx, true);
            },
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _saveId = null);
    }
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final sheet = state.history
        .where((h) => h.id == _saveId)
        .cast<Worksheet>()
        .toList();
    if (sheet.isEmpty) return;
    final ok = await saveSheetToDisk(sheet.first);
    if (!mounted) return;
    setState(() {
      _msg = ok ? '已保存 PDF 到所选位置' : '已取消保存';
      _severity = ok ? InfoBarSeverity.success : InfoBarSeverity.info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final effectiveId = _saveId ?? state.currentSheet?.id;
    final canSave =
        effectiveId != null && state.history.any((h) => h.id == effectiveId);

    return ScaffoldPage(
      header: const PageHeader(title: Text('设置')),
      content: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: SizedBox(
            width: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_msg != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoBar(title: Text(_msg!), severity: _severity),
                  ),
                Card(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('保存 PDF',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 6),
                      const Text(
                        '选择一份试卷，点「保存」会弹出系统「另存为」对话框，'
                        '你自己选文件名与位置，App 不会在电脑里新建任何文件夹。',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ComboBox<int>(
                              placeholder: const Text('选择试卷'),
                              value: canSave ? effectiveId : null,
                              items: state.history
                                  .map((h) => ComboBoxItem<int>(
                                      value: h.id, child: Text(h.name)))
                                  .toList(),
                              onChanged: (v) => setState(() => _saveId = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            child: const Text('保存到本地'),
                            onPressed: canSave ? () => _save() : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('数据管理',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 6),
                      const Text('历史试卷只保存在本机（最多 12 份），'
                          '不上传、不写系统目录。'),
                      const SizedBox(height: 12),
                      Button(
                        child: const Text('清空全部历史'),
                        onPressed: () => _clear(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('关于',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      SizedBox(height: 6),
                      Text('口算题卡 v2.0 · Flutter 桌面版'),
                      SizedBox(height: 4),
                      Text('按年级收敛知识点，A4 每页 125 题（5 列 × 25 行），'
                          '含 0 运算与填空题。'),
                      SizedBox(height: 4),
                      Text('保存方式：Windows 系统「另存为」对话框'
                          '（不建文件夹、不留临时文件）。'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
