import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static bool _fontConfigured = false;

  static void _ensureFontConfig() {
    if (_fontConfigured) return;
    // السماح بتحميل خط Cairo من Google Fonts عند أول تشغيل
    // (allowRuntimeFetching=true هو الافتراضي، لا نحتاج لتغييره)
    _fontConfigured = true;
  }

  static String? _safeCairoFontFamily() {
    try {
      return GoogleFonts.cairo().fontFamily;
    } catch (_) {
      return null; // الرجوع لخط النظام الافتراضي بدلاً من رمي خطأ يوقف التطبيق
    }
  }

  static TextTheme _safeCairoTextTheme(TextTheme base) {
    try {
      return GoogleFonts.cairoTextTheme(base);
    } catch (_) {
      return base;
    }
  }

  static ThemeData light(Color seed, double fontScale) {
    _ensureFontConfig();
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
      scaffoldBackgroundColor: AppColors.lightBg,
      fontFamily: _safeCairoFontFamily(),
    );
    return _apply(base, seed, fontScale, isDark: false);
  }

  static ThemeData dark(Color seed, double fontScale) {
    _ensureFontConfig();
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      scaffoldBackgroundColor: AppColors.darkBg,
      fontFamily: _safeCairoFontFamily(),
    );
    return _apply(base, seed, fontScale, isDark: true);
  }

  static ThemeData _apply(ThemeData base, Color seed, double fontScale, {required bool isDark}) {
    final textTheme = _safeCairoTextTheme(base.textTheme).apply(
      bodyColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      displayColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      fontSizeFactor: fontScale,
    );

    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return base.copyWith(
      textTheme: textTheme,
      cardColor: cardColor,
      dividerColor: borderColor,
      appBarTheme: AppBarTheme(
        backgroundColor: base.scaffoldBackgroundColor,
        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderColor),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: seed, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: seed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: seed,
        unselectedItemColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightBg,
        side: BorderSide(color: borderColor),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
