import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

ThemeData buildLightTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

  final colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryLight,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.primaryDark,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.primaryLight,
    onSecondaryContainer: AppColors.primary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    background: AppColors.background,
    onBackground: AppColors.textPrimary,
    error: AppColors.error,
    onError: Colors.white,
    // Material3 필수 값들
    surfaceContainerHighest: AppColors.surface,
    surfaceContainerHigh: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerLow: AppColors.surface,
    surfaceContainerLowest: AppColors.surface,
    surfaceBright: AppColors.surface,
    surfaceDim: AppColors.surface,
    outline: AppColors.divider,
    outlineVariant: AppColors.divider,
    tertiary: AppColors.success,
    onTertiary: Colors.white,
    scrim: Colors.black.withOpacity(0.4),
    shadow: Colors.black.withOpacity(0.06),
    inversePrimary: AppColors.primaryDark,
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.surface,
  );

  final textTheme = GoogleFonts.notoSansTextTheme().apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.divider,
    textTheme: textTheme.copyWith(
      // H1 대체
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      // H2 대체
      headlineSmall:
          textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      // Body
      bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 16),
      // Caption
      labelSmall: textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      elevation: 0,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryLight,
      labelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      side: BorderSide.none,
      selectedColor: AppColors.primaryLight,
      secondarySelectedColor: AppColors.primaryLight,
      disabledColor: AppColors.divider,
      shadowColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      hintStyle: TextStyle(color: AppColors.textMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.textSecondary),
    // Divider, ListTile, etc. 기본 톤 맞춤
    listTileTheme: ListTileThemeData(
      iconColor: AppColors.textSecondary,
      textColor: AppColors.textPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: Gaps.screen),
      dense: true,
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);

  // 다크 테마용 색상 정의
  const darkBackground = Color(0xFF121212);
  const darkSurface = Color(0xFF1E1E1E);
  const darkSurfaceContainer = Color(0xFF2C2C2C);
  const darkDivider = Color(0xFF3A3A3A);
  const darkTextPrimary = Color(0xFFE5E5E5);
  const darkTextSecondary = Color(0xFFB0B0B0);
  const darkTextMuted = Color(0xFF808080);

  final colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: Colors.white,
    secondary: AppColors.primaryLight,
    onSecondary: AppColors.primaryDark,
    secondaryContainer: AppColors.primaryDark,
    onSecondaryContainer: Colors.white,
    surface: darkSurface,
    onSurface: darkTextPrimary,
    background: darkBackground,
    onBackground: darkTextPrimary,
    error: AppColors.error,
    onError: Colors.white,
    // Material3 필수 값들
    surfaceContainerHighest: darkSurfaceContainer,
    surfaceContainerHigh: darkSurfaceContainer,
    surfaceContainer: darkSurfaceContainer,
    surfaceContainerLow: darkSurface,
    surfaceContainerLowest: darkSurface,
    surfaceBright: darkSurfaceContainer,
    surfaceDim: darkSurface,
    outline: darkDivider,
    outlineVariant: darkDivider,
    tertiary: AppColors.success,
    onTertiary: Colors.white,
    scrim: Colors.black.withOpacity(0.6),
    shadow: Colors.black.withOpacity(0.3),
    inversePrimary: AppColors.primary,
    inverseSurface: darkTextPrimary,
    onInverseSurface: darkBackground,
  );

  final textTheme = GoogleFonts.notoSansTextTheme().apply(
    bodyColor: darkTextPrimary,
    displayColor: darkTextPrimary,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: darkBackground,
    dividerColor: darkDivider,
    textTheme: textTheme.copyWith(
      // H1 대체
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      // H2 대체
      headlineSmall:
          textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      // Body
      bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 16),
      // Caption
      labelSmall: textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: darkTextSecondary,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      elevation: 0,
      foregroundColor: darkTextPrimary,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: darkTextPrimary,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: darkTextMuted,
      elevation: 0,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryDark.withOpacity(0.3),
      labelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      side: BorderSide.none,
      selectedColor: AppColors.primaryDark.withOpacity(0.3),
      secondarySelectedColor: AppColors.primaryDark.withOpacity(0.3),
      disabledColor: darkDivider,
      shadowColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      hintStyle: const TextStyle(color: darkTextMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    iconTheme: const IconThemeData(color: darkTextSecondary),
    // Divider, ListTile, etc. 기본 톤 맞춤
    listTileTheme: ListTileThemeData(
      iconColor: darkTextSecondary,
      textColor: darkTextPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: Gaps.screen),
      dense: true,
    ),
  );
}