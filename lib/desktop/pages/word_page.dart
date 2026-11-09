import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../chinese/grid_preview.dart';
import '../../chinese/word_bank.dart';
import '../../chinese/word_models.dart'
    show kModeWriteChar, kModeWritePinyin, modeLabel, WordSheet;
import '../../chinese/word_state.dart';
import '../save_windows.dart';

/// 桌面「语文生字」页：左侧配置 + 最近练习卷，右侧 A4 预览（田字格 + 四线三格）+ 工具栏。
class WordPage extends StatefulWidget {
  const WordPage({super.key});

  @override
  State<WordPage> createState() => _WordPageState();
}

class _WordPageState extends State<WordPage> {
  final TextEditingController _customCtrl = TextEditingController();
  String? _msg;
  InfoBarSeverity _severity = InfoBarSeverity.info;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(WordState st) async {
    final sheet = st.currentSheet;
    if (sheet == null) return;
    setState(() => _msg = null);
    try {
      final ok = await saveWordSheetToDisk(sheet);
      if (!mounted) return;
      setState(() {
        _msg = ok ? '已保存：生字练习卷 PDF 写入你选择的位置' : '已取消保存';
        _severity = ok ? InfoBarSeverity.success : InfoBarSeverity.info;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _msg = '保存失败：$e';
        _severity = InfoBarSeverity.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<WordState>();
    final sheet = st.currentSheet;
    final total = sheet?.pages.length ?? 0;
    final idx = total == 0 ? 1 : st.currentPage.clamp(1, total);

    return ScaffoldPage(
      header: const PageHeader(title: Text('语文生字')),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _configCard(st),
                          const SizedBox(height: 14),
                          _historyCard(st),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 3,
                    child: _previewCard(st, sheet, idx),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _configCard(WordState st) {
    return Card(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('年级 / 册',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ComboBox<String>(
            value: st.grade,
            isExpanded: true,
            items: HanziBank.gradeIds
                .map((id) => ComboBoxItem<String>(
                    value: id, child: Text(HanziBank.labelOf(id))))
                .toList(),
            onChanged: (v) {
              if (v != null) st.setGrade(v);
            },
          ),
          const SizedBox(height: 6),
          Text(st.poolLabel, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 16),

          const Text('练习模式',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          // fluent_ui 4.17.0 的 RadioButton 改成 value + RadioGroup 模式，
          // 已无 checked / onChanged 参数，故用 ComboBox 表达「两种卷子分开选」。
          ComboBox<String>(
            value: st.mode,
            isExpanded: true,
            items: [
              ComboBoxItem<String>(
                  value: kModeWriteChar,
                  child: Text(modeLabel(kModeWriteChar))),
              ComboBoxItem<String>(
                  value: kModeWritePinyin,
                  child: Text(modeLabel(kModeWritePinyin))),
            ],
            onChanged: (v) {
              if (v != null) st.setMode(v);
            },
          ),
          const SizedBox(height: 6),
          Text(
            st.mode == kModeWriteChar
                ? '四线三格印拼音、田字格留空 → 照拼音写生字'
                : '田字格印生字、四线三格留空 → 给生字标拼音',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),

          const Text('每页字数',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ComboBox<int>(
            value: st.perPage,
            isExpanded: true,
            items: [20, 30, 40]
                .map((n) =>
                    ComboBoxItem<int>(value: n, child: Text('$n 字 / 页')))
                .toList(),
            onChanged: (v) {
              if (v != null) st.setPerPage(v);
            },
          ),
          const SizedBox(height: 16),

          const Text('页数', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          NumberBox<int>(
            value: st.pages,
            min: 1,
            max: 5,
            onChanged: (v) {
              if (v != null) st.setPages(v);
            },
          ),
          const SizedBox(height: 16),

          const Text('自定义生字（可选）',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextBox(
            controller: _customCtrl,
            maxLines: 3,
            placeholder: '粘贴一课生字，如：天地人口手；也可写成 天:tiān 地:dì',
            onChanged: (v) => st.setCustom(v),
          ),
          const SizedBox(height: 6),
          const Text('不填则用内置分级字表；纯汉字会自动补拼音。',
              style: TextStyle(fontSize: 11)),
          const SizedBox(height: 18),

          FilledButton(
            child: const Text('生成练习纸'),
            onPressed: () async {
              await st.generateWordSheet();
            },
          ),
        ],
      ),
    );
  }

  /// 生字卷历史（独立存储 key，不与口算试卷混在一起）
  Widget _historyCard(WordState st) {
    return Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('最近练习卷',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (st.history.isNotEmpty)
                Button(
                  child: const Text('清空'),
                  onPressed: () => st.clearAllHistory(),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (st.history.isEmpty)
            const Text('生成的练习卷会保存在这里（只存本机）。',
                style: TextStyle(fontSize: 11.5))
          else
            Column(
              children: st.history.map((h) {
                final active = st.currentSheet?.id == h.id;
                return GestureDetector(
                  onTap: () => st.selectSheet(h.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0x1A4C6FFF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h.name,
                                  maxLines: 1,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                '${h.gradeLabel} · ${h.modeText} · '
                                '${h.pages.length} 页 · ${h.createdAt}',
                                style: const TextStyle(fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(FluentIcons.delete),
                          onPressed: () => st.delSheet(h.id),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _previewCard(WordState st, WordSheet? sheet, int idx) {
    final total = sheet?.pages.length ?? 0;
    return Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                sheet == null ? '预览' : '预览（第 $idx / $total 页）',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (sheet != null) ...[
                Button(
                  child: const Text('上一页'),
                  onPressed: st.prevPage,
                ),
                const SizedBox(width: 8),
                Button(
                  child: const Text('换一批'),
                  onPressed: () => st.reshuffle(),
                ),
                const SizedBox(width: 8),
                Button(
                  child: const Text('下一页'),
                  onPressed: st.nextPage,
                ),
                const SizedBox(width: 8),
                FilledButton(
                  child: const Text('保存到本地'),
                  onPressed: () => _save(st),
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
                      child: Text('点左侧「生成练习纸」后，这里会显示 A4 预览'),
                    )
                  : FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      child: WordSheetPreview(
                        sheet: sheet,
                        pageIndex: idx - 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
