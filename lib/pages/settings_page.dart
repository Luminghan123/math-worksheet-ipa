import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../engine.dart';
import '../models.dart';
import '../share.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// 设置页：唯一的「保存到本地」出口 + 数据管理 + 关于
///
/// 保存逻辑照搬参考软件：
///   await Printing.sharePdf(bytes: result.bytes, filename: filename);
/// PDF 在内存里生成后直接交给系统分享面板，用户选「存储到文件」自己决定
/// 存哪。App 不写文档目录、不新建任何文件夹。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final h = state.history;
    // 当前目标试卷：优先 currentSheet，其次历史第一份
    Worksheet? target = state.currentSheet;
    if (target == null && h.isNotEmpty) target = h.first;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => state.go(PageId.home),
          child: const Text('‹ 返回',
              style: TextStyle(
                  fontSize: 15, color: kBrand, fontWeight: FontWeight.w600)),
        ),
        title: const Text('设置'),
        leadingWidth: 80,
        actions: const [SizedBox(width: 56)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // ---------- 分享 / 保存到本地 ----------
          GroupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GroupHead(
                  badge: '↑',
                  title: '分享 / 保存到本地',
                  badgeColor: kOk,
                  badgeBg: kOkSoft,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 6),
                  child: Text(
                    '点下面的按钮后，手机会弹出系统分享面板：选「存储到文件」即可把整卷 PDF '
                    '存到你指定的位置，也能直接发到微信、邮箱或别的应用。'
                    'App 不会在手机里新建文件夹，PDF 只在内存里生成。',
                    style: TextStyle(fontSize: 12, color: kInk3, height: 1.65),
                  ),
                ),

                // 选择试卷
                FormRow(
                  label: '选择试卷',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: kBg,
                        border: Border.all(color: kLine),
                        borderRadius: BorderRadius.circular(10)),
                    child: DropdownButton<int>(
                      value: target?.id,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      alignment: AlignmentDirectional.centerEnd,
                      hint: const Text('暂无试卷，请先生成一份',
                          style: TextStyle(fontSize: 12, color: kInk3)),
                      items: [
                        for (final x in h)
                          DropdownMenuItem(
                            value: x.id,
                            child: Text(
                              '${x.name}（${x.pages.length} 页）',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: h.isEmpty
                          ? null
                          : (v) {
                              if (v != null) state.selectSheet(v);
                            },
                      icon: const Icon(Icons.arrow_drop_down,
                          color: kBrand, size: 20),
                    ),
                  ),
                ),

                // 当前试卷信息
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 6, bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: kBg,
                      border: Border.all(color: kLine),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            color: kSoft,
                            border: Border.all(color: const Color(0xFFD9E1FF)),
                            borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: const Text('≡',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: kBrand)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: target == null
                            ? const Text('还没有试卷，请先回首页点「＋」生成一份。',
                                style: TextStyle(
                                    fontSize: 12, color: kInk2, height: 1.6))
                            : Text(
                                '当前试卷：${target.name}\n'
                                '${target.gradeLabel} · ${target.pages.length} 页 · '
                                '${target.totalQuestions} 题 · 每题 ${target.score} 分',
                                style: const TextStyle(
                                    fontSize: 12, color: kInk2, height: 1.6)),
                      ),
                    ],
                  ),
                ),

                // 唯一主按钮
                GradientButton(
                  label: state.busy ? '正在生成…' : '生成并分享 / 保存 PDF',
                  icon: Icons.ios_share,
                  busy: state.busy,
                  onTap: target == null
                      ? null
                      : () => _save(context, state, target!),
                ),

                // 结果提示
                if (state.status.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: state.statusError ? kDangerSoft : kOkSoft,
                      border: Border.all(
                          color: state.statusError
                              ? const Color(0xFFF3CFCF)
                              : const Color(0xFFCDEDDD)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(state.status,
                        style: TextStyle(
                            fontSize: 12.5,
                            height: 1.7,
                            color: state.statusError
                                ? const Color(0xFFA23B3B)
                                : kInk)),
                  ),
                ],

                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    '手机上第一次分享若没看到「存储到文件」，在系统分享面板里上滑或点「更多」即可找到。'
                    '与参考软件一致：PDF 生成后直接交给系统分享面板，App 不写文档目录、不新建文件夹。',
                    style: TextStyle(fontSize: 11.5, color: kInk3, height: 1.7),
                  ),
                ),
              ],
            ),
          ),

          // ---------- 数据管理 ----------
          GroupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GroupHead(
                  badge: '▤',
                  title: '数据管理',
                  badgeColor: kAccent,
                  badgeBg: Color(0xFFFFF1E6),
                ),
                const HintText(
                    '历史试卷只存在本机，不会上传。清空后首页列表与这里的试卷一起清空，已经分享保存出去的文件不受影响。'),
                InkWell(
                  onTap: h.isEmpty ? null : () => _confirmClear(context, state),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                        border:
                            Border(top: BorderSide(color: kLine, width: 1))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('清空全部历史试卷',
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: h.isEmpty ? kInk3 : kDanger)),
                        const Icon(Icons.chevron_right,
                            size: 18, color: Color(0xFFC7CEDC)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------- 关于 ----------
          GroupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GroupHead(badge: 'i', title: '关于', tag: 'v2.0 Flutter'),
                const SizedBox(height: 6),
                _aboutRow('应用名称', '口算题卡'),
                _aboutRow('纸张规格', 'A4 竖版 · 210 × 297 mm'),
                _aboutRow('每页题量', '$kPerPage 题（${kCols} 列 × ${kRows} 行）'),
                _aboutRow('出题规则', '按年级收敛 · 含 0 运算'),
                _aboutRow('保存方式', '系统分享面板 · 不建文件夹'),
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('本版不含参考答案页，也不做手机做题判分。',
                      style: TextStyle(fontSize: 12, color: kInk3)),
                ),
              ],
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
      final result = await buildSheetPdf(sheet);
      await sharePdfBytes(sheet, result); // Printing.sharePdf —— 唯一保存动作
      state.setBusy(false);
      state.setStatus(
        '✓ ${sheetFileName(sheet)}（${humanSize(result.bytes.length)}，'
        '${result.pageCount} 页 A4）已交给系统分享面板。'
        '选「存储到文件」即可存到你指定的位置，也可直接发到微信、邮箱。'
        'App 不会在手机里新建文件夹。',
      );
    } catch (e) {
      state.setBusy(false);
      state.setStatus('分享失败：$e', true);
    }
  }

  Future<void> _confirmClear(BuildContext context, AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('清空全部历史试卷？'),
        content: const Text('已通过分享保存出去的文件不受影响。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('清空', style: TextStyle(color: kDanger))),
        ],
      ),
    );
    if (ok == true) await state.clearAllHistory();
  }

  Widget _aboutRow(String k, String v) => Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: kLine, width: 1))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(fontSize: 12.5, color: kInk3)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: kInk)),
            ),
          ],
        ),
      );
}
