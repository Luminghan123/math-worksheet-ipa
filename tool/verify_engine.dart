// 本地回归测试：只依赖 dart:math，可在任意 Dart SDK 上直接跑
//   dart tool/verify_engine.dart
import 'dart:math';
import '../lib/engine.dart';
import '../lib/models.dart';

int _fail = 0;
void ok(bool cond, String msg) {
  if (!cond) {
    _fail++;
    print('  ✗ $msg');
  }
}

void main() {
  final r = Random(20261108);
  print('=== 出题引擎回归 ===');

  // 1) 年级规则
  ok(kGradeRules.length == 12, '12 个年级档');
  print('  年级档: ${kGradeRules.length}');

  // 2) 每个年级 / 每个 cap / 三种题型，生成大量题目并逐项校验
  var totalQ = 0, zeroQ = 0, fillQ = 0, blankWithLine = 0;
  final caps = [10, 20, 100, 1000, 10000];
  for (final g in kGradeRules) {
    for (final cap in caps) {
      for (final t in kAllTypes) {
        for (var i = 0; i < 60; i++) {
          final q = makeQuestion(g, min(cap, g.max), t, r);
          totalQ++;
          // 表达式必须含等号
          ok(q.expr.contains('='), '${g.id}/$cap/$t 含等号: ${q.expr}');
          // 答案非负
          ok(q.answer >= 0, '${g.id}/$cap/$t 答案非负: ${q.expr}=${q.answer}');
          // 运算符不超纲
          for (final op in const ['+', '−', '×', '÷']) {
            if (q.expr.contains(op)) {
              ok(g.ops.contains(op), '${g.id} 不应出现 $op: ${q.expr}');
            }
          }
          // 数值不超过上限（粗略：提取所有数字校验）
          for (final m in RegExp(r'\d+').allMatches(q.expr)) {
            final n = int.parse(m.group(0)!);
            ok(n <= g.max * 10 + 10, '${g.id} 数值 $n 疑似超上限: ${q.expr}');
          }
          // 填空题规则
          if (t == '填空') {
            fillQ++;
            ok(q.expr.contains('□'), '填空题必须含 □: ${q.expr}');
            ok(q.isFillBlank, 'isFillBlank=true: ${q.expr}');
          } else {
            ok(!q.expr.contains('□'), '非填空题不应含 □: ${q.expr}');
            ok(!q.isFillBlank, 'isFillBlank=false: ${q.expr}');
          }
        }
      }
    }
  }
  print('  普通题抽样: $totalQ 道，填空题: $fillQ');

  // 3) 每页恰好 125 题、恰好 10 道含 0 运算
  var pagesChecked = 0;
  for (final g in kGradeRules) {
    for (var p = 0; p < 12; p++) {
      final weights = {'口算': 60, '竖式': 25, '填空': 15};
      final page = generatePage(g, g.max, weights, r);
      pagesChecked++;
      ok(page.length == kPerPage, '${g.id} 每页 125 题，实际 ${page.length}');
      final z = page.where((q) => q.type == '含0运算').length;
      zeroQ += z;
      ok(z == kZeroPerPage, '${g.id} 每页 10 道含 0，实际 $z');
      // 含 0 题：要么表达式里有 0 参与，要么结果为 0（a − a = 0）
      for (final q in page.where((q) => q.type == '含0运算')) {
        ok(q.expr.contains('0') || q.answer == 0,
            '含0运算应有 0 参与或结果为 0: ${q.expr}=${q.answer}');
      }
      // 分配合计
      final alloc = allocate(weights, kPerPage);
      ok(alloc.values.fold<int>(0, (a, b) => a + b) == kPerPage,
          'allocate 合计 125');
    }
  }
  print('  整页校验: $pagesChecked 页，含 0 运算共 $zeroQ 道');

  // 4) 填空题不追加横线（渲染层判断）——统计
  for (final g in kGradeRules) {
    final page = generatePage(g, g.max, {'口算': 60, '竖式': 25, '填空': 15}, r);
    final fill = page.where((q) => q.isFillBlank).length;
    ok(fill > 0, '${g.id} 应含填空题');
    blankWithLine += page.where((q) => !q.isFillBlank).length;
  }
  print('  非填空（需画横线）题抽样: $blankWithLine');

  // 5) 模型 JSON 往返
  final rule = gradeById('2b');
  final sheet = Worksheet(
    id: 123,
    name: '二年级下 · 第 1 份',
    gradeLabel: rule.label,
    score: 1,
    createdAt: '11-08 20:30',
    config: SheetConfig(
        grade: '2b', cap: 100, pages: 2, score: 1, weights: {'口算': 100}),
    pages: [
      generatePage(rule, 100, {'口算': 100}, r),
      generatePage(rule, 100, {'口算': 100}, r),
    ],
  );
  // 手动模拟 jsonEncode/jsonDecode 往返（避免依赖 dart:convert 的 package 冲突）
  final j = sheet.toJson();
  final back = Worksheet.fromJson(j);
  ok(back.id == 123 && back.pages.length == 2, 'JSON 往返页数');
  ok(back.pages[0].length == 125, 'JSON 往返每页 125 题');
  ok(back.pages[0][0].expr == sheet.pages[0][0].expr, 'JSON 往返题目文本');
  ok(back.totalQuestions == 250, '总题数 250');
  ok(back.fullScore == 125, '满分 125');
  final fresh = back.reshuffled(r);
  ok(fresh.pages.length == 2 && fresh.id == 123, '换一批保持 id/页数');
  print('  模型 JSON 往返 + 换一批: OK');

  print('');
  if (_fail == 0) {
    print('✅ 全部通过（0 失败）');
  } else {
    print('❌ 失败 $_fail 项');
  }
}
