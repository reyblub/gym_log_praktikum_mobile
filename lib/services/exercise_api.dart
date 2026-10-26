import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/exercise.dart';

abstract class ExerciseApi {
  Future<ExercisePage> fetchExercises({
    String query = '',
    int? categoryId,
    int offset = 0,
    int limit = 24,
  });
  Future<List<ExerciseCategory>> fetchCategories();
  Future<Exercise> fetchDetail(int id);
  void close();
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class WgerApiService implements ExerciseApi {
  WgerApiService({
    http.Client? client,
    this.timeout = const Duration(seconds: 25),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;
  static const host = 'wger.de';

  @override
  Future<ExercisePage> fetchExercises({
    String query = '',
    int? categoryId,
    int offset = 0,
    int limit = 24,
  }) async {
    final parameters = <String, String>{
      'limit': '$limit', 'offset': '$offset', 'language__code': 'en',
      'ordering': 'id',
      // name__search adalah nama parameter pada schema wger saat ini.
      // Parameter search/name biasa diabaikan oleh server ini.
      if (query.trim().isNotEmpty) 'name__search': query.trim(),
      if (categoryId != null) 'category': '$categoryId',
    };
    final json = await _get('exerciseinfo/', parameters);
    if (json['results'] is! List || json['count'] is! num) {
      throw const ApiException(
        'Format daftar latihan dari server tidak dikenali.',
      );
    }
    final rawItems = json['results'] as List;
    if (rawItems.any((item) => item is! Map)) {
      throw const ApiException('Ada data latihan yang tidak dapat dibaca.');
    }
    final items = rawItems
        .map(
          (item) =>
              Exercise.fromApiJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    final next =
        json['next'] is String ? Uri.tryParse(json['next'] as String) : null;
    return ExercisePage(
      items: items,
      total: (json['count'] as num).toInt(),
      nextOffset: next == null
          ? null
          : int.tryParse(next.queryParameters['offset'] ?? ''),
    );
  }

  @override
  Future<List<ExerciseCategory>> fetchCategories() async {
    final json = await _get('exercisecategory/', {'limit': '100'});
    if (json['results'] is! List) {
      throw const ApiException('Kategori latihan tidak dapat dibaca.');
    }
    final categories = (json['results'] as List)
        .whereType<Map>()
        .map(
          (item) => ExerciseCategory.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    categories.sort((a, b) => a.label.compareTo(b.label));
    return categories;
  }

  @override
  Future<Exercise> fetchDetail(int id) async =>
      Exercise.fromApiJson(await _get('exerciseinfo/$id/'));

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? query,
  ]) async {
    final uri = Uri.https(host, '/api/v2/$path', query);
    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'}).timeout(timeout);
      if (response.statusCode == 429) {
        throw const ApiException(
          'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.',
        );
      }
      if (response.statusCode == 404) {
        throw const ApiException('Data latihan ini tidak ditemukan di server.');
      }
      if (response.statusCode != 200) {
        throw ApiException(
          'Server belum dapat memuat data (HTTP ${response.statusCode}).',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw const ApiException('Format respons server tidak dikenali.');
      }
      return Map<String, dynamic>.from(decoded);
    } on TimeoutException {
      throw const ApiException(
        'Koneksi terlalu lama. Periksa internet lalu coba lagi.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung. Periksa koneksi internetmu.',
      );
    } on FormatException {
      throw const ApiException(
        'Respons server tidak dapat dibaca. Coba lagi nanti.',
      );
    }
  }

  @override
  void close() => _client.close();
}
