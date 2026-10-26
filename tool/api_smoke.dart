import 'dart:io';

import 'package:gym_log/services/exercise_api.dart';

/// Pemeriksaan API sungguhan; dijalankan manual, bukan bagian unit test offline.
Future<void> main() async {
  final api = WgerApiService();
  try {
    final categories = await api.fetchCategories();
    final page = await api.fetchExercises(
      query: 'bench',
      categoryId: 11,
      limit: 3,
    );
    if (categories.isEmpty || page.items.isEmpty) {
      throw StateError('API tidak mengembalikan data yang diharapkan.');
    }
    if (page.items.any((item) => item.category.id != 11)) {
      throw StateError('Filter kategori tidak diterapkan server.');
    }
    final detail = await api.fetchDetail(page.items.first.id);
    if (detail.id != page.items.first.id || detail.name.isEmpty) {
      throw StateError('Detail tidak sesuai item yang dipilih.');
    }
    stdout.writeln('Kategori: ${categories.length}');
    stdout.writeln('Hasil pencarian bench + Chest: ${page.total}');
    stdout.writeln('Detail terpilih: ${detail.id} — ${detail.name}');
    stdout.writeln('API smoke check: PASS');
  } finally {
    api.close();
  }
}
