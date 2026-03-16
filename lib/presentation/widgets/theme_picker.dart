// lib/presentation/widgets/theme_picker.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

class ThemePickerSheet extends ConsumerWidget {
  const ThemePickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text(
              'Choose theme',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 20),

            // Theme grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              physics: const NeverScrollableScrollPhysics(),
              children: MeloxTheme.values.map((theme) {
                final isActive = theme == current;
                return GestureDetector(
                  onTap: () {
                    ref.read(themeProvider.notifier).setTheme(theme);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? theme.primary
                            : AppTheme.divider,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Color circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isActive ? 38 : 32,
                          height: isActive ? 38 : 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.primary,
                            boxShadow: isActive
                                ? [
                              BoxShadow(
                                color: theme.primary.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ]
                                : null,
                          ),
                          child: isActive
                              ? const Icon(
                            Icons.check_rounded,
                            color: Colors.black,
                            size: 18,
                          )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          theme.label,
                          style: TextStyle(
                            color: isActive
                                ? theme.primary
                                : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Helper to show it anywhere
void showThemePicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const ThemePickerSheet(),
  );
}