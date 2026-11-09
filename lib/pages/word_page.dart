import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../chinese/grid_preview.dart';
import '../chinese/word_bank.dart';
import '../chinese/word_models.dart'
    show kModeWriteChar, kModeWritePinyin, modeLabel, WordSheet;
import '../chinese/word_share.dart';
import '../chinese/word_state.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// 移动端「语文生字」页。
///
/// 手机屏幕窄，不照搬桌面的左右分栏，改成两态切换：
///   - 配置态：字表 / 练习模式 / 每页字数 / 页数 / 自定义字 + 最近练习卷
///   - 预览态：A4 预览（田字格 + 四线三格）+ 翻页 / 换一批 / 保存
/// 生成后自动切到预览态；预览态返回可回到配置态再调参数。
class WordPage extends StatefulWidget {
  const WordPage({super.key});

  @override
  State<WordPage> createState() => _WordPageState();
}

class _WordPageState extends State<WordPage> {
  final TextEditingController _customCtrl = TextEditingController();
  bool _showPreview = false;
  bool _busy = false;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate(WordState st) async {
    await st.generateWordSheet();
    if (!mounted) return;
    setState(() => _showPreview = true);
  }

  Future<void> _save(BuildContext context, WordSheet sheet) async {
    setState(() => _busy = true);
    try {
      await shareWordSheet(sheet); // Printing.sharePdf —— 系统分享面板
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已打开系统分享面板')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<WordState>();
    final sheet = st.currentSheet;
    final showPreview = _showPreview && sheet != null;

    if (showPreview) return _buildPreview(context, st, sheet);
    return _buildConfig(context, st);
  }

  // ---------------------------------------------------------------------------
  // 配置态
  // ---------------------------------------------------------------------------
  Widget _buildConfig(BuildContext context, WordState st) {
    final appState = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => appState.go(PageId.home),
          child: const Text('‹ 返回',
              style: TextStyle(
                  fontSize: 15, color: kBrand, fontWeight: FontWeight.w600)),
        ),
        title: const Text('语文生字'),
        leadingWidth: 80,
        actions: const [SizedBox(width: 56)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                // ---------- 1 字表与模式 ----------
                GroupCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GroupHead(
                          badge: '字', title: '字表与练习模式', tag: '两种卷子'),
                      const HintText(
                          '练写字：四线三格印拼音、田字格留空；练拼音：田字格印生字、四线三格留空。'
                          '两种卷子分开选，一次只练一种。'),
                      FormRow(
                        label: '年级 / 册',
                        child: _dropdown<String>(
                          value: st.grade,
                          items: [
                            for (final id in HanziBank.gradeIds)
                              DropdownMenuItem(
                                  value: id,
                                  child: Text(HanziBank.labelOf(id)))
                          ],
                          onChanged: (v) {
                            if (v != null) st.setGrade(v);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SegChoice(
                            label: '练写字',
                            selected: st.mode == kModeWriteChar,
                            onTap: () => st.setMode(kModeWriteChar),
                          ),
                          const SizedBox(width: 10),
                          SegChoice(
                            label: '练拼音',
                            selected: st.mode == kModeWritePinyin,
                            onTap: () => st.setMode(kModeWritePinyin),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(modeLabel(st.mode),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kBrand)),
                      const SizedBox(height: 4),
                      Text(st.poolLabel,
                          style: const TextStyle(
                              fontSize: 11.5, color: kInk3)),
                    ],
                  ),
                ),

                // ---------- 2 版式与字数 ----------
                GroupCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GroupHead(
                        badge: '2',
                        title: '版式与字数',
                        badgeColor: kAccent,
                        badgeBg: Color(0xFFFFF1E6),
                      ),
                      const HintText('A4 竖版，每个生字上方四线三格、下方田字格。'),
                      FormRow(
                        label: '每页字数',
                        child: _dropdown<int>(
                          value: st.perPage,
                          items: [
                            for (final n in const [20, 30, 40])
                              DropdownMenuItem(
                                  value: n, child: Text('$n 字 / 页'))
                          ],
                          onChanged: (v) {
                            if (v != null) st.setPerPage(v);
                          },
                        ),
                      ),
                      FormRow(
                        label: '页数',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NumberStepper(
                              value: st.pages,
                              onMinus: () => st.stepPages(-1),
                              onPlus: () => st.stepPages(1),
                            ),
                            const SizedBox(width: 8),
                            Text('共 ${st.pages * st.perPage} 字',
                                style: const TextStyle(
                                    fontSize: 12, color: kInk3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------- 3 自定义生字 ----------
                GroupCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GroupHead(
                        badge: '3',
                        title: '自定义生字（可选）',
                        badgeColor: kOk,
                        badgeBg: kOkSoft,
                      ),
                      const HintText(
                          '不填则用内置分级字表。可直接粘贴一课生字（纯汉字会自动补拼音），'
                          '也可写成「字:拼音」，如 天:tiān 地:dì。'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customCtrl,
                        maxLines: 3,
                        onChanged: (v) => st.setCustom(v),
                        style: const TextStyle(fontSize: 13, color: kInk),
                        decoration: InputDecoration(
                          hintText: '例：天地人口手；或 天:tiān 地:dì',
                          hintStyle: const TextStyle(
                              fontSize: 12, color: kInk3),
                          filled: true,
                          fillColor: kBg,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kLine),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kLine),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kBrand),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------- 最近练习卷（独立历史，不与口算混） ----------
                _historyCard(context, st),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: Text(
                    '练习卷只在本机保存，不会上传。生成后用系统分享面板保存 PDF，'
                    'App 不在手机里新建文件夹。',
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
              label: '生成练习纸',
              icon: Icons.grid_on_outlined,
              onTap: () => _generate(st),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(BuildContext context, WordState st) {
    return GroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GroupHead 内部含 Expanded，必须放在 Column 里拿到有界宽度，
          // 不能塞进另一个 Row（否则 Expanded 收到 unbounded 约束会崩）。
          const GroupHead(badge: '▤', title: '最近练习卷'),
          if (st.history.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => st.clearAllHistory(),
                child: const Text('清空',
                    style: TextStyle(fontSize: 12, color: kDanger)),
              ),
            ),
          if (st.history.isEmpty)
            const HintText('生成的练习卷会保存在这里（只存本机）。')
          else
            Column(
              children: st.history.map((h) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: kLine, width: 1))),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            st.selectSheet(h.id);
                            setState(() => _showPreview = true);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kInk)),
                              const SizedBox(height: 3),
                              Text(
                                '${h.gradeLabel} · ${h.modeText} · '
                                '${h.pages.length} 页 · ${h.createdAt}',
                                style: const TextStyle(
                                    fontSize: 11, color: kInk3),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 19, color: kDanger),
                        onPressed: () => st.delSheet(h.id),
                      ),
                    ],
                  ),
                );
              }).toList(),
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

  // ---------------------------------------------------------------------------
  // 预览态
  // ---------------------------------------------------------------------------
  Widget _buildPreview(
      BuildContext context, WordState st, WordSheet sheet) {
    final total = sheet.pages.length;
    final page = st.currentPage.clamp(1, total);
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => setState(() => _showPreview = false),
          child: const Text('‹ 配置',
              style: TextStyle(
                  fontSize: 15, color: kBrand, fontWeight: FontWeight.w600)),
        ),
        title: Text('$page / $total'),
        leadingWidth: 80,
        actions: [
          TextButton(
            onPressed: _busy ? null : () => _save(context, sheet),
            child: Text(_busy ? '生成中…' : '保存',
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
                _tool('‹ 上一页', st.prevPage),
                const SizedBox(width: 8),
                _tool('换一批', () => st.reshuffle()),
                const SizedBox(width: 8),
                _tool('下一页 ›', st.nextPage),
              ],
            ),
          ),
          // ---------- A4 试卷 ----------
          Expanded(
            child: Container(
              color: const Color(0xFFE7ECF5),
              padding: const EdgeInsets.all(14),
              alignment: Alignment.topCenter,
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 794,
                  height: 1123,
                  child: WordSheetPreview(
                    sheet: sheet,
                    pageIndex: page - 1,
                  ),
                ),
              ),
            ),
          ),
          // ---------- 底部说明 ----------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
            color: Colors.white,
            child: const Text(
              'A4 210 × 297 mm · 田字格 + 四线三格\n'
              '点右上「保存」调起系统分享面板，选「存储到文件」即可保存整卷 PDF',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: kInk3, height: 1.6),
            ),
          ),
        ],
      ),
    );
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
