import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../controllers/gym_log_controller.dart';
import '../models/exercise.dart';
import '../widgets/common_widgets.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    required this.controller,
    required this.onExercise,
    required this.onBrowse,
  });
  final GymLogController controller;
  final ValueChanged<Exercise> onExercise;
  final VoidCallback onBrowse;
  @override
  Widget build(BuildContext context) => PageWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const Text(
              'Favorit',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${controller.favorites.length} latihan tersimpan',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 22),
            if (controller.favoritesLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (controller.favoriteError != null)
              StatusPanel(
                icon: Icons.folder_off_outlined,
                title: 'Favorit belum terbaca',
                message: controller.favoriteError!,
                onPressed: controller.loadFavorites,
              )
            else if (controller.favorites.isEmpty)
              StatusPanel(
                icon: Icons.bookmark_add_outlined,
                title: 'Simpan latihan pilihanmu',
                message:
                    'Ketuk ikon bookmark pada latihan untuk menemukannya kembali di sini.',
                buttonLabel: 'Jelajahi latihan',
                onPressed: onBrowse,
              )
            else ...[
              ...controller.favorites.map(
                (exercise) => ExerciseCard(
                  exercise: exercise,
                  controller: controller,
                  onTap: () => onExercise(exercise),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.bookmark_rounded,
                        color: AppColors.green, size: 32),
                    SizedBox(height: 12),
                    Text(
                      'Latihan pilihanmu, mudah ditemukan kembali.',
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tersimpan di perangkat ini.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}
