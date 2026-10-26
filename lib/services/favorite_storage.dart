import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';

abstract class FavoriteStorage {
  Future<List<Exercise>> read();
  Future<void> write(List<Exercise> exercises);
}

class LocalFavoriteStorage implements FavoriteStorage {
  LocalFavoriteStorage({this.key = storageKey});

  static const storageKey = 'gym_log.favorites.v1';
  final String key;

  @override
  Future<List<Exercise>> read() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.any((item) => item is! Map)) {
      throw const FormatException('Data favorit tidak valid.');
    }
    return decoded
        .map(
          (item) =>
              Exercise.fromStoredJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<void> write(List<Exercise> exercises) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      key,
      jsonEncode(exercises.map((exercise) => exercise.toStoredJson()).toList()),
    );
    if (!saved) throw StateError('Penyimpanan favorit gagal.');
  }
}
