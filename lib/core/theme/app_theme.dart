// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Theme definitions ─────────────────────────────────────────

enum MeloxTheme {
  purple,
  blue,
  green,
  red,
  gold,
  cyan,
}

extension MeloxThemeExtension on MeloxTheme {
  String get label => switch (this) {
    MeloxTheme.purple => 'Purple',
    MeloxTheme.blue   => 'Blue',
    MeloxTheme.green  => 'Green',
    MeloxTheme.red    => 'Red',
    MeloxTheme.gold   => 'Gold',
    MeloxTheme.cyan   => 'Cyan',
  };

  Color get primary => switch (this) {
    MeloxTheme.purple => const Color(0xFFBB86FC),
    MeloxTheme.blue   => const Color(0xFF6CB4FF),
    MeloxTheme.green  => const Color(0xFF4CAF7D),
    MeloxTheme.red    => const Color(0xFFFF6B6B),
    MeloxTheme.gold   => const Color(0xFFFFBB33),
    MeloxTheme.cyan   => const Color(0xFF00E5CC),
  };

  Color get primaryDim => switch (this) {
    MeloxTheme.purple => const Color(0xFF9B59B6),
    MeloxTheme.blue   => const Color(0xFF4A90D9),
    MeloxTheme.green  => const Color(0xFF388E5E),
    MeloxTheme.red    => const Color(0xFFE53935),
    MeloxTheme.gold   => const Color(0xFFE6A020),
    MeloxTheme.cyan   => const Color(0xFF00BFA5),
  };

  // Subtle tinted background per theme
  Color get surfaceTint => switch (this) {
    MeloxTheme.purple => const Color(0xFF1A1025),
    MeloxTheme.blue   => const Color(0xFF0D1520),
    MeloxTheme.green  => const Color(0xFF0A1A12),
    MeloxTheme.red    => const Color(0xFF1A0D0D),
    MeloxTheme.gold   => const Color(0xFF1A1500),
    MeloxTheme.cyan   => const Color(0xFF001A18),
  };
}

// ── AppTheme ──────────────────────────────────────────────────

class AppTheme {
  // Base colors — always dark
  static const Color background   = Color(0xFF0A0A0A);
  static const Color surface      = Color(0xFF141414);
  static const Color surfaceHigh  = Color(0xFF1E1E1E);
  static const Color textPrimary  = Color(0xFFFFFFFF);
  static const Color textSecondary= Color(0xFFB3B3B3);
  static const Color textHint     = Color(0xFF6B6B6B);
  static const Color divider      = Color(0xFF2A2A2A);
  static const Color error        = Color(0xFFCF6679);

  // Default accent (overridden by theme)
  static const Color primary      = Color(0xFFBB86FC);

  static ThemeData dark({MeloxTheme meloxTheme = MeloxTheme.purple}) {
    final accent = meloxTheme.primary;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          displayLarge:  TextStyle(color: textPrimary,    fontSize: 32, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: textPrimary,    fontSize: 28, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: textPrimary,    fontSize: 24, fontWeight: FontWeight.w600),
          headlineMedium:TextStyle(color: textPrimary,    fontSize: 20, fontWeight: FontWeight.w600),
          titleLarge:    TextStyle(color: textPrimary,    fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium:   TextStyle(color: textPrimary,    fontSize: 16, fontWeight: FontWeight.w500),
          titleSmall:    TextStyle(color: textSecondary,  fontSize: 14, fontWeight: FontWeight.w500),
          bodyLarge:     TextStyle(color: textPrimary,    fontSize: 16),
          bodyMedium:    TextStyle(color: textSecondary,  fontSize: 14),
          bodySmall:     TextStyle(color: textHint,       fontSize: 12),
          labelLarge:    TextStyle(color: textPrimary,    fontSize: 14, fontWeight: FontWeight.w600),
          labelSmall:    TextStyle(color: textHint,       fontSize: 11, letterSpacing: 0.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withOpacity(0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: accent);
          }
          return const IconThemeData(color: textHint);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(color: textHint, fontSize: 12);
        }),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: divider,
        thumbColor: accent,
        overlayColor: accent.withOpacity(0.15),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? accent : textHint),
        trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? accent.withOpacity(0.4)
            : surfaceHigh),
      ),
      dividerTheme: const DividerThemeData(color: divider, space: 1),
    );
  }
}