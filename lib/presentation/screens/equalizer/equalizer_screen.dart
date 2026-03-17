// lib/presentation/screens/equalizer/equalizer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/eq_provider.dart';
import '../../../domain/entities/eq_preset.dart';
import '../../../core/theme/app_theme.dart';

class EqualizerScreen extends ConsumerStatefulWidget {
  const EqualizerScreen({super.key});

  @override
  ConsumerState<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends ConsumerState<EqualizerScreen> {
  final List<String> _bandLabels = ['60Hz', '230Hz', '910Hz', '4kHz', '14kHz'];
  late List<int> _localLevels;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _localLevels = List.filled(5, 0);
  }

  void _initLevels(EQPreset? preset) {
    if (!_initialized && preset != null) {
      _localLevels = List<int>.from(preset.bandLevels);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary; // ← add
    final activePreset = ref.watch(eqProvider);
    final presetsAsync = ref.watch(eqPresetsProvider);

    _initLevels(activePreset);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            snap: true,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text(
                'Equalizer',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              titlePadding: EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // EQ Band sliders
                _EQBandsWidget(
                  levels: _localLevels,
                  bandLabels: _bandLabels,
                  accent: accent, // ← pass accent
                  onBandChanged: (index, value) {
                    setState(() => _localLevels[index] = value);
                    ref.read(eqProvider.notifier).updateBandLevel(index, value);
                  },
                ),

                const SizedBox(height: 8),

                // Save preset button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: OutlinedButton.icon(
                    onPressed: () => _showSavePresetDialog(context, ref, accent),
                    icon: Icon(Icons.save_outlined, color: accent, size: 18),
                    label: Text(
                      'Save as preset',
                      style: TextStyle(color: accent),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accent), // ← themed
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Presets',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                presetsAsync.when(
                  data: (presets) => _PresetsList(
                    presets: presets,
                    activePreset: activePreset,
                    accent: accent, // ← pass accent
                    onSelect: (preset) {
                      setState(() {
                        _localLevels = List<int>.from(preset.bandLevels);
                      });
                      ref.read(eqProvider.notifier).selectPreset(preset);
                    },
                    onDelete: (preset) {
                      ref.read(eqProvider.notifier).deletePreset(preset);
                    },
                  ),
                  loading: () => Center(
                    child: CircularProgressIndicator(color: accent), // ← themed
                  ),
                  error: (e, _) => Center(child: Text('$e')),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSavePresetDialog(BuildContext context, WidgetRef ref, Color accent) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Save preset',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Preset name',
            hintStyle: const TextStyle(color: AppTheme.textHint),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accent), // ← themed
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(eqProvider.notifier).saveCustomPreset(
                  EQPreset(
                    name: name,
                    bandLevels: List<int>.from(_localLevels),
                  ),
                );
                ref.invalidate(eqPresetsProvider);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Preset "$name" saved'),
                    backgroundColor: AppTheme.surfaceHigh,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Text('Save', style: TextStyle(color: accent)), // ← themed
          ),
        ],
      ),
    );
  }
}

// ── EQ Bands widget ────────────────────────────────────────────

class _EQBandsWidget extends StatelessWidget {
  final List<int> levels;
  final List<String> bandLabels;
  final Color accent;
  final void Function(int index, int value) onBandChanged;

  const _EQBandsWidget({
    required this.levels,
    required this.bandLabels,
    required this.accent,
    required this.onBandChanged,
  });

  static const int _minDb = -1500;
  static const int _maxDb = 1500;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // dB value labels
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(5, (i) {
                    final db = (levels[i] / 100).toStringAsFixed(0);
                    final isPositive = levels[i] > 0;
                    return Text(
                      '${isPositive ? '+' : ''}$db',
                      style: TextStyle(
                        color: isPositive
                            ? accent // ← themed
                            : levels[i] < 0
                            ? AppTheme.textSecondary
                            : AppTheme.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // dB axis labels
                const Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('+15',
                        style: TextStyle(color: AppTheme.textHint, fontSize: 10)),
                    Text('0',
                        style: TextStyle(color: AppTheme.textHint, fontSize: 10)),
                    Text('-15',
                        style: TextStyle(color: AppTheme.textHint, fontSize: 10)),
                  ],
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Stack(
                    children: [
                      // Zero line
                      Positioned(
                        top: 110,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 0.5,
                          color: AppTheme.divider,
                        ),
                      ),
                      // Band sliders
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(5, (i) {
                          return _VerticalBandSlider(
                            value: levels[i].toDouble(),
                            min: _minDb.toDouble(),
                            max: _maxDb.toDouble(),
                            accent: accent, // ← pass accent
                            onChanged: (val) => onBandChanged(i, val.round()),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Frequency labels
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: bandLabels
                      .map((label) => Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 11,
                    ),
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Vertical band slider ───────────────────────────────────────

class _VerticalBandSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final Color accent;
  final ValueChanged<double> onChanged;

  const _VerticalBandSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 220,
      child: RotatedBox(
        quarterTurns: 3,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: accent,                        // ← themed
            inactiveTrackColor: AppTheme.divider,
            thumbColor: accent,                              // ← themed
            overlayColor: accent.withValues(alpha: 0.15),   // ← themed
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

// ── Presets list ───────────────────────────────────────────────

class _PresetsList extends StatelessWidget {
  final List<EQPreset> presets;
  final EQPreset? activePreset;
  final Color accent;
  final ValueChanged<EQPreset> onSelect;
  final ValueChanged<EQPreset> onDelete;

  const _PresetsList({
    required this.presets,
    required this.activePreset,
    required this.accent,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: presets.length,
      separatorBuilder: (_, __) =>
      const Divider(color: AppTheme.divider, height: 1),
      itemBuilder: (context, index) {
        final preset = presets[index];
        final isActive = activePreset?.name == preset.name;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? accent.withValues(alpha: 0.15) // ← themed
                  : AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isActive ? Icons.equalizer_rounded : Icons.music_note_outlined,
              color: isActive ? accent : AppTheme.textHint, // ← themed
              size: 20,
            ),
          ),
          title: Text(
            preset.name,
            style: TextStyle(
              color: isActive ? accent : AppTheme.textPrimary, // ← themed
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            preset.isBuiltIn ? 'Built-in' : 'Custom',
            style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive)
                Icon(
                  Icons.check_circle_rounded,
                  color: accent, // ← themed
                  size: 20,
                ),
              if (!preset.isBuiltIn)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.error,
                    size: 20,
                  ),
                  onPressed: () => onDelete(preset),
                ),
            ],
          ),
          onTap: () => onSelect(preset),
        );
      },
    );
  }
}