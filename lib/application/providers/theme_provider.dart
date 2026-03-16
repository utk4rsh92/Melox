import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';

class ThemeNotifier extends Notifier<MeloxTheme> {
  static const _key = 'active_theme';

  @override
  MeloxTheme build() {
    _load();
    return MeloxTheme.purple; // default
  }

  Future<void> _load() async {
    final box = Hive.box('settings');
    final saved = box.get(_key, defaultValue: 'purple') as String;
    state = MeloxTheme.values.firstWhere(
          (t) => t.name == saved,
      orElse: () => MeloxTheme.purple,
    );
  }

  Future<void> setTheme(MeloxTheme theme) async {
    final box = Hive.box('settings');
    await box.put(_key, theme.name);
    state = theme;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, MeloxTheme>(
  ThemeNotifier.new,
);