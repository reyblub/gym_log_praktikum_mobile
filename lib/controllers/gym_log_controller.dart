import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/exercise.dart';
import '../services/exercise_api.dart';
import '../services/favorite_storage.dart';

/// ChangeNotifier bawaan Flutter cukup untuk kebutuhan UTS ini.
/// UI tidak melakukan HTTP atau membaca SharedPreferences secara langsung.
class GymLogController extends ChangeNotifier {
  GymLogController({required this.api, required this.storage});
  final ExerciseApi api;
  final FavoriteStorage storage;

  List<Exercise> homeExercises = [];
  List<Exercise> exercises = [];
  List<ExerciseCategory> categories = [];
  Map<int, Exercise> _favorites = {};
  String query = '';
  int? categoryId;
  int total = 0;
  int? _nextOffset;
  bool homeLoading = true;
  bool loading = true;
  bool loadingMore = false;
  bool favoritesLoading = true;
  bool savingFavorite = false;
  String? homeError;
  String? error;
  String? paginationError;
  String? categoryError;
  String? favoriteError;
  Timer? _debounce;
  int _requestVersion = 0;
  bool _disposed = false;
  bool _initialized = false;

  List<Exercise> get favorites => _favorites.values.toList().reversed.toList();
  bool get hasMore => _nextOffset != null;
  bool isFavorite(int id) => _favorites.containsKey(id);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await Future.wait([
      loadHome(),
      reload(),
      loadCategories(),
      loadFavorites(),
    ]);
  }

  Future<void> loadHome() async {
    homeLoading = true;
    homeError = null;
    _notify();
    try {
      final page = await api.fetchExercises(limit: 12);
      if (_disposed) return;
      homeExercises = page.items;
    } catch (exception) {
      if (_disposed) return;
      homeError = _message(exception);
    } finally {
      homeLoading = false;
      _notify();
    }
  }

  Future<void> loadCategories() async {
    try {
      final result = await api.fetchCategories();
      if (_disposed) return;
      categories = result;
      categoryError = null;
    } catch (_) {
      if (_disposed) return;
      categoryError = 'Kategori belum dapat dimuat.';
    }
    _notify();
  }

  void updateQuery(String value) {
    if (query == value) return;
    query = value;
    // Batalkan hak respons lama sejak pengguna mengetik, termasuk load more.
    _requestVersion++;
    _debounce?.cancel();
    exercises = [];
    loading = true;
    loadingMore = false;
    error = null;
    paginationError = null;
    _nextOffset = null;
    _notify();
    _debounce = Timer(const Duration(milliseconds: 400), reload);
  }

  void selectCategory(int? value, {bool clearQuery = false}) {
    categoryId = value;
    if (clearQuery) query = '';
    unawaited(reload());
  }

  Future<void> reload() async {
    _debounce?.cancel();
    final version = ++_requestVersion;
    loading = true;
    loadingMore = false;
    error = null;
    paginationError = null;
    exercises = [];
    _nextOffset = null;
    _notify();
    try {
      final page = await api.fetchExercises(
        query: query,
        categoryId: categoryId,
      );
      if (_disposed || version != _requestVersion) return;
      exercises = page.items;
      total = page.total;
      _nextOffset = page.nextOffset;
    } catch (exception) {
      if (_disposed || version != _requestVersion) return;
      error = _message(exception);
    } finally {
      if (version == _requestVersion) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || _nextOffset == null) return;
    final version = _requestVersion;
    loadingMore = true;
    paginationError = null;
    _notify();
    try {
      final page = await api.fetchExercises(
        query: query,
        categoryId: categoryId,
        offset: _nextOffset!,
      );
      if (_disposed || version != _requestVersion) return;
      final known = exercises.map((exercise) => exercise.id).toSet();
      exercises = [
        ...exercises,
        ...page.items.where((exercise) => known.add(exercise.id)),
      ];
      _nextOffset = page.nextOffset;
      total = page.total;
    } catch (exception) {
      if (_disposed || version != _requestVersion) return;
      paginationError = _message(exception);
    } finally {
      if (version == _requestVersion) {
        loadingMore = false;
        _notify();
      }
    }
  }

  Future<void> loadFavorites() async {
    favoritesLoading = true;
    _notify();
    try {
      final result = await storage.read();
      if (_disposed) return;
      _favorites = {for (final exercise in result) exercise.id: exercise};
      favoriteError = null;
    } catch (_) {
      if (_disposed) return;
      favoriteError = 'Favorit belum dapat dibaca dari perangkat. Coba lagi.';
    } finally {
      favoritesLoading = false;
      _notify();
    }
  }

  /// null berarti berhasil. Perubahan UI dilakukan setelah data tersimpan.
  Future<String?> toggleFavorite(Exercise exercise) async {
    if (favoritesLoading || savingFavorite || favoriteError != null) {
      return 'Penyimpanan belum siap. Buka Favorit dan coba lagi.';
    }
    final updated = Map<int, Exercise>.from(_favorites);
    if (updated.containsKey(exercise.id)) {
      updated.remove(exercise.id);
    } else {
      updated[exercise.id] = exercise;
    }
    savingFavorite = true;
    _notify();
    try {
      await storage.write(updated.values.toList());
      if (!_disposed) _favorites = updated;
      return null;
    } catch (_) {
      return 'Favorit gagal disimpan. Coba lagi.';
    } finally {
      savingFavorite = false;
      _notify();
    }
  }

  String _message(Object exception) => exception is ApiException
      ? exception.message
      : 'Data belum dapat dimuat. Periksa koneksi lalu coba lagi.';

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    api.close();
    super.dispose();
  }
}
