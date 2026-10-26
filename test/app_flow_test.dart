import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/controllers/gym_log_controller.dart';
import 'package:gym_log/main.dart';
import 'package:gym_log/screens/catalog_screen.dart';
import 'package:gym_log/screens/exercise_detail_screen.dart';
import 'package:gym_log/screens/favorites_screen.dart';

import 'test_support.dart';

void main() {
  testWidgets(
    'Layar kecil: beranda → katalog → detail → favorit, simpan dan hapus',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = GymLogController(api: FakeApi(), storage: MemoryStorage());
      await tester.pumpWidget(GymLogApp(controller: state));
      await tester.pumpAndSettle();
      expect(find.text('Halo, Rey'), findsOneWidget);
      await tester.tap(find.text('Jelajahi latihan').first);
      await tester.pumpAndSettle();
      expect(find.byType(CatalogScreen), findsOneWidget);
      await tester.tap(
        find
            .descendant(
              of: find.byType(CatalogScreen),
              matching: find.text('Bench Press'),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseDetailScreen), findsOneWidget);
      expect(find.text('Simpan favorit'), findsOneWidget);
      await tester.tap(find.text('Simpan favorit'));
      await tester.pumpAndSettle();
      expect(state.favorites.single.name, 'Bench Press');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favorit').last);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(FavoritesScreen),
          matching: find.text('Bench Press'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Hapus favorit').last);
      await tester.pumpAndSettle();
      expect(find.text('Simpan latihan pilihanmu'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );

  testWidgets(
    'Error menyediakan retry dan pencarian tanpa hasil menyediakan reset',
    (tester) async {
      final api = FakeApi()..fail = true;
      final state = GymLogController(api: api, storage: MemoryStorage());
      await tester.pumpWidget(GymLogApp(controller: state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Latihan').last);
      await tester.pumpAndSettle();
      expect(find.text('Gagal memuat latihan'), findsOneWidget);
      api.fail = false;
      await tester.tap(find.text('Coba lagi').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'tidakada');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.text('Latihan tidak ditemukan'), findsOneWidget);
      await tester.ensureVisible(find.text('Reset pencarian'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset pencarian'));
      await tester.pumpAndSettle();
      expect(find.text('1 latihan ditemukan'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );
}
