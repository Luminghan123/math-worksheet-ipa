import 'dart:math';

import 'word_bank.dart';
import 'word_models.dart';

/// ---------------------------------------------------------------------------
/// 生字出题引擎（纯 Dart，不依赖 Flutter）
///   - 字源：用户自定义粘贴的一课生字，或内置分级字表
///   - 抽字：洗牌后按需取，字不够时循环补足（保证每页字数填满）
///   - 练写字模式需要拼音；查不到拼音的字允许留空四线格
/// ---------------------------------------------------------------------------

/// 判断一个字符是不是 CJK 汉字（含常用扩展 A 区）
bool _isHan(int code) =>
    (code >= 0x4E00 && code <= 0x9FFF) ||
    (code >= 0x3400 && code <= 0x4DBF);

/// 把用户粘贴的文本解析成生字列表。
///
/// 支持三种写法（可混用，用空白 / 逗号 / 顿号 / 换行分隔）：
///   1. 纯汉字串     天 地 人  /  天地人
///   2. 带拼音       天:tiān   或   天 tiān
///   3. 上面两种混合
/// 纯汉字会自动查内置字表补拼音；查不到的字拼音留空。
List<Hanzi> parseCustomWords(String text) {
  final out = <Hanzi>[];
  final seen = <String>{};
  // 先按分隔符切成 token
  final tokens = text
      .split(RegExp(r'[\s,，、;；\n\r\t]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty);

  void add(String ch, String py) {
    if (ch.isEmpty || seen.contains(ch)) return;
    seen.add(ch);
    out.add(Hanzi(ch, py));
  }

  for (final tok in tokens) {
    // 情形 A：形如 "天:tiān" 或 "天 tiān"（空格分隔已在上面拆开，所以主要处理冒号）
    final colon = tok.indexOf(':');
    final colonCn = tok.indexOf('：');
    final sep = colon >= 0 ? colon : colonCn;
    if (sep >= 0) {
      final left = tok.substring(0, sep);
      final right = tok.substring(sep + 1).trim();
      // 左边可能是一串汉字，右边只作为第一个字的拼音
      final runes = left.runes.toList();
      for (var i = 0; i < runes.length; i++) {
        final ch = String.fromCharCode(runes[i]);
        if (!_isHan(runes[i])) continue;
        add(ch, i == 0 ? right : HanziBank.pinyinIndex[ch] ?? '');
      }
      continue;
    }
    // 情形 B：token 里含汉字的，逐字抽出（自动补拼音）
    final runes = tok.runes.toList();
    var hasHan = false;
    for (final r in runes) {
      if (!_isHan(r)) continue;
      hasHan = true;
      final ch = String.fromCharCode(r);
      add(ch, HanziBank.pinyinIndex[ch] ?? '');
    }
    if (hasHan) continue;
    // 情形 C：纯拼音 token（上一个 token 是单字时补拼音）——由调用方成对处理，
    // 这里简单跳过，避免把 latin 字母当成生字。
  }
  return out;
}

/// 依据配置取字源
List<Hanzi> wordPool(WordConfig cfg) {
  final custom = parseCustomWords(cfg.custom);
  if (custom.isNotEmpty) return custom;
  return HanziBank.of(cfg.grade);
}

/// 生成整卷：返回 pages 页，每页 perPage 个字
List<List<Hanzi>> generateWordPages(WordConfig cfg, Random r) {
  final pool = List<Hanzi>.from(wordPool(cfg));
  if (pool.isEmpty) {
    pool.addAll(HanziBank.of('1a')); // 兜底，保证不空
  }
  final total = cfg.pages * cfg.perPage;
  final picked = <Hanzi>[];
  while (picked.length < total) {
    final shuffled = List<Hanzi>.from(pool)..shuffle(r);
    for (final h in shuffled) {
      if (picked.length >= total) break;
      picked.add(h);
    }
  }
  final pages = <List<Hanzi>>[];
  for (var p = 0; p < cfg.pages; p++) {
    pages.add(picked.sublist(p * cfg.perPage, (p + 1) * cfg.perPage));
  }
  return pages;
}
