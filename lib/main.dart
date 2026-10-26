import 'dart:async';

import 'package:flutter/material.dart';

import 'app_config.dart';
import 'app_theme.dart';
import 'controllers/gym_log_controller.dart';
import 'models/exercise.dart';
import 'screens/catalog_screen.dart';
import 'screens/exercise_detail_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'services/exercise_api.dart';
import 'services/favorite_storage.dart';
import 'services/local_exercise_service.dart';
import 'widgets/common_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GymLogApp());
}

class GymLogApp extends StatefulWidget {
  const GymLogApp({super.key, this.controller});
  // Injeksi controller dipakai dalam pengujian tanpa mengakses internet.
  final GymLogController? controller;
  @override
  State<GymLogApp> createState() => _GymLogAppState();
}

class _GymLogAppState extends State<GymLogApp> {
  late final GymLogController _controller;
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        GymLogController(
          api: AppConfig.useLocalData
              ? LocalExerciseService()
              : WgerApiService(),
          storage: LocalFavoriteStorage(key: AppConfig.favoriteStorageKey),
        );
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'GymLog',
        debugShowCheckedModeBanner: false,
        theme: gymLogTheme(),
        home: GymLogShell(controller: _controller),
      );
}

class GymLogShell extends StatefulWidget {
  const GymLogShell({super.key, required this.controller});
  final GymLogController controller;
  @override
  State<GymLogShell> createState() => _GymLogShellState();
}

class _GymLogShellState extends State<GymLogShell> {
  int _index = 0;
  void _browse(int? categoryId) {
    widget.controller.selectCategory(categoryId, clearQuery: true);
    setState(() => _index = 1);
  }

  void _openExercise(Exercise exercise) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExerciseDetailScreen(
          exercise: exercise,
          controller: widget.controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const GymLogWordmark(),
            actions: [
              IconButton(
                tooltip: 'Tentang GymLog',
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () => showAboutDialog(
                  context: context,
                  applicationName: 'GymLog',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.green,
                    size: 40,
                  ),
                  children: [
                    Text(
                      AppConfig.useLocalData
                          ? 'Jelajahi contoh latihan dan simpan favoritmu. '
                              'Versi praktikum menggunakan katalog contoh '
                              'yang tersedia tanpa internet. '
                              'Ilustrasi menunjukkan kategori latihan. '
                              'Favorit tersimpan di perangkat ini.'
                          : 'Jelajahi latihan dan simpan favoritmu. '
                              'Data dan ilustrasi latihan berasal dari wger. '
                              'Nama dan panduan mengikuti bahasa sumber. '
                              'Favorit tersimpan di perangkat ini.',
                      style: const TextStyle(height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: IndexedStack(
            index: _index,
            children: [
              HomeScreen(
                controller: widget.controller,
                onBrowse: _browse,
                onExercise: _openExercise,
              ),
              CatalogScreen(
                controller: widget.controller,
                onExercise: _openExercise,
              ),
              FavoritesScreen(
                controller: widget.controller,
                onExercise: _openExercise,
                onBrowse: () => _browse(null),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) {
              FocusScope.of(context).unfocus();
              setState(() => _index = value);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: AppColors.green),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.green,
                ),
                label: 'Latihan',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_border_rounded),
                selectedIcon:
                    Icon(Icons.bookmark_rounded, color: AppColors.green),
                label: 'Favorit',
              ),
            ],
          ),
        ),
      );
}
