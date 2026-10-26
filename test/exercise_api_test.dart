import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/models/exercise.dart';
import 'package:gym_log/services/exercise_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_support.dart';

void main() {
  test('Memilih terjemahan Inggris dan membersihkan HTML dengan entity', () {
    final json = fixture();
    (json['translations'] as List)[1]['description'] =
        '<p>Press &amp; control.</p><ul><li>Keep stable.</li></ul>'
        '<script>doNotDisplay()</script>';
    final exercise = Exercise.fromApiJson(json);
    expect(exercise.name, 'Bench Press');
    expect(exercise.description, contains('Press & control.'));
    expect(exercise.description, contains('• Keep stable.'));
    expect(exercise.description, isNot(contains('doNotDisplay')));
    expect(exercise.category.label, 'Dada');
    expect(exercise.imageUrl, isNull);
    expect(exercise.author, 'English author');
  });

  test('Mengambil gambar utama, thumbnail, dan lisensi yang berbeda', () {
    final json = fixture();
    json['images'] = [
      {'image': 'https://wger.de/first.png', 'is_main': false},
      {
        'image': 'https://wger.de/main.png',
        'is_main': true,
        'thumbnails': {'medium': 'https://wger.de/medium.png'},
        'license': 2,
        'license_author': 'Image author',
      },
    ];
    final exercise = Exercise.fromApiJson(json);
    expect(exercise.imageUrl, 'https://wger.de/main.png');
    expect(exercise.thumbnailUrl, 'https://wger.de/medium.png');
    expect(exercise.imageLicense, 'CC-BY-SA 4.0');
    final restored = Exercise.fromStoredJson(exercise.toStoredJson());
    expect(restored.toStoredJson(), exercise.toStoredJson());
  });

  test(
    'Mengirim pencarian, kategori, bahasa, dan pagination ke server',
    () async {
      final api = WgerApiService(
        client: MockClient((request) async {
          expect(request.url.scheme, 'https');
          expect(request.url.path, '/api/v2/exerciseinfo/');
          expect(request.url.queryParameters['name__search'], 'bench');
          expect(request.url.queryParameters['category'], '11');
          expect(request.url.queryParameters['language__code'], 'en');
          expect(request.url.queryParameters['offset'], '24');
          return http.Response(
            jsonEncode({
              'count': 50,
              'next': 'http://wger.de/api/v2/exerciseinfo/?offset=48&limit=24',
              'results': [fixture()],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final page = await api.fetchExercises(
        query: ' bench ',
        categoryId: 11,
        offset: 24,
      );
      expect(page.items.single.id, 57);
      expect(page.total, 50);
      expect(page.nextOffset, 48);
      api.close();
    },
  );

  test(
    'HTTP error, JSON rusak, dan timeout menjadi pesan yang dapat ditampilkan',
    () async {
      for (final response in [
        http.Response('unavailable', 503),
        http.Response('<html>invalid</html>', 200),
        http.Response('{"results":"wrong","count":0}', 200),
      ]) {
        final api = WgerApiService(client: MockClient((_) async => response));
        await expectLater(api.fetchExercises(), throwsA(isA<ApiException>()));
        api.close();
      }
      final api = WgerApiService(
        client: MockClient((_) async => throw TimeoutException('timeout')),
      );
      await expectLater(api.fetchExercises(), throwsA(isA<ApiException>()));
      api.close();
    },
  );
}
