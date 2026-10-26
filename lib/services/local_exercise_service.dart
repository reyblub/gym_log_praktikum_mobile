import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/exercise.dart';
import 'exercise_api.dart';

/// Sumber data UTS praktikum. Seluruh katalog dibundel di dalam aplikasi.
/// Interface sama dengan API agar halaman dan controller bisa dipakai kembali.
class LocalExerciseService implements ExerciseApi {
  LocalExerciseService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/data/exercises.json';
  final AssetBundle _bundle;
  Future<_LocalCatalog>? _catalog;

  Future<_LocalCatalog> _load() async {
    final cached = _catalog;
    if (cached != null) return cached;
    final pending = _readCatalog();
    _catalog = pending;
    try {
      return await pending;
    } catch (_) {
      // Kegagalan membaca berkas tidak mengunci tombol coba lagi.
      if (identical(_catalog, pending)) _catalog = null;
      _bundle.evict(assetPath);
      rethrow;
    }
  }

  Future<_LocalCatalog> _readCatalog() async {
    try {
      final decoded = jsonDecode(await _bundle.loadString(assetPath));
      if (decoded is! Map ||
          decoded['categories'] is! List ||
          decoded['exercises'] is! List) {
        throw const FormatException('Struktur katalog tidak valid.');
      }

      final categoriesById = <int, ExerciseCategory>{};
      for (final item in decoded['categories'] as List) {
        final json = _record(item);
        final id = _positiveId(json['id']);
        final name = _requiredText(json, 'name');
        if (categoriesById.containsKey(id)) {
          throw const FormatException('ID kategori berulang.');
        }
        categoriesById[id] = ExerciseCategory(id: id, name: name);
      }
      if (categoriesById.isEmpty) {
        throw const FormatException('Kategori kosong.');
      }

      final exercises = <Exercise>[];
      final knownIds = <int>{};
      for (final item in decoded['exercises'] as List) {
        final json = _record(item);
        final id = _positiveId(json['id']);
        final category = categoriesById[_positiveId(json['category_id'])];
        if (category == null || !knownIds.add(id)) {
          throw const FormatException('Relasi kategori atau ID tidak valid.');
        }
        _requiredText(json, 'name');
        _requiredText(json, 'description');
        _stringList(json['equipment']);
        _stringList(json['muscles']);
        exercises.add(Exercise.fromLocalJson(json, category: category));
      }
      final categories = categoriesById.values.toList()
        ..sort((a, b) => a.label.compareTo(b.label));
      return _LocalCatalog(exercises: exercises, categories: categories);
    } on FormatException {
      throw const ApiException(
        'Format data lokal tidak valid. Periksa assets/data/exercises.json.',
      );
    } catch (_) {
      throw const ApiException(
        'Data lokal belum dapat dibaca. Tutup lalu buka kembali aplikasi.',
      );
    }
  }

  @override
  Future<ExercisePage> fetchExercises({
    String query = '',
    int? categoryId,
    int offset = 0,
    int limit = 24,
  }) async {
    if (offset < 0 || limit < 1) {
      throw ArgumentError('Offset minimal 0 dan limit minimal 1.');
    }
    final catalog = await _load();
    final words = query.trim().toLowerCase().split(RegExp(r'\s+'));
    final filtered = catalog.exercises.where((exercise) {
      if (categoryId != null && exercise.category.id != categoryId) {
        return false;
      }
      final text = [
        exercise.name,
        exercise.category.name,
        exercise.category.label,
        ...exercise.equipment,
        ...exercise.muscles,
      ].join(' ').toLowerCase();
      return words.every(text.contains);
    }).toList();
    final items = filtered.skip(offset).take(limit).toList();
    final nextOffset = offset + items.length;
    return ExercisePage(
      items: items,
      total: filtered.length,
      nextOffset: nextOffset < filtered.length ? nextOffset : null,
    );
  }

  @override
  Future<List<ExerciseCategory>> fetchCategories() async =>
      List.unmodifiable((await _load()).categories);

  @override
  Future<Exercise> fetchDetail(int id) async {
    for (final exercise in (await _load()).exercises) {
      if (exercise.id == id) return exercise;
    }
    throw const ApiException('Latihan tidak ditemukan pada katalog lokal.');
  }

  @override
  void close() {}
}

class _LocalCatalog {
  const _LocalCatalog({required this.exercises, required this.categories});

  final List<Exercise> exercises;
  final List<ExerciseCategory> categories;
}

Map<String, dynamic> _record(dynamic value) {
  if (value is! Map) throw const FormatException('Objek JSON tidak valid.');
  return Map<String, dynamic>.from(value);
}

int _positiveId(dynamic value) {
  if (value is! int || value < 1) {
    throw const FormatException('ID harus berupa bilangan bulat positif.');
  }
  return value;
}

String _requiredText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key wajib berupa teks.');
  }
  return value.trim();
}

void _stringList(dynamic value) {
  if (value is! List ||
      value.isEmpty ||
      value.any((item) => item is! String || item.trim().isEmpty)) {
    throw const FormatException('Daftar alat atau otot tidak valid.');
  }
}
