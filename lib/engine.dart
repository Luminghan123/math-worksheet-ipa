import 'dart:math';

/// ---------------------------------------------------------------------------
/// 出题引擎（纯 Dart，不依赖 Flutter，可单独跑单元测试）
/// 从旧版 index.html 的 JS 出题逻辑 1:1 移植而来：
///   - 按年级/学期收敛运算符，避免超纲
///   - 口算 / 竖式 / 填空 三种题型
///   - 每页固定 125 题（5 列 × 25 行），其中固定 10 道「含 0 的运算」
///   - 含 □ 的填空题不追加答案横线（由渲染层判断）
/// ---------------------------------------------------------------------------

/// 每页题量 / 网格
const int kPerPage = 125;
const int kCols = 5;
const int kRows = 25;
const int kZeroPerPage = 10;

/// 三种题型
const List<String> kAllTypes = ['口算', '竖式', '填空'];

/// 年级知识点规则：max 为数值上限，ops 为该阶段允许的运算符
class GradeRule {
  final String id;
  final String label;
  final int max;
  final List<String> ops;
  final String note;

  const GradeRule(this.id, this.label, this.max, this.ops, this.note);
}

const List<GradeRule> kGradeRules = [
  GradeRule('1a', '一年级上', 10, ['+', '−'], '10 以内加减法'),
  GradeRule('1b', '一年级下', 20, ['+', '−'], '20 以内加减法、退位减'),
  GradeRule('2a', '二年级上', 100, ['+', '−', '×'], '100 以内加减、表内乘法'),
  GradeRule('2b', '二年级下', 100, ['+', '−', '×', '÷'], '表内乘除法、万以内加减'),
  GradeRule('3a', '三年级上', 1000, ['+', '−', '×'], '万以内加减、多位数乘一位数'),
  GradeRule('3b', '三年级下', 1000, ['+', '−', '×', '÷'], '两位数乘两位数、除数一位数除法'),
  GradeRule('4a', '四年级上', 10000, ['+', '−', '×', '÷'], '三位数乘两位数、除数两位数除法'),
  GradeRule('4b', '四年级下', 10000, ['+', '−', '×', '÷'], '四则混合、运算律、小数加减'),
  GradeRule('5a', '五年级上', 10000, ['+', '−', '×', '÷'], '小数乘除、简易方程'),
  GradeRule('5b', '五年级下', 10000, ['+', '−', '×', '÷'], '分数加减、因数与倍数'),
  GradeRule('6a', '六年级上', 10000, ['+', '−', '×', '÷'], '分数乘除、百分数'),
  GradeRule('6b', '六年级下', 10000, ['+', '−', '×', '÷'], '比例、综合运算'),
];

GradeRule gradeById(String id) =>
    kGradeRules.firstWhere((g) => g.id == id, orElse: () => kGradeRules[3]);

/// 一道题：表达式文本 + 答案 + 题型
class Question {
  final String expr;
  final int answer;
  final String type;

  const Question(this.expr, this.answer, this.type);

  /// 填空题用 □ 占位，后面不再追加答案横线
  bool get isFillBlank => expr.contains('□');

  Map<String, dynamic> toJson() => {'e': expr, 'a': answer, 't': type};

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        j['e'] as String,
        (j['a'] as num).toInt(),
        (j['t'] as String?) ?? '口算',
      );
}

int _rnd(Random r, int a, int b) => b <= a ? a : a + r.nextInt(b - a + 1);
T _pick<T>(Random r, List<T> list) => list[r.nextInt(list.length)];

/// 生成一道普通题（短算式，一行写完；加减法允许 0 参与）
Question makeQuestion(GradeRule rule, int cap, String type, Random r) {
  final big = type == '竖式';
  final ops = rule.ops;

  if (type == '填空') {
    final usable = ops.where((o) => o != '÷').toList();
    final op = _pick(r, usable.isEmpty ? <String>['+'] : usable);
    if (op == '+') {
      final ans = _rnd(r, 3, max(3, min(cap, 99)));
      final a = _rnd(r, 0, ans - 1);
      return Question('$a + □ = $ans', ans - a, type);
    }
    if (op == '−') {
      final a = _rnd(r, 3, max(3, min(cap, 99)));
      final ans = _rnd(r, 0, a - 1);
      return Question('$a − □ = $ans', a - ans, type);
    }
    final b = _rnd(r, 2, 9);
    final q0 = cap ~/ b; // JS: Math.floor(cap/b)||9
    final qHi = max(2, min(9, q0 == 0 ? 9 : q0));
    final q = _rnd(r, 2, qHi);
    return Question('□ × $b = ${b * q}', q, type);
  }

  final op = _pick(r, ops);
  if (op == '+') {
    final hi = max(4, min(cap, big ? 999 : 99));
    final a = _rnd(r, 0, hi - 1);
    final b = _rnd(r, 0, max(0, hi - a));
    return Question('$a + $b =', a + b, type);
  }
  if (op == '−') {
    final hi = max(4, min(cap, big ? 999 : 99));
    final a = _rnd(r, 0, hi);
    final b = _rnd(r, 0, a);
    return Question('$a − $b =', a - b, type);
  }
  if (op == '×') {
    int a, b;
    if (big && cap >= 100) {
      a = _rnd(r, 11, min(99, max(12, cap)));
      b = _rnd(r, 2, 9);
    } else {
      a = _rnd(r, 2, 9);
      b = _rnd(r, 2, 9);
    }
    return Question('$a × $b =', a * b, type);
  }
  // ÷
  final b = _rnd(r, 2, 9);
  final qmax = big ? max(2, min(99, cap ~/ b)) : 9;
  final q = _rnd(r, 2, max(2, qmax));
  return Question('${b * q} ÷ $b =', q, type);
}

/// 含 0 的运算：0 作加数 / 减数 / 被减数 / 因数 / 被除数，或结果为 0
Question makeZeroQuestion(GradeRule rule, int cap, Random r) {
  final hi = max(3, min(cap, 99));
  final op = _pick(r, rule.ops);
  late String expr;
  late int answer;
  if (op == '+') {
    final b = _rnd(r, 1, hi);
    if (r.nextDouble() < .5) {
      expr = '0 + $b =';
    } else {
      expr = '$b + 0 =';
    }
    answer = b;
  } else if (op == '−') {
    final a = _rnd(r, 1, hi);
    if (r.nextDouble() < .5) {
      expr = '$a − 0 =';
      answer = a;
    } else {
      expr = '$a − $a =';
      answer = 0;
    }
  } else if (op == '×') {
    final b = _rnd(r, 1, 9);
    expr = r.nextDouble() < .5 ? '0 × $b =' : '$b × 0 =';
    answer = 0;
  } else {
    final b = _rnd(r, 1, 9);
    expr = '0 ÷ $b =';
    answer = 0;
  }
  return Question(expr, answer, '含0运算');
}

/// 按权重把 total 道题分配给各题型，最后一项补齐余数，保证合计恰好 total
Map<String, int> allocate(Map<String, int> weights, int total) {
  final keys = weights.keys.toList();
  final out = <String, int>{};
  var acc = 0;
  for (var i = 0; i < keys.length; i++) {
    if (i == keys.length - 1) {
      out[keys[i]] = total - acc;
    } else {
      final v = (total * weights[keys[i]]! / 100).round();
      out[keys[i]] = v;
      acc += v;
    }
  }
  return out;
}

/// 生成一页 125 题，并在随机 10 个位置替换为「含 0 运算」
List<Question> generatePage(
    GradeRule rule, int cap, Map<String, int> weights, Random r) {
  final counts = allocate(weights, kPerPage);
  final list = <Question>[];
  counts.forEach((t, n) {
    for (var i = 0; i < n; i++) {
      list.add(makeQuestion(rule, cap, t, r));
    }
  });
  final used = <int>{};
  while (used.length < kZeroPerPage) {
    used.add(r.nextInt(kPerPage));
  }
  for (final i in used) {
    list[i] = makeZeroQuestion(rule, cap, r);
  }
  return list;
}
