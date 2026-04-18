import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/lyric_line.dart';
import '../../domain/entities/song.dart';
import 'player_provider.dart';

// State for lyrics
class LyricsState {
  final List<LyricLine> lines;
  final bool isLoading;
  final bool hasError;
  final bool notFound;
  final String? songTitle; // track which song lyrics belong to

  const LyricsState({
    this.lines = const [],
    this.isLoading = false,
    this.hasError = false,
    this.notFound = false,
    this.songTitle,
  });

  LyricsState copyWith({
    List<LyricLine>? lines,
    bool? isLoading,
    bool? hasError,
    bool? notFound,
    String? songTitle,
  }) => LyricsState(
    lines: lines ?? this.lines,
    isLoading: isLoading ?? this.isLoading,
    hasError: hasError ?? this.hasError,
    notFound: notFound ?? this.notFound,
    songTitle: songTitle ?? this.songTitle,
  );
}

class LyricsNotifier extends Notifier<LyricsState> {
  String _currentCleanTitle  = '';
  String _currentCleanArtist = '';
  @override
  LyricsState build() {
    // Listen for song changes
    ref.listen(playerProvider.select((s) => s.currentSong), (prev, next) {
      if (next != null && next.title != state.songTitle) {
        fetchLyrics(next);
      }
    });

    // ← Also fetch immediately for currently playing song
    final currentSong = ref.read(playerProvider).currentSong;
    if (currentSong != null) {
      Future.microtask(() => fetchLyrics(currentSong));
    }

    return const LyricsState();
  }

  Future<void> fetchLyrics(Song song) async {
    if (state.songTitle == song.title && state.lines.isNotEmpty) return;

    state = state.copyWith(
      isLoading: true,
      hasError: false,
      notFound: false,
      songTitle: song.title,
      lines: [],
    );

    try {
      // Smart extraction
      final cleanTitle  = _extractTitle(song.title);
      final cleanArtist = _extractArtist(song.title, song.artist);

      debugPrint('Raw title:  "${song.title}"');
      debugPrint('Raw artist: "${song.artist}"');
      debugPrint('Clean title:  "$cleanTitle"');
      debugPrint('Clean artist: "$cleanArtist"');

      List<LyricLine>? lines;
      if (state.songTitle == song.title && state.lines.isNotEmpty) return;

      // Store for use in _pickBestMatch
      _currentCleanTitle  = _extractTitle(song.title);
      _currentCleanArtist = _extractArtist(song.title, song.artist);

      // ... rest of fetchLyrics unchanged

      // Strategy 1 — artist + title (most reliable)
      if (cleanArtist.isNotEmpty) {
        lines = await _searchLyrics('$cleanArtist $cleanTitle');
      }

      // Strategy 2 — title + artist reversed
      if (lines == null && cleanArtist.isNotEmpty) {
        lines = await _searchLyrics('$cleanTitle $cleanArtist');
      }

      // Strategy 3 — title only
      if (lines == null && cleanTitle.isNotEmpty) {
        lines = await _searchLyrics(cleanTitle);
      }

      // Strategy 4 — try original title cleaned (no split)
      if (lines == null) {
        final fallback = _cleanString(song.title);
        if (fallback != cleanTitle) {
          lines = await _searchLyrics(fallback);
        }
      }

      if (lines != null && lines.isNotEmpty) {
        state = state.copyWith(lines: lines, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, notFound: true);
      }
    } catch (e) {
      debugPrint('Lyrics fetch error: $e');
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }

// Replace _searchLyrics method in lyrics_provider.dart

  Future<List<LyricLine>?> _searchLyrics(String query) async {
    try {
      final uri = Uri.parse(
        'https://lrclib.net/api/search?q=${Uri.encodeComponent(query)}',
      );

      debugPrint('Trying: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Lrclib-Client': 'Melox/1.0.0 (Android)',
          'User-Agent': 'Melox/1.0.0',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final List<dynamic> results = jsonDecode(response.body);
      if (results.isEmpty) return null;

      return _pickBestMatch(results);
    } catch (e) {
      debugPrint('Search error: $e');
      return null;
    }
  }

// ── Pick best matching result ──────────────────────────────────

  List<LyricLine>? _pickBestMatch(List<dynamic> results) {
    // Score each result based on how well it matches
    int bestScore = -1;
    Map<String, dynamic>? bestResult;

    for (final r in results) {
      final resultTitle  = (r['trackName']  as String? ?? '').toLowerCase().trim();
      final resultArtist = (r['artistName'] as String? ?? '').toLowerCase().trim();
      final hasSynced = r['syncedLyrics'] != null &&
          (r['syncedLyrics'] as String).isNotEmpty;
      final hasPlain = r['plainLyrics'] != null &&
          (r['plainLyrics'] as String).isNotEmpty;

      // Skip results with no lyrics at all
      if (!hasSynced && !hasPlain) continue;

      int score = 0;

      // Get our cleaned values for comparison
      final ourTitle  = _currentCleanTitle.toLowerCase().trim();
      final ourArtist = _currentCleanArtist.toLowerCase().trim();

      // ── Title matching ─────────────────────────────────
      if (resultTitle == ourTitle) {
        score += 100; // exact match
      } else if (resultTitle.contains(ourTitle) || ourTitle.contains(resultTitle)) {
        score += 60;  // partial match
      } else {
        // Word overlap score
        final ourWords    = ourTitle.split(' ').where((w) => w.length > 2).toSet();
        final resultWords = resultTitle.split(' ').where((w) => w.length > 2).toSet();
        final overlap     = ourWords.intersection(resultWords).length;
        if (overlap == 0) continue; // no title overlap — skip entirely
        score += overlap * 15;
      }

      // ── Artist matching ────────────────────────────────
      if (ourArtist.isNotEmpty) {
        if (resultArtist == ourArtist) {
          score += 80;
        } else if (resultArtist.contains(ourArtist) ||
            ourArtist.contains(resultArtist)) {
          score += 40;
        } else {
          // Check if any artist word matches
          final ourArtistWords    = ourArtist.split(' ').where((w) => w.length > 2).toSet();
          final resultArtistWords = resultArtist.split(' ').where((w) => w.length > 2).toSet();
          final artistOverlap     = ourArtistWords.intersection(resultArtistWords).length;
          score += artistOverlap * 20;
        }
      }

      // ── Prefer synced over plain ───────────────────────
      if (hasSynced) score += 30;

      debugPrint(
          '  Candidate: "$resultTitle" by "$resultArtist" | score: $score | synced: $hasSynced');

      if (score > bestScore) {
        bestScore = score;
        bestResult = r as Map<String, dynamic>;
      }
    }

    // Minimum score threshold — reject if too low
    if (bestScore < 60 || bestResult == null) {
      debugPrint('No good match found (best score: $bestScore)');
      return null;
    }

    debugPrint(
        'Best match: "${bestResult['trackName']}" by "${bestResult['artistName']}" (score: $bestScore)');

    final syncedLyrics = bestResult['syncedLyrics'] as String?;
    final plainLyrics  = bestResult['plainLyrics']  as String?;

    if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
      return _parseLrc(syncedLyrics);
    } else if (plainLyrics != null && plainLyrics.isNotEmpty) {
      return plainLyrics
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .map((l) => LyricLine(timestamp: Duration.zero, text: l.trim()))
          .toList();
    }

    return null;
  }

  String _cleanString(String input) {
    var s = input.trim();

    // Remove file extensions
    s = s.replaceAll(
        RegExp(r'\.(mp3|flac|m4a|wav|ogg|aac|opus)$',
            caseSensitive: false), '');

    // ← NEW: Remove website domains — e.g. Riskyjatt.com, DJPunjab.com
    s = s.replaceAll(
        RegExp(r'\b[\w]+\.(com|net|org|in|co|io|me|pk|uk)\b',
            caseSensitive: false), '');

    // ← NEW: Remove common download site watermarks
    s = s.replaceAll(
        RegExp(
            r'\b(riskyjatt|djpunjab|pagalworld|pagalnew|mr\s*jatt|mrjatt|djjohal|downloadming|songspk|bestwap|waploft|funmaza|djmaza|freshmaza|mymp3song|pendujatt|jattshare|djyoungster|raagpunjabi|gaana|wynk|pagalworld|downloadhub|mp3mad|mp3skull|mp3juices|ringtonedownload|wapking|mobango|zedge)\b',
            caseSensitive: false),
        '');

    // Remove trailing numbers/codes like _0394, _001
    s = s.replaceAll(RegExp(r'[_\-]\d{3,}$'), '');

    // Remove content in brackets — [Official Video], [HD], [Lyrics]
    s = s.replaceAll(RegExp(r'\[.*?\]'), '');

    // Remove content in parentheses except feat/ft
    s = s.replaceAll(
        RegExp(r'\((?!.*feat|.*ft).*?\)', caseSensitive: false), '');

    // Remove common YouTube/download suffixes
    s = s.replaceAll(
        RegExp(
            r'\b(lyrics?|official|video|audio|hd|hq|4k|mv|explicit|clean|remix|version|visualizer|lyric\s*video|full\s*song|new\s*song)\b',
            caseSensitive: false),
        '');

    // Remove featuring artists
    s = s.replaceAll(RegExp(r'\bft\.?\s.*$', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\bfeat\.?\s.*$', caseSensitive: false), '');

    // Remove extra dashes and whitespace at end
    s = s.replaceAll(RegExp(r'\s*[-–—]\s*$'), '');

    // Remove multiple spaces and trim
    s = s.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (s == '<unknown>') return '';

    return s;
  }

  String _extractTitle(String rawTitle) {
    var s = _cleanString(rawTitle);

    // Handle "Title - Website.com" pattern — take the part before the dash
    // e.g. "dhol jageero da - Riskyjatt.com" → "dhol jageero da"
    if (s.contains(' - ') || s.contains(' – ')) {
      final parts = s.split(RegExp(r'\s[-–]\s'));

      // Check if last part looks like a website or junk
      final lastPart = parts.last.trim().toLowerCase();
      final isJunk = lastPart.contains('.com') ||
          lastPart.contains('.net') ||
          lastPart.contains('.in') ||
          lastPart.length < 3 ||
          RegExp(r'^\d+$').hasMatch(lastPart); // pure numbers

      if (isJunk && parts.length >= 2) {
        // Take everything except the last junk part
        s = parts.sublist(0, parts.length - 1).join(' - ').trim();
      } else if (parts.length >= 2) {
        // Normal "Artist - Title" pattern — take last part as title
        s = parts.last.trim();
      }
    }

    return _cleanString(s);
  }

  String _extractArtist(String rawTitle, String metaArtist) {
    final cleanMeta = _cleanString(metaArtist);

    // If metadata artist is valid use it
    if (cleanMeta.isNotEmpty && cleanMeta != '<unknown>') {
      return cleanMeta;
    }

    // Try to extract artist from title like "chris brown - Residuals"
    final cleanTitle = _cleanString(rawTitle);
    if (cleanTitle.contains(' - ') || cleanTitle.contains(' – ')) {
      final parts = cleanTitle.split(RegExp(r'\s[-–]\s'));
      if (parts.length >= 2) {
        return parts.first.trim();
      }
    }

    return '';
  }

  // Parse .lrc format: [mm:ss.xx] lyric line
  List<LyricLine> _parseLrc(String lrc) {
    final lines = <LyricLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in lrc.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final ms = int.parse(match.group(3)!.padRight(3, '0'));
        final text = match.group(4)!.trim();

        if (text.isNotEmpty) {
          lines.add(LyricLine(
            timestamp: Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: ms,
            ),
            text: text,
          ));
        }
      }
    }

    return lines;
  }

  // Get current line index based on playback position
  int getCurrentLineIndex(Duration position) {
    if (state.lines.isEmpty) return -1;
    // Find last line whose timestamp <= current position
    int index = -1;
    for (int i = 0; i < state.lines.length; i++) {
      if (state.lines[i].timestamp <= position) {
        index = i;
      } else {
        break;
      }
    }
    return index;
  }
}

final lyricsProvider = NotifierProvider<LyricsNotifier, LyricsState>(
  LyricsNotifier.new,
);