import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'chinese/word_state.dart';
import 'desktop/app_desktop.dart' show FluentMwApp;
import 'pages/config_page.dart';
import 'pages/home_page.dart';
import 'pages/preview_page.dart';
import 'pages/settings_page.dart';
import 'pages/word_page.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load(); // 口算历史试卷先读进来，避免首帧空白
  final wordState = WordState();
  await wordState.load(); // 生字练习卷历史：独立 key，互不影响
  // Windows 桌面端走 Fluent UI；iOS 等移动端保留原 Material 体验
  if (Platform.isWindows) {
    runApp(FluentMwApp(state: state, wordState: wordState));
  } else {
    runApp(MwApp(state: state, wordState: wordState));
  }
}

class MwApp extends StatelessWidget {
  final AppState state;
  final WordState wordState;
  const MwApp({super.key, required this.state, required this.wordState});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: state),
        ChangeNotifierProvider<WordState>.value(value: wordState),
      ],
      child: MaterialApp(
        title: '口算题卡',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const MainShell(),
      ),
    );
  }
}

/// 单壳五页切换（与旧版 show('page-xxx') 一致，无路由栈歧义）
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final idx = context.select<AppState, int>((s) => s.pageIndex);
    switch (idx) {
      case PageId.config:
        return const ConfigPage();
      case PageId.preview:
        return const PreviewPage();
      case PageId.settings:
        return const SettingsPage();
      case PageId.word:
        return const WordPage();
      default:
        return const HomePage();
    }
  }
}
