import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../controllers/gym_log_controller.dart';
import '../models/exercise.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onBrowse,
    required this.onExercise,
  });
  final GymLogController controller;
  final void Function(int? categoryId) onBrowse;
  final ValueChanged<Exercise> onExercise;

  @override
  Widget build(BuildContext context) {
    final preferred = ['Chest', 'Back', 'Legs', 'Shoulders'];
    final categories = preferred
        .expand(
          (name) => controller.categories.where((item) => item.name == name),
        )
        .toList();
    final pictured = controller.homeExercises
        .where((item) => item.imageUrl != null)
        .toList();
    final featured =
        (pictured.isNotEmpty ? pictured : controller.homeExercises).take(4);
    return PageWidth(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            controller.loadHome(),
            controller.loadCategories(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const Text(
              'Halo, Rey',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Temukan latihanmu',
                              style: TextStyle(
                                fontSize: 22,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Jelajahi gerakan berdasarkan otot dan alat.',
                              style: TextStyle(
                                height: 1.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(17),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD5EDDF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fitness_center_rounded,
                          color: AppColors.green,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => onBrowse(null),
                      label: const Text('Jelajahi latihan'),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                      iconAlignment: IconAlignment.end,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'Kelompok otot',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (controller.categoryError != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.categoryError!,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.loadCategories,
                    child: const Text('Coba lagi'),
                  ),
                ],
              )
            else if (categories.isEmpty)
              const LinearProgressIndicator(minHeight: 2)
            else
              Row(
                children: [
                  for (var i = 0; i < categories.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i == categories.length - 1 ? 0 : 10,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => onBrowse(categories[i].id),
                          child: Column(
                            children: [
                              Container(
                                height: 65,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: [
                                    const Color(0xFFFFE9E8),
                                    const Color(0xFFE4F0FF),
                                    const Color(0xFFFFF1D9),
                                    const Color(0xFFF0E7FF),
                                  ][i % 4],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  categoryIcon(categories[i]),
                                  size: 29,
                                  color: [
                                    const Color(0xFFE46B6B),
                                    const Color(0xFF5896D8),
                                    const Color(0xFFCF9635),
                                    const Color(0xFF9871D5),
                                  ][i % 4],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                categories[i].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pilihan latihan',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: () => onBrowse(null),
                  child: const Text('Lihat semua'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (controller.homeLoading && controller.homeExercises.isEmpty)
              const ExerciseSkeleton()
            else if (controller.homeError != null &&
                controller.homeExercises.isEmpty)
              StatusPanel(
                icon: Icons.cloud_off_rounded,
                title: 'Gagal memuat latihan',
                message: controller.homeError!,
                onPressed: controller.loadHome,
              )
            else if (controller.homeExercises.isEmpty)
              StatusPanel(
                icon: Icons.search_off_rounded,
                title: 'Belum ada latihan',
                message: 'Data latihan belum tersedia. Coba muat ulang.',
                onPressed: controller.loadHome,
              )
            else ...[
              if (controller.homeError != null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Pembaruan belum berhasil. Daftar sebelumnya tetap ditampilkan.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ...featured.map(
                (exercise) => ExerciseCard(
                  exercise: exercise,
                  controller: controller,
                  onTap: () => onExercise(exercise),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
