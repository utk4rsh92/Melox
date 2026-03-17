// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum MeloxTheme {
  lime,
  purple,
  green,
  orange,
  yellow,
  pink,
}

extension MeloxThemeExtension on MeloxTheme {
  String get label => switch (this) {
    MeloxTheme.lime   => 'Lime',
    MeloxTheme.purple => 'Purple',
    MeloxTheme.green  => 'Green',
    MeloxTheme.orange => 'Orange',
    MeloxTheme.yellow => 'Yellow',
    MeloxTheme.pink   => 'Pink',
  };

  Color get primary => switch (this) {
    MeloxTheme.lime   => const Color(0xFFC6F54E),
    MeloxTheme.purple => const Color(0xFFA125DF),
    MeloxTheme.green  => const Color(0xFF31FF6A),
    MeloxTheme.orange => const Color(0xFFE25129),
    MeloxTheme.yellow => const Color(0xFFFEE605),
    MeloxTheme.pink   => const Color(0xFFFE0183),
  };

  Color get primaryDim => switch (this) {
    MeloxTheme.lime   => const Color(0xFF8FB52E),
    MeloxTheme.purple => const Color(0xFF7A1AAA),
    MeloxTheme.green  => const Color(0xFF1FCC4E),
    MeloxTheme.orange => const Color(0xFFB33D1C),
    MeloxTheme.yellow => const Color(0xFFCDB800),
    MeloxTheme.pink   => const Color(0xFFCC0066),
  };

  Color get surfaceTint => switch (this) {
    MeloxTheme.lime   => const Color(0xFF0F1500),
    MeloxTheme.purple => const Color(0xFF1A0A25),
    MeloxTheme.green  => const Color(0xFF001A0A),
    MeloxTheme.orange => const Color(0xFF1A0A00),
    MeloxTheme.yellow => const Color(0xFF1A1600),
    MeloxTheme.pink   => const Color(0xFF1A0010),
  };

  // Smart contrast — black for bright colors, white for dark ones
  Color get onPrimary {
    final luminance = primary.computeLuminance();
    return luminance > 0.4 ? Colors.black : Colors.white;
  }
}

// ── AppTheme ───────────────────────────────────────────────────

class AppTheme {
  static const Color background    = Color(0xFF0A0A0A);
  static const Color surface       = Color(0xFF141414);
  static const Color surfaceHigh   = Color(0xFF1E1E1E);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textHint      = Color(0xFF6B6B6B);
  static const Color divider       = Color(0xFF2A2A2A);
  static const Color error         = Color(0xFFCF6679);

  // Default accent — overridden by active theme
  static const Color primary = Color(0xFFC6F54E);

  static ThemeData dark({MeloxTheme meloxTheme = MeloxTheme.lime}) {
    final accent = meloxTheme.primary;
    final onAccent = meloxTheme.onPrimary;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: accent,
        onPrimary: onAccent,
        secondary: accent,
        onSecondary: onAccent,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          displayLarge:   TextStyle(color: textPrimary,    fontSize: 32, fontWeight: FontWeight.w700),
          displayMedium:  TextStyle(color: textPrimary,    fontSize: 28, fontWeight: FontWeight.w700),
          headlineLarge:  TextStyle(color: textPrimary,    fontSize: 24, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(color: textPrimary,    fontSize: 20, fontWeight: FontWeight.w600),
          titleLarge:     TextStyle(color: textPrimary,    fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium:    TextStyle(color: textPrimary,    fontSize: 16, fontWeight: FontWeight.w500),
          titleSmall:     TextStyle(color: textSecondary,  fontSize: 14, fontWeight: FontWeight.w500),
          bodyLarge:      TextStyle(color: textPrimary,    fontSize: 16),
          bodyMedium:     TextStyle(color: textSecondary,  fontSize: 14),
          bodySmall:      TextStyle(color: textHint,       fontSize: 12),
          labelLarge:     TextStyle(color: textPrimary,    fontSize: 14, fontWeight: FontWeight.w600),
          labelSmall:     TextStyle(color: textHint,       fontSize: 11, letterSpacing: 0.5),
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
        indicatorColor: accent.withValues(alpha: 0.15),
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
        overlayColor: accent.withValues(alpha: 0.15),
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
            ? accent.withValues(alpha: 0.4)
            : surfaceHigh),
      ),
      dividerTheme: const DividerThemeData(color: divider, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent, // ← ensures text/icon readable on all colors
        ),
      ),
    );
  }
}