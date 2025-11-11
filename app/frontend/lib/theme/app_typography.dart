import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(ColorScheme colorScheme) {
    final base = GoogleFonts.poppinsTextTheme();

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
      ),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium:
          base.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      labelSmall: base.labelSmall?.copyWith(fontWeight: FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
      bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w400),
    ).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }
}
