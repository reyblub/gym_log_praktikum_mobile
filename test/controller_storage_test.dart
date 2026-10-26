import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/controllers/gym_log_controller.dart';
import 'package:gym_log/models/exercise.dart';
import 'package:gym_log/services/favorite_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_support.dart';

class DelayedSearchApi extends FakeApi {
  final requests = <String, Completer<ExercisePage>>{};
  @override
  Future<ExercisePage> fetchExercises({
    String query = '',
    int? categoryId,
    int offset = 0,
    int limit = 24,
  }) {
    final completer = Completer<ExercisePage>();
    requests[query] = completer;
    return completer.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Favorit tetap ada pada instance penyimpanan baru dan bisa dihapus',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = LocalFavoriteStorage();
      await first.write([exampleExercise()]);
      final second = LocalFavoriteStorage();
      expect((await second.read()).single.name, 'Bench Press');
      await second.write([]);
      expect(await LocalFavoriteStorage().read(), isEmpty);
    },
  );

  test('Gagal menyimpan tidak mengubah daftar favorit pada UI', () async {
    final storage = MemoryStorage()..failWrite = true;
    final state = GymLogController(api: FakeApi(), storage: storage);
    await state.loadFavorites();
    expect(await state.toggleFavorite(exampleExercise()), isNotNull);
    expect(state.favorites, isEmpty);
    storage.failWrite = false;
    expect(await state.toggleFavorite(exampleExercise()), isNull);
    expect(state.favorites.single.id, 57);
    state.dispose();
  });

  test(
    'Respons pencarian lama tidak menimpa hasil pencarian terbaru',
    () async {
      final api = DelayedSearchApi();
      final state = GymLogController(api: api, storage: MemoryStorage());
      state.query = 'old';
      final oldRequest = state.reload();
      state.query = 'new';
      final newRequest = state.reload();
      api.requests['new']!.complete(
        ExercisePage(
          items: [exampleExercise(id: 2, name: 'New result')],
          total: 1,
        ),
      );
      await newRequest;
      api.requests['old']!.complete(
        ExercisePage(
          items: [exampleExercise(id: 1, name: 'Old result')],
          total: 1,
        ),
      );
      await oldRequest;
      expect(state.exercises.single.name, 'New result');
      expect(state.loading, isFalse);
      state.dispose();
    },
  );
}
