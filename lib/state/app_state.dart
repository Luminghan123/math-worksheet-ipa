import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine.dart';
import '../models.dart';

/// ---------------------------------------------------------------------------
/// 全局状态：出题配置 + 历史试卷 + 当前浏览的试卷
/// 历史试卷只存本机（shared_preferences），不上传、不写文件目录。
/// ---------------------------------------------------------------------------

const String _kHistoryKey = 'mwa_flutter_history_v1';

/// 页面索引（对应旧版 4 个 section）
class PageId {
  static const int home = 0;
  static const int config = 1;
  static const int preview = 2;
  static const int settings = 3;
}

class AppState extends ChangeNotifier {
  final Random _r = Random();
  SharedPreferences? _prefs;

  // ---------- 出题配置 ----------
  String grade = '2b';
  int cap = 100;
  int pages = 1;
  int score = 1;
  List<String> types = ['口算', '竖式', '填空'];
  Map<String, int> weights = {'口算': 60, '竖式': 25, '填空': 15};

  // ---------- 页面 / 试卷 ----------
  int pageIndex = PageId.home;
  List<Worksheet> history = [];
  Worksheet? currentSheet;
  int currentPage = 1;

  bool _busy = false;
  bool get busy => _busy;
  String status = ''; // 保存结果提示
  bool statusError = false;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_kHistoryKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        history = list
            .map((e) => Worksheet.fromJson((e as Map).cast<String, dynamic>()))
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
        _kHistoryKey,
        jsonEncode(history.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  void go(int idx) {
    pageIndex = idx;
    notifyListeners();
  }

  // ---------- 配置操作（从旧版 JS 逻辑移植） ----------
  void _normalizeWeights() {
    final keys = List<String>.from(types);
    if (keys.isEmpty) return;
    var w = keys.map((k) => max(5, weights[k] ?? 0)).toList();
    final sum = w.fold<int>(0, (a, b) => a + b);
    w = w.map((v) => (v * 100 / sum).round()).toList();
    w[w.length - 1] += 100 - w.fold<int>(0, (a, b) => a + b);
    weights = {for (var i = 0; i < keys.length; i++) keys[i]: w[i]};
  }

  void toggleType(String t) {
    if (types.contains(t)) {
      if (types.length == 1) return; // 至少保留一种
      types = types.where((x) => x != t).toList();
      weights.remove(t);
    } else {
      types = [...types, t];
      weights[t] = 20;
    }
    _normalizeWeights();
    notifyListeners();
  }

  void adjustWeight(String t, int d) {
    if (types.length < 2) return;
    final others = types.where((k) => k != t).toList();
    final target = max(5, min(90, (weights[t] ?? 0) + d));
    final rest = 100 - target;
    final oldRest =
        others.fold<int>(0, (s, k) => s + (weights[k] ?? 0)).clamp(1, 1 << 30);
    final nw = <String, int>{t: target};
    var acc = target;
    for (var i = 0; i < others.length; i++) {
      final k = others[i];
      if (i == others.length - 1) {
        nw[k] = max(5, 100 - acc);
      } else {
        nw[k] = max(5, (rest * (weights[k] ?? 0) / oldRest).round());
        acc += nw[k]!;
      }
    }
    weights = nw;
    _normalizeWeights();
    notifyListeners();
  }

  void setGrade(String v) {
    grade = v;
    final r = gradeById(v);
    if (cap > r.max) {
      final allowed = [10, 20, 100, 1000].where((n) => n <= r.max).toList();
      cap = allowed.isEmpty ? 10 : allowed.last;
    }
    notifyListeners();
  }

  void setCap(int v) {
    cap = v;
    notifyListeners();
  }

  void stepPages(int d) {
    pages = max(1, min(5, pages + d));
    notifyListeners();
  }

  void stepScore(int d) {
    score = max(1, min(10, score + d));
    notifyListeners();
  }

  /// 当前配置下各题型的题量（合计恒为 125）
  Map<String, int> get typeCounts => allocate(weights, kPerPage);

  // ---------- 生成 / 换一批 ----------
  Future<void> generateSheet() async {
    final rule = gradeById(grade);
    final effCap = min(rule.max, cap);
    final newPages = List<List<Question>>.generate(
      pages,
      (_) => generatePage(rule, effCap, Map<String, int>.from(weights), _r),
    );
    final now = DateTime.now();
    final item = Worksheet(
      id: now.microsecondsSinceEpoch,
      name: '${rule.label} · 第 ${history.length + 1} 份',
      gradeLabel: rule.label,
      score: score,
      createdAt:
          '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      config: SheetConfig(
        grade: grade,
        cap: cap,
        pages: pages,
        score: score,
        weights: Map<String, int>.from(weights),
      ),
      pages: newPages,
    );
    history = [item, ...history].take(12).toList();
    currentSheet = item;
    currentPage = 1;
    await _persist();
    pageIndex = PageId.preview;
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

  void openSheet(int id) {
    final found = history.where((x) => x.id == id).toList();
    if (found.isEmpty) return;
    currentSheet = found.first;
    currentPage = 1;
    pageIndex = PageId.preview;
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

  void setBusy(bool v, [String msg = '']) {
    _busy = v;
    if (msg.isNotEmpty) {
      status = msg;
      statusError = false;
    }
    notifyListeners();
  }

  void setStatus(String msg, [bool err = false]) {
    status = msg;
    statusError = err;
    notifyListeners();
  }
}
