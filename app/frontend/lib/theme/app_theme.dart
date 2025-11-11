import 'package:flutter/material.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const seed = Color(0xFF2563EB);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      surface: Colors.white,
      primary: seed,
    );
    final textTheme = AppTypography.textTheme(colorScheme);

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.all(textTheme.labelMedium),
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        indicatorColor: seed.withValues(alpha: 0.12),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.2),
      splashFactory: InkSparkle.splashFactory,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      // 전역 스크롤 물리학 설정 (기본값으로 사용)
      scrollbarTheme: ScrollbarThemeData(
        thickness: MaterialStateProperty.all(4.0),
        radius: const Radius.circular(4),
      ),
    );
  }
}
