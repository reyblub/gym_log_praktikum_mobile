import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/controllers/gym_log_controller.dart';
import 'package:gym_log/models/exercise.dart';
import 'package:gym_log/services/exercise_api.dart';
import 'package:gym_log/services/favorite_storage.dart';
import 'package:gym_log/services/local_exercise_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_support.dart';

class _JsonBundle extends CachingAssetBundle {
  _JsonBundle(this.contents);
  String contents;
  int reads = 0;

  @override
  Future<ByteData> load(String key) async {
    expect(key, LocalExerciseService.assetPath);
    reads++;
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(contents)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String catalogJson;
  late LocalExerciseService service;
  late _JsonBundle bundle;

  setUp(() async {
    catalogJson = await File(LocalExerciseService.assetPath).readAsString();
    bundle = _JsonBundle(catalogJson);
    service = LocalExerciseService(bundle: bundle);
  });

  test('JSON asli: 32 latihan, 8 kategori, tanpa HTTP client', () async {
    await HttpOverrides.runZoned(() async {
      final results = await Future.wait<Object>([
        service.fetchExercises(), service.fetchCategories(), service.fetchDetail(1001),
      ]);
      final page = results[0] as ExercisePage;
      final categories = results[1] as List<ExerciseCategory>;
      final detail = results[2] as Exercise;
      expect(page.total, 32);
      expect(categories.length, 8);
      expect(detail.name, 'Push-up');
      expect(detail.isLocal, isTrue);
      expect(detail.sourceUrl, isEmpty);
      expect(detail.imageUrl, isNull);
      expect(bundle.reads, 1);
    }, createHttpClient: (_) => throw StateError('HTTP tidak boleh dipakai.'));
  });

  test('Pagination menghasilkan seluruh data tepat sekali', () async {
    final first = await service.fetchExercises();
    expect(first.items.length, 24);
    expect(first.nextOffset, 24);
    final second = await service.fetchExercises(offset: first.nextOffset!);
    expect(second.items.length, 8);
    expect(second.nextOffset, isNull);
    expect({...first.items.map((e) => e.id), ...second.items.map((e) => e.id)},
        hasLength(32));
    expect((await service.fetchExercises(offset: 100)).items, isEmpty);
  });

  test('Pencarian kapital/spasi dan kombinasi kategori bekerja', () async {
    final push = await service.fetchExercises(query: '  PUSH  ');
    expect(push.items.map((e) => e.name),
        containsAll(['Push-up', 'Diamond Push-up', 'Triceps Pushdown']));
    final chest = await service.fetchExercises(categoryId: 11, query: 'push');
    expect(chest.items.map((e) => e.name), ['Push-up', 'Diamond Push-up']);
    expect((await service.fetchExercises(query: 'bench dada')).items.single.name,
        'Bench Press');
    expect((await service.fetchExercises(query: 'dada')).total, 4);
    expect((await service.fetchExercises(query: 'latihantidakada')).items, isEmpty);
    expect((await service.fetchExercises(categoryId: 999)).items, isEmpty);
  });

  test('ID tidak ditemukan dan batas halaman tidak valid ditangani', () async {
    await expectLater(service.fetchDetail(-1), throwsA(isA<ApiException>()));
    await expectLater(service.fetchExercises(limit: 0), throwsArgumentError);
    await expectLater(service.fetchExercises(offset: -1), throwsArgumentError);
  });

  test('JSON rusak, kategori hilang, dan ID berulang ditolak', () async {
    final dangling = jsonDecode(catalogJson) as Map<String, dynamic>;
    (dangling['exercises'] as List).first['category_id'] = 999;
    final duplicate = jsonDecode(catalogJson) as Map<String, dynamic>;
    final rows = duplicate['exercises'] as List;
    rows[1]['id'] = rows[0]['id'];
    for (final contents in ['{invalid', jsonEncode(dangling), jsonEncode(duplicate)]) {
      final bad = LocalExerciseService(bundle: _JsonBundle(contents));
      await expectLater(bad.fetchExercises(), throwsA(isA<ApiException>()));
    }
  });

  test('Pembacaan dapat dicoba lagi setelah JSON diperbaiki', () async {
    final changingBundle = _JsonBundle('{invalid');
    final changing = LocalExerciseService(bundle: changingBundle);
    await expectLater(changing.fetchExercises(), throwsA(isA<ApiException>()));
    changingBundle.contents = catalogJson;
    expect((await changing.fetchExercises()).total, 32);
  });

  test('Controller memuat halaman lanjutan dan menerapkan filter lokal', () async {
    final state = GymLogController(api: service, storage: MemoryStorage());
    addTearDown(state.dispose);
    await state.initialize();
    expect(state.homeExercises.length, 12);
    expect(state.homeError, isNull);
    expect(state.exercises.length, 24);
    await state.loadMore();
    expect(state.exercises.length, 32);
    expect(state.hasMore, isFalse);
    state.categoryId = 11;
    state.query = 'push';
    await state.reload();
    expect(state.total, 2);
    expect(state.exercises.every((e) => e.category.id == 11), isTrue);
  });

  test('Favorit lokal tersimpan lengkap dan terpisah dari mode API', () async {
    SharedPreferences.setMockInitialValues({});
    final local = LocalFavoriteStorage(key: 'test.local');
    final online = LocalFavoriteStorage(key: 'test.api');
    final exercise = await service.fetchDetail(1001);
    await local.write([exercise]);
    await online.write([exampleExercise()]);
    final restored = (await LocalFavoriteStorage(key: 'test.local').read()).single;
    expect(restored.toStoredJson(), exercise.toStoredJson());
    expect(restored.isLocal, isTrue);
    expect(restored.sourceUrl, isEmpty);
    expect((await online.read()).single.isLocal, isFalse);
    await local.write([]);
    expect(await local.read(), isEmpty);
    expect((await online.read()).single.name, 'Bench Press');
  });
}
