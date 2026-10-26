import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/app_config.dart';
import 'package:gym_log/main.dart';
import 'package:gym_log/screens/catalog_screen.dart';
import 'package:gym_log/screens/exercise_detail_screen.dart';
import 'package:gym_log/screens/favorites_screen.dart';
import 'package:gym_log/services/local_exercise_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in [const Size(360, 780), const Size(800, 600)]) {
    testWidgets(
      'JSON asli ${size.width}x${size.height}: navigasi dan favorit setelah buka ulang',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        await tester.runAsync(
          () => rootBundle.loadString(LocalExerciseService.assetPath),
        );
        await HttpOverrides.runZoned(() async {
          await tester.pumpWidget(const GymLogApp());
          await tester.pumpAndSettle();
          expect(find.text('Halo, Rey'), findsOneWidget);
          expect(find.text('Gagal memuat latihan'), findsNothing);
          await tester.tap(find.text('Jelajahi latihan').first);
          await tester.pumpAndSettle();
          expect(find.text('32 latihan ditemukan'), findsOneWidget);
          await tester.enterText(find.byType(TextField), 'push');
          await tester.pump(const Duration(milliseconds: 450));
          await tester.pumpAndSettle();
          await tester.tap(find.descendant(
            of: find.byType(CatalogScreen),
            matching: find.text('Push-up'),
          ).first);
          await tester.pumpAndSettle();
          expect(find.byType(ExerciseDetailScreen), findsOneWidget);
          expect(find.text('Bahasa panduan: Indonesia'), findsOneWidget);
          expect(find.text('Salin tautan sumber'), findsNothing);
          await tester.tap(find.text('Simpan favorit'));
          await tester.pumpAndSettle();
          await tester.pageBack();
          await tester.pumpAndSettle();
          await tester.tap(find.text('Favorit').last);
          await tester.pumpAndSettle();
          expect(find.descendant(
            of: find.byType(FavoritesScreen),
            matching: find.text('Push-up'),
          ), findsOneWidget);
          // App baru membaca kembali JSON favorit pada SharedPreferences mock.
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          await tester.pumpWidget(const GymLogApp());
          await tester.pumpAndSettle();
          await tester.tap(find.text('Favorit').last);
          await tester.pumpAndSettle();
          expect(find.text('1 latihan tersimpan'), findsOneWidget);
          await tester.tap(find.byTooltip('Hapus favorit').last);
          await tester.pumpAndSettle();
          expect(find.text('Simpan latihan pilihanmu'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }, createHttpClient: (_) => throw StateError('Mode lokal memakai HTTP.'));
      },
      skip: !AppConfig.useLocalData,
    );
  }
}
