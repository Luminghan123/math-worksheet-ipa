import 'dart:math';

import 'engine.dart';

/// ---------------------------------------------------------------------------
/// 数据模型 + JSON 序列化（历史试卷用 shared_preferences 存在本机）
/// ---------------------------------------------------------------------------

/// 生成这份试卷时的配置快照，用于「换一批」重新出题
class SheetConfig {
  final String grade;
  final int cap;
  final int pages;
  final int score;
  final Map<String, int> weights;

  const SheetConfig({
    required this.grade,
    required this.cap,
    required this.pages,
    required this.score,
    required this.weights,
  });

  Map<String, dynamic> toJson() => {
        'grade': grade,
        'cap': cap,
        'pages': pages,
        'score': score,
        'weights': weights,
      };

  factory SheetConfig.fromJson(Map<String, dynamic> j) => SheetConfig(
        grade: (j['grade'] as String?) ?? '2b',
        cap: (j['cap'] as num?)?.toInt() ?? 100,
        pages: (j['pages'] as num?)?.toInt() ?? 1,
        score: (j['score'] as num?)?.toInt() ?? 1,
        weights: (j['weights'] as Map?) == null
            ? {'口算': 60, '竖式': 25, '填空': 15}
            : (j['weights'] as Map)
                .map((k, v) => MapEntry(k as String, (v as num).toInt())),
      );
}

/// 一份试卷：若干页，每页 kPerPage 道题
class Worksheet {
  final int id;
  final String name;
  final String gradeLabel;
  final int score;
  final String createdAt;
  final SheetConfig config;
  final List<List<Question>> pages;

  const Worksheet({
    required this.id,
    required this.name,
    required this.gradeLabel,
    required this.score,
    required this.createdAt,
    required this.config,
    required this.pages,
  });

  int get totalQuestions => pages.length * kPerPage;
  int get fullScore => kPerPage * score;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gradeLabel': gradeLabel,
        'score': score,
        'createdAt': createdAt,
        'config': config.toJson(),
        'pages': pages.map((p) => p.map((q) => q.toJson()).toList()).toList(),
      };

  factory Worksheet.fromJson(Map<String, dynamic> j) => Worksheet(
        id: (j['id'] as num).toInt(),
        name: (j['name'] as String?) ?? '试卷',
        gradeLabel: (j['gradeLabel'] as String?) ?? '',
        score: (j['score'] as num?)?.toInt() ?? 1,
        createdAt: (j['createdAt'] as String?) ?? '',
        config: SheetConfig.fromJson(
            (j['config'] as Map?)?.cast<String, dynamic>() ?? {}),
        pages: (j['pages'] as List? ?? [])
            .map((p) => (p as List)
                .map((q) =>
                    Question.fromJson((q as Map).cast<String, dynamic>()))
                .toList())
            .toList(),
      );

  /// 依据同一配置重新生成所有页（换一批）
  Worksheet reshuffled(Random r) {
    final rule = gradeById(config.grade);
    final cap = min(rule.max, config.cap);
    final newPages = List<List<Question>>.generate(
      config.pages,
      (_) => generatePage(rule, cap, config.weights, r),
    );
    return Worksheet(
      id: id,
      name: name,
      gradeLabel: gradeLabel,
      score: score,
      createdAt: createdAt,
      config: config,
      pages: newPages,
    );
  }
}
