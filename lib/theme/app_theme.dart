import 'package:flutter/material.dart';

/// Cereont's visual identity — a calm, executive dark palette with a
/// signature teal accent, plus a matching light theme.
class AppColors {
  static const Color brand = Color(0xFF13B5A6); // Cereont teal
  static const Color brandDeep = Color(0xFF0E8C82);
  static const Color accent = Color(0xFF6C8CFF);

  // Dark surfaces
  static const Color bgDark = Color(0xFF0B0F14);
  static const Color surfaceDark = Color(0xFF131A22);
  static const Color surfaceDark2 = Color(0xFF1B2530);
  static const Color borderDark = Color(0xFF243040);
  static const Color textDark = Color(0xFFECF1F6);
  static const Color mutedDark = Color(0xFF8C99A8);

  // Light surfaces
  static const Color bgLight = Color(0xFFF4F6F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E7EE);
  static const Color textLight = Color(0xFF141A21);
  static const Color mutedLight = Color(0xFF64707E);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = const ColorScheme.dark(
      primary: AppColors.brand,
      secondary: AppColors.accent,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textDark,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: scheme,
      textTheme: _text(base.textTheme, AppColors.textDark, AppColors.mutedDark),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textDark,
      ),
      dividerColor: AppColors.borderDark,
      chipTheme: _chip(AppColors.surfaceDark2, AppColors.borderDark),
      inputDecorationTheme: _input(AppColors.surfaceDark2, AppColors.borderDark),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.brand,
        unselectedItemColor: AppColors.mutedDark,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = const ColorScheme.light(
      primary: AppColors.brandDeep,
      secondary: AppColors.accent,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textLight,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: scheme,
      textTheme:
          _text(base.textTheme, AppColors.textLight, AppColors.mutedLight),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textLight,
      ),
      dividerColor: AppColors.borderLight,
      chipTheme: _chip(const Color(0xFFEDF1F6), AppColors.borderLight),
      inputDecorationTheme:
          _input(AppColors.surfaceLight, AppColors.borderLight),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.brandDeep,
        unselectedItemColor: AppColors.mutedLight,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandDeep,
        foregroundColor: Colors.white,
      ),
    );
  }

  static TextTheme _text(TextTheme base, Color color, Color muted) {
    return base
        .apply(bodyColor: color, displayColor: color)
        .copyWith(
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          bodySmall: base.bodySmall?.copyWith(color: muted),
        );
  }

  static ChipThemeData _chip(Color bg, Color border) {
    return ChipThemeData(
      backgroundColor: bg,
      side: BorderSide(color: border),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }

  static InputDecorationTheme _input(Color fill, Color border) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
    );
  }
}
