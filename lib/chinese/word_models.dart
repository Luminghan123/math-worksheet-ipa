import 'dart:math';

import 'word_bank.dart';
import 'word_engine.dart';

/// ---------------------------------------------------------------------------
/// 语文生字练习卷的数据模型
/// 独立一套（不改动口算的 Worksheet / SheetConfig），避免影响已交付版本。
/// ---------------------------------------------------------------------------

/// 练习模式：
///   'char'   练写字：四线三格印拼音、田字格留空，学生照拼音写生字
///   'pinyin' 练拼音：田字格印生字、四线三格留空，学生给生字注音
const String kModeWriteChar = 'char';
const String kModeWritePinyin = 'pinyin';

const Map<String, String> kModeLabels = {
  kModeWriteChar: '练写字（看拼音写生字）',
  kModeWritePinyin: '练拼音（看生字写拼音）',
};

String modeLabel(String mode) =>
    kModeLabels[mode] ?? kModeLabels[kModeWriteChar]!;

/// 生成配置快照（用于「换一批」重新抽字）
class WordConfig {
  final String grade;
  final String mode;
  final int perPage;
  final int pages;
  final String custom;

  const WordConfig({
    required this.grade,
    required this.mode,
    required this.perPage,
    required this.pages,
    required this.custom,
  });

  Map<String, dynamic> toJson() => {
        'grade': grade,
        'mode': mode,
        'perPage': perPage,
        'pages': pages,
        'custom': custom,
      };

  factory WordConfig.fromJson(Map<String, dynamic> j) => WordConfig(
        grade: (j['grade'] as String?) ?? '1a',
        mode: (j['mode'] as String?) ?? kModeWriteChar,
        perPage: (j['perPage'] as num?)?.toInt() ?? 20,
        pages: (j['pages'] as num?)?.toInt() ?? 1,
        custom: (j['custom'] as String?) ?? '',
      );
}

/// 一份生字练习卷：若干页，每页 perPage 个字
class WordSheet {
  final int id;
  final String name;
  final String gradeLabel;
  final String mode;
  final String createdAt;
  final WordConfig config;
  final List<List<Hanzi>> pages;

  const WordSheet({
    required this.id,
    required this.name,
    required this.gradeLabel,
    required this.mode,
    required this.createdAt,
    required this.config,
    required this.pages,
  });

  int get perPage => config.perPage;
  int get totalChars => pages.length * perPage;
  String get modeText => modeLabel(mode);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gradeLabel': gradeLabel,
        'mode': mode,
        'createdAt': createdAt,
        'config': config.toJson(),
        'pages': pages.map((p) => p.map((h) => h.toJson()).toList()).toList(),
      };

  factory WordSheet.fromJson(Map<String, dynamic> j) => WordSheet(
        id: (j['id'] as num).toInt(),
        name: (j['name'] as String?) ?? '练习卷',
        gradeLabel: (j['gradeLabel'] as String?) ?? '',
        mode: (j['mode'] as String?) ?? kModeWriteChar,
        createdAt: (j['createdAt'] as String?) ?? '',
        config: WordConfig.fromJson(
            (j['config'] as Map?)?.cast<String, dynamic>() ?? {}),
        pages: (j['pages'] as List? ?? [])
            .map((p) => (p as List)
                .map((h) => Hanzi.fromJson((h as Map).cast<String, dynamic>()))
                .toList())
            .toList(),
      );

  /// 依据同一配置重新抽字（换一批）
  WordSheet reshuffled(Random r) {
    return WordSheet(
      id: id,
      name: name,
      gradeLabel: gradeLabel,
      mode: mode,
      createdAt: createdAt,
      config: config,
      pages: generateWordPages(config, r),
    );
  }
}
