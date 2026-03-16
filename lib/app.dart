// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melox/presentation/screens/home/home_screen.dart';
import 'package:melox/presentation/screens/splash/splash_screen.dart';

import 'application/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';


class MeloxApp extends ConsumerWidget {
  const MeloxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meloxTheme = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Melox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(meloxTheme: meloxTheme),      // always dark — no light theme
      home: const SplashScreen(),
    );
  }
}