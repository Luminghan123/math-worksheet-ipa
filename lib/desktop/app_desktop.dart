import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';

import '../chinese/word_state.dart';
import '../models.dart';
import '../state/app_state.dart';
import 'pages/generate_page.dart';
import 'pages/history_page.dart';
import 'pages/settings_page.dart';
import 'pages/word_page.dart';

/// Windows 桌面端入口：Fluent UI（微软风格），左侧 NavigationView 四页。
class FluentMwApp extends StatelessWidget {
  final AppState state;
  final WordState wordState;
  const FluentMwApp({
    super.key,
    required this.state,
    required this.wordState,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: state),
        ChangeNotifierProvider<WordState>.value(value: wordState),
      ],
      child: FluentApp(
        title: '口算题卡',
        debugShowCheckedModeBanner: false,
        theme: FluentThemeData(
          accentColor: material.Colors.blue.toAccentColor(),
          brightness: material.Brightness.light,
        ),
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        localizationsDelegates: const [
          FluentLocalizations.delegate,
        ],
        home: const DesktopShell(),
      ),
    );
  }
}

/// 桌面四页：出题（口算） / 语文生字 / 历史试卷 / 设置（设置放在底部 footer）
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      pane: NavigationPane(
        selected: _selected,
        onChanged: (i) => setState(() => _selected = i),
        displayMode: PaneDisplayMode.expanded,
        header: const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            '口算题卡',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.calculator),
            title: const Text('出题'),
            body: const GeneratePage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.dictionary),
            title: const Text('语文生字'),
            body: const WordPage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.history),
            title: const Text('历史试卷'),
            body: const HistoryPage(),
          ),
        ],
        footerItems: [
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('设置'),
            body: const SettingsPage(),
          ),
        ],
      ),
    );
  }
}
