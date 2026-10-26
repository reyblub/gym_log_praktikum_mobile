import 'package:gym_log/models/exercise.dart';
import 'package:gym_log/services/exercise_api.dart';
import 'package:gym_log/services/favorite_storage.dart';

// Fixture khusus pengujian API. Mode praktikum membaca JSON pada assets/data/.
Map<String, dynamic> fixture({int id = 57, String name = 'Bench Press'}) => {
      'id': id,
      'category': {'id': 11, 'name': 'Chest'},
      'equipment': [
        {'id': 1, 'name': 'Barbell'},
      ],
      'muscles': [
        {'id': 4, 'name': 'Pectoralis major', 'name_en': 'Chest'},
      ],
      'license': {
        'id': 1,
        'short_name': 'CC-BY-SA 3.0',
        'url': 'https://creativecommons.org/licenses/by-sa/3.0/',
      },
      'license_author': 'Test author',
      'images': [],
      'translations': [
        {'language': 1, 'name': 'Bankdrücken', 'description': '<p>Deutsch</p>'},
        {
          'language': 2,
          'name': name,
          'description': '<p>Press &amp; control.</p>',
          'license': 1,
          'license_author': 'English author',
        },
      ],
    };

Exercise exampleExercise({int id = 57, String name = 'Bench Press'}) =>
    Exercise.fromApiJson(fixture(id: id, name: name));

class MemoryStorage implements FavoriteStorage {
  List<Exercise> saved = [];
  bool failWrite = false;
  @override
  Future<List<Exercise>> read() async => List.from(saved);
  @override
  Future<void> write(List<Exercise> exercises) async {
    if (failWrite) throw StateError('Storage is full');
    saved = List.from(exercises);
  }
}

class FakeApi implements ExerciseApi {
  bool fail = false;
  @override
  Future<ExercisePage> fetchExercises({
    String query = '',
    int? categoryId,
    int offset = 0,
    int limit = 24,
  }) async {
    if (fail) throw const ApiException('Koneksi terputus untuk pengujian.');
    final items = query == 'tidakada' ? <Exercise>[] : [exampleExercise()];
    return ExercisePage(items: items, total: items.length);
  }

  @override
  Future<List<ExerciseCategory>> fetchCategories() async => [
        const ExerciseCategory(id: 11, name: 'Chest'),
        const ExerciseCategory(id: 12, name: 'Back'),
        const ExerciseCategory(id: 9, name: 'Legs'),
        const ExerciseCategory(id: 13, name: 'Shoulders'),
      ];
  @override
  Future<Exercise> fetchDetail(int id) async {
    if (fail) throw const ApiException('Tidak terhubung.');
    return exampleExercise(id: id);
  }

  @override
  void close() {}
}
