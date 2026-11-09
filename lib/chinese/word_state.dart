import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'word_bank.dart';
import 'word_models.dart';
import 'word_engine.dart';

/// ---------------------------------------------------------------------------
/// 语文生字模块独立状态：出题配置 + 历史练习卷 + 当前浏览的卷
/// 与口算的 AppState 完全隔离，历史用独立的本机存储 key，互不影响。
/// ---------------------------------------------------------------------------

const String _kWordHistoryKey = 'mwa_flutter_word_history_v1';

class WordState extends ChangeNotifier {
  final Random _r = Random();
  SharedPreferences? _prefs;

  // ---------- 配置 ----------
  String grade = '1a';
  String mode = kModeWriteChar;
  int perPage = 20;
  int pages = 1;
  String custom = '';

  // ---------- 页面 / 试卷 ----------
  List<WordSheet> history = [];
  WordSheet? currentSheet;
  int currentPage = 1; // 1-based
  String status = '';
  bool statusError = false;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_kWordHistoryKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        history = list
            .map((e) => WordSheet.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      }
    } catch (_) {
      history = [];
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      await _prefs?.setString(
        _kWordHistoryKey,
        jsonEncode(history.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  // ---------- 配置操作 ----------
  void setGrade(String v) {
    grade = v;
    notifyListeners();
  }

  void setMode(String v) {
    mode = v;
    notifyListeners();
  }

  void setPerPage(int v) {
    perPage = v;
    notifyListeners();
  }

  void stepPages(int d) {
    pages = max(1, min(5, pages + d));
    notifyListeners();
  }

  /// 直接设定页数（桌面 NumberBox / 移动步进器共用），自动收敛到 1–5
  void setPages(int v) {
    pages = max(1, min(5, v));
    notifyListeners();
  }

  void setCustom(String v) {
    custom = v;
    notifyListeners();
  }

  /// 当前实际会用到的字源数量（自定义优先，否则取内置字表）
  int get poolSize => wordPool(
        WordConfig(
          grade: grade,
          mode: mode,
          perPage: perPage,
          pages: pages,
          custom: custom,
        ),
      ).length;

  String get poolLabel => custom.trim().isEmpty
      ? '内置 ${HanziBank.labelOf(grade)}（${HanziBank.of(grade).length} 字）'
      : '自定义（$poolSize 字）';

  // ---------- 生成 / 换一批 ----------
  Future<void> generateWordSheet() async {
    final cfg = WordConfig(
      grade: grade,
      mode: mode,
      perPage: perPage,
      pages: pages,
      custom: custom,
    );
    final newPages = generateWordPages(cfg, _r);
    final now = DateTime.now();
    final item = WordSheet(
      id: now.microsecondsSinceEpoch,
      name: '${HanziBank.labelOf(grade)} · ${modeLabel(mode)} · 第 ${history.length + 1} 份',
      gradeLabel: HanziBank.labelOf(grade),
      mode: mode,
      createdAt:
          '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      config: cfg,
      pages: newPages,
    );
    history = [item, ...history].take(12).toList();
    currentSheet = item;
    currentPage = 1;
    status = '';
    await _persist();
    notifyListeners();
  }

  Future<void> reshuffle() async {
    final cur = currentSheet;
    if (cur == null) return;
    final fresh = cur.reshuffled(_r);
    currentSheet = fresh;
    history = history.map((e) => e.id == fresh.id ? fresh : e).toList();
    await _persist();
    notifyListeners();
  }

  void selectSheet(int id) {
    final found = history.where((x) => x.id == id).toList();
    if (found.isEmpty) return;
    currentSheet = found.first;
    currentPage = 1;
    status = '';
    notifyListeners();
  }

  Future<void> delSheet(int id) async {
    history = history.where((x) => x.id != id).toList();
    if (currentSheet?.id == id) currentSheet = null;
    await _persist();
    notifyListeners();
  }

  Future<void> clearAllHistory() async {
    history = [];
    currentSheet = null;
    status = '';
    await _persist();
    notifyListeners();
  }

  void prevPage() {
    final cur = currentSheet;
    if (cur == null) return;
    currentPage = max(1, currentPage - 1);
    notifyListeners();
  }

  void nextPage() {
    final cur = currentSheet;
    if (cur == null) return;
    currentPage = min(cur.pages.length, currentPage + 1);
    notifyListeners();
  }

  void setStatus(String msg, [bool err = false]) {
    status = msg;
    statusError = err;
    notifyListeners();
  }
}
