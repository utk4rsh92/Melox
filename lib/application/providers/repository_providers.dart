// lib/application/providers/repository_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/eq_repository_impl.dart';
import '../../domain/repositories/library_repository.dart';
import '../../domain/repositories/library_repository_impl.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/repositories/eq_repository.dart';
import '../../domain/repositories/playlist_repository_impl.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepositoryImpl();
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepositoryImpl();
});

final eqRepositoryProvider = Provider<EQRepository>((ref) {
  return EQRepositoryImpl();
});