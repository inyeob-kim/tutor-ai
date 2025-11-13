import 'package:flutter/material.dart';

/// ===== Design Tokens (Colors) =====
class AppColors {
  // Brand
  static const primary = Color(0xFF3182F6);
  static const primaryDark = Color(0xFF1E6FE8);
  static const primaryLight = Color(0xFFEBF4FF);

  // Surfaces
  static const background = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const divider = Color(0xFFEDEFF2);

  // Text
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);

  // States
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}

/// ===== Spacing / Radius Tokens =====
class Gaps {
  /// 화면 기본 padding (16–20 권장) — 기본 20
  static const screen = 20.0;

  /// 카드 간 간격 (12–16) — 기본 16
  static const card = 16.0;

  /// Row 간격 (8–12) — 기본 10
  static const row = 10.0;

  /// 카드 내부 padding (16–20) — 기본 20
  static const cardPad = 20.0;
}

class Radii {
  /// 카드 라운드 (16–20) — 기본 18
  static const card = 18.0;

  /// 칩 라운드 12
  static const chip = 12.0;

  /// 아이콘 라운드 8
  static const icon = 8.0;
}
