import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/library_provider.dart';
import '../../../application/providers/player_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/theme_picker.dart';
import '../equalizer/equalizer_screen.dart';
import '../library/library_screen.dart';
import '../playlists/playlists_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    LibraryScreen(),
    PlaylistsScreen(),
    EqualizerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final playerState = ref.watch(playerProvider);
    final hasSong = playerState.currentSong != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Melox',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            color: AppTheme.textSecondary,
            onPressed: () {
              if (_currentIndex == 0) {
                showSearch(
                  context: context,
                  delegate: SongSearchDelegate(ref),
                ).then((_) {
                  ref.read(searchQueryProvider.notifier).state = '';
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            color: AppTheme.textSecondary,
            onPressed: () => showThemePicker(context),
            tooltip: 'Change theme',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSong) const MiniPlayer(),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            backgroundColor: AppTheme.surface,
            indicatorColor: accent.withOpacity(0.2),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music, color: accent),
                label: 'Library',
              ),
              NavigationDestination(
                icon: const Icon(Icons.queue_music_outlined),
                selectedIcon: Icon(Icons.queue_music, color: accent),
                label: 'Playlists',
              ),
              NavigationDestination(
                icon: const Icon(Icons.equalizer_outlined),
                selectedIcon: Icon(Icons.equalizer, color: accent),
                label: 'Equalizer',
              ),
            ],
          ),
        ],
      ),
    );
  }
}