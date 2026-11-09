import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// 视觉体系：沿用旧版 index.html 的蓝紫渐变 + 浅灰底 + 白卡片
/// ---------------------------------------------------------------------------
const Color kBg = Color(0xFFF3F5FB);
const Color kCard = Color(0xFFFFFFFF);
const Color kInk = Color(0xFF1B2030);
const Color kInk2 = Color(0xFF5B6276);
const Color kInk3 = Color(0xFF98A0B3);
const Color kLine = Color(0xFFEDF0F6);
const Color kBrand = Color(0xFF4C6FFF);
const Color kBrand2 = Color(0xFF5B7CFA);
const Color kSoft = Color(0xFFEEF2FF);
const Color kAccent = Color(0xFFFF9A55);
const Color kOk = Color(0xFF12A37B);
const Color kOkSoft = Color(0xFFE9F8F2);
const Color kDanger = Color(0xFFEE4A4A);
const Color kDangerSoft = Color(0xFFFFF0F0);

const LinearGradient kGrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF5B7CFA), Color(0xFF4C63E6)],
);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kBrand,
      brightness: Brightness.light,
    ).copyWith(primary: kBrand, surface: kBg),
  );
  return base.copyWith(
    scaffoldBackgroundColor: kBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: kInk,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: kInk,
      ),
    ),
    dividerTheme: const DividerThemeData(color: kLine, thickness: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kBrand),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(backgroundColor: kBrand),
    ),
  );
}
