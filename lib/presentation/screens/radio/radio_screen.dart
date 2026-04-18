import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/radio_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/radio_station.dart';
import '../../widgets/radio_station_tile.dart';
import 'radio_player_bar.dart';

class RadioScreen extends ConsumerStatefulWidget {
  const RadioScreen({super.key});

  @override
  ConsumerState<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends ConsumerState<RadioScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  bool _showSearch = false;

  static const _genres = [
    'Bollywood', 'Punjabi', 'Pop', 'Hip Hop',
    'Jazz', 'Classical', 'Rock', 'Electronic',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final radioState = ref.watch(radioPlayerProvider);

    return Scaffold(
      body: Column(
        children: [
          // ── Header ────────────────────────────────────
          _buildHeader(accent),

          // ── Tab bar ───────────────────────────────────
          Container(
            color: AppTheme.background,
            child: TabBar(
              controller: _tabController,
              indicatorColor: accent,
              indicatorWeight: 2,
              labelColor: accent,
              unselectedLabelColor: AppTheme.textHint,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Top'),
                Tab(text: 'India'),
                Tab(text: 'Genres'),
                Tab(text: 'Favorites'),
              ],
            ),
          ),

          // ── Tab content ───────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TopStationsTab(),
                _IndianStationsTab(),
                _GenresTab(genres: _genres),
                _FavoritesTab(),
              ],
            ),
          ),

          // ── Radio player bar ──────────────────────────
          if (radioState.currentStation != null)
            RadioPlayerBar(state: radioState),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      color: AppTheme.background,
      child: Row(
        children: [
          if (!_showSearch) ...[
            const Expanded(
              child: Text(
                'Radio',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search_rounded),
              color: AppTheme.textSecondary,
              onPressed: () => setState(() => _showSearch = true),
            ),
          ] else ...[
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search stations...',
                  hintStyle:
                  const TextStyle(color: AppTheme.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceHigh,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textHint,
                    size: 20,
                  ),
                ),
                onChanged: (q) => setState(() {}),
              ),
            ),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _showSearch = false);
              },
              child: Text('Cancel',
                  style: TextStyle(color: accent)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Top stations tab ───────────────────────────────────────────

class _TopStationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final stationsAsync = ref.watch(topStationsProvider);

    return stationsAsync.when(
      data: (stations) => _StationsList(stations: stations),
      loading: () =>
          Center(child: CircularProgressIndicator(color: accent)),
      error: (e, _) => _ErrorWidget(onRetry: () => ref.invalidate(topStationsProvider)),
    );
  }
}

// ── Indian stations tab ────────────────────────────────────────

class _IndianStationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final stationsAsync = ref.watch(indianStationsProvider);

    return stationsAsync.when(
      data: (stations) => _StationsList(stations: stations),
      loading: () =>
          Center(child: CircularProgressIndicator(color: accent)),
      error: (e, _) => _ErrorWidget(onRetry: () => ref.invalidate(indianStationsProvider)),
    );
  }
}

// ── Genres tab ─────────────────────────────────────────────────

class _GenresTab extends ConsumerStatefulWidget {
  final List<String> genres;
  const _GenresTab({required this.genres});

  @override
  ConsumerState<_GenresTab> createState() => _GenresTabState();
}

class _GenresTabState extends ConsumerState<_GenresTab> {
  String _selectedGenre = 'Bollywood';

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final stationsAsync =
    ref.watch(genreStationsProvider(_selectedGenre.toLowerCase()));

    return Column(
      children: [
        // Genre chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            children: widget.genres.map((genre) {
              final isSelected = genre == _selectedGenre;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(genre),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedGenre = genre),
                  selectedColor: accent.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? accent
                        : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: isSelected ? accent : AppTheme.divider,
                  ),
                  backgroundColor: AppTheme.surface,
                ),
              );
            }).toList(),
          ),
        ),

        // Stations list
        Expanded(
          child: stationsAsync.when(
            data: (stations) => _StationsList(stations: stations),
            loading: () => Center(
                child: CircularProgressIndicator(color: accent)),
            error: (e, _) => _ErrorWidget(
                onRetry: () => ref.invalidate(
                    genreStationsProvider(_selectedGenre))),
          ),
        ),
      ],
    );
  }
}

// ── Favorites tab ──────────────────────────────────────────────

class _FavoritesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final favAsync = ref.watch(radioFavoritesProvider);

    return favAsync.when(
      data: (stations) => stations.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radio,
                size: 64, color: AppTheme.textHint),
            const SizedBox(height: 16),
            const Text(
              'No favorite stations',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap ♥ on any station to save it',
              style: TextStyle(
                  color: AppTheme.textHint, fontSize: 14),
            ),
          ],
        ),
      )
          : _StationsList(stations: stations),
      loading: () =>
          Center(child: CircularProgressIndicator(color: accent)),
      error: (e, _) => _ErrorWidget(
          onRetry: () => ref.invalidate(radioFavoritesProvider)),
    );
  }
}

// ── Stations list ──────────────────────────────────────────────

class _StationsList extends StatelessWidget {
  final List<RadioStation> stations;
  const _StationsList({required this.stations});

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) {
      return const Center(
        child: Text(
          'No stations found',
          style: TextStyle(color: AppTheme.textHint),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: stations.length,
      itemBuilder: (context, index) =>
          RadioStationTile(station: stations[index]),
    );
  }
}

// ── Error widget ───────────────────────────────────────────────

class _ErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 64, color: AppTheme.textHint),
          const SizedBox(height: 16),
          const Text(
            'Could not load stations',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
            ),
            child: const Text('Retry',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}