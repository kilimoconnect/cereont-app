import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cereont's visual identity — a modern, professional dark palette aligned with
/// the marketing site: deep navy surfaces, a confident blue primary and a cyan
/// accent (Linear / Stripe / OpenAI feel), set in Inter.
class AppColors {
  // Brand — kept under the historic `brand`/`accent` names so every screen that
  // already references them picks up the new identity automatically.
  static const Color brand = Color(0xFF2563EB); // primary blue
  static const Color brandDeep = Color(0xFF1D4ED8);
  static const Color accent = Color(0xFF38BDF8); // cyan

  // Dark surfaces (deep navy)
  static const Color bgDark = Color(0xFF050816);
  static const Color surfaceDark = Color(0xFF0C1426);
  static const Color surfaceDark2 = Color(0xFF131E36);
  static const Color borderDark = Color(0xFF1E2B48);
  static const Color textDark = Color(0xFFEAF0FA);
  static const Color mutedDark = Color(0xFF93A1B8);

  // Light surfaces
  static const Color bgLight = Color(0xFFF5F7FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLight2 = Color(0xFFEEF2F8);
  static const Color borderLight = Color(0xFFE1E7F0);
  static const Color textLight = Color(0xFF0B1220);
  static const Color mutedLight = Color(0xFF5B6779);

  // Semantic (shared across themes)
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
}

class AppTheme {
  static const _font = 'Inter';

  /// System UI overlay so the status/nav bars match the app chrome.
  static const SystemUiOverlayStyle darkOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bgDark,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = const ColorScheme.dark(
      primary: AppColors.brand,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Color(0xFF04121F),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textDark,
      error: AppColors.danger,
      outline: AppColors.borderDark,
    );
    return _common(
      base,
      scheme,
      bg: AppColors.bgDark,
      surface: AppColors.surfaceDark,
      surface2: AppColors.surfaceDark2,
      border: AppColors.borderDark,
      text: AppColors.textDark,
      muted: AppColors.mutedDark,
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = const ColorScheme.light(
      primary: AppColors.brand,
      onPrimary: Colors.white,
      secondary: AppColors.brandDeep,
      onSecondary: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textLight,
      error: AppColors.danger,
      outline: AppColors.borderLight,
    );
    return _common(
      base,
      scheme,
      bg: AppColors.bgLight,
      surface: AppColors.surfaceLight,
      surface2: AppColors.surfaceLight2,
      border: AppColors.borderLight,
      text: AppColors.textLight,
      muted: AppColors.mutedLight,
    );
  }

  static ThemeData _common(
    ThemeData base,
    ColorScheme scheme, {
    required Color bg,
    required Color surface,
    required Color surface2,
    required Color border,
    required Color text,
    required Color muted,
  }) {
    final textTheme = _text(base.textTheme, text, muted);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      canvasColor: bg,
      dividerColor: border,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: text,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 19),
        systemOverlayStyle:
            bg == AppColors.bgDark ? darkOverlay : SystemUiOverlayStyle.dark,
      ),
      chipTheme: _chip(surface2, border, text),
      inputDecorationTheme: _input(surface2, border, muted),
      filledButtonTheme: FilledButtonThemeData(style: _filled()),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _filled()),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
              fontFamily: _font, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: const TextStyle(
              fontFamily: _font, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.brand.withValues(alpha: 0.16),
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? AppColors.brand : muted,
              size: 24,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontFamily: _font,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: s.contains(WidgetState.selected) ? AppColors.brand : muted,
            )),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: text,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surface2,
        contentTextStyle: TextStyle(fontFamily: _font, color: text),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.brand),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : muted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.brand : surface2),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        textStyle: TextStyle(fontFamily: _font, color: text, fontSize: 12),
      ),
    );
  }

  static ButtonStyle _filled() => FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.brand.withValues(alpha: 0.4),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
            fontFamily: _font, fontWeight: FontWeight.w600, fontSize: 14.5),
      );

  static TextTheme _text(TextTheme base, Color color, Color muted) {
    return base.apply(fontFamily: _font, bodyColor: color, displayColor: color).copyWith(
          displaySmall: base.displaySmall
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.0),
          headlineMedium: base.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.8),
          headlineSmall: base.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6),
          titleLarge: base.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleMedium: base.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          bodyLarge: base.bodyLarge?.copyWith(height: 1.45),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
          bodySmall: base.bodySmall?.copyWith(color: muted, height: 1.4),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        );
  }

  static ChipThemeData _chip(Color bg, Color border, Color text) {
    return ChipThemeData(
      backgroundColor: bg,
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: TextStyle(
          fontFamily: _font,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: text),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  static InputDecorationTheme _input(Color fill, Color border, Color muted) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle:
          TextStyle(fontFamily: _font, color: muted.withValues(alpha: 0.8)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }
}
