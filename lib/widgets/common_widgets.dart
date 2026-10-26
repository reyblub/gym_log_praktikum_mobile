import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../controllers/gym_log_controller.dart';
import '../models/exercise.dart';

class GymLogWordmark extends StatelessWidget {
  const GymLogWordmark({super.key});
  @override
  Widget build(BuildContext context) => const Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Gym',
              style: TextStyle(color: AppColors.ink),
            ),
            TextSpan(
              text: 'Log',
              style: TextStyle(color: AppColors.green),
            ),
          ],
        ),
        style: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      );
}

/// Batasi lebar isi agar tablet/web tidak menghasilkan kartu yang terlalu lebar.
class PageWidth extends StatelessWidget {
  const PageWidth({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: child,
        ),
      );
}

class ExercisePicture extends StatelessWidget {
  const ExercisePicture({
    super.key,
    required this.exercise,
    this.size = 84,
    this.large = false,
  });
  final Exercise exercise;
  final double size;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final url = large ? exercise.imageUrl : exercise.thumbnailUrl;
    final fallback = ColoredBox(
      color: AppColors.mint,
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          size: large ? 66 : 32,
          color: AppColors.green,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: large ? double.infinity : size,
        height: large ? 265 : size,
        child: exercise.isLocal
            ? _LocalExerciseArtwork(category: exercise.category, large: large)
            : url == null
            ? fallback
            : ColoredBox(
                color: const Color(0xFFF2F5F6),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  semanticLabel: exercise.name,
                  errorBuilder: (_, error, stack) => fallback,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: progress.expectedTotalBytes == null
                                  ? null
                                  : progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!,
                            ),
                          ),
                        ),
                ),
              ),
      ),
    );
  }
}

/// Ilustrasi kategori dibuat dengan widget Flutter, sehingga tetap tampil offline.
class _LocalExerciseArtwork extends StatelessWidget {
  const _LocalExerciseArtwork({required this.category, required this.large});

  final ExerciseCategory category;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final (background, accent) = switch (category.name) {
      'Chest' => (const Color(0xFFFFE9E8), const Color(0xFFC75B5B)),
      'Back' => (const Color(0xFFE4F0FF), const Color(0xFF467FB7)),
      'Legs' => (const Color(0xFFFFF1D9), const Color(0xFFAC7A23)),
      'Shoulders' => (const Color(0xFFF0E7FF), const Color(0xFF8560BF)),
      'Arms' => (const Color(0xFFE2F4EA), const Color(0xFF28845F)),
      'Abs' => (const Color(0xFFFFE8D9), const Color(0xFFBA6D3B)),
      'Calves' => (const Color(0xFFE0F3F4), const Color(0xFF2C858A)),
      _ => (const Color(0xFFFCE7F1), const Color(0xFFAA527E)),
    };
    return Semantics(
      label: 'Ilustrasi kategori ${category.label}',
      excludeSemantics: true,
      child: ColoredBox(
        color: background,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: large ? -65 : -25,
              right: large ? -35 : -25,
              child: Container(
                width: large ? 230 : 85,
                height: large ? 230 : 85,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(82),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(categoryIcon(category), size: large ? 100 : 38, color: accent),
                if (large) ...[
                  const SizedBox(height: 15),
                  Text(
                    category.label,
                    style: TextStyle(
                      color: accent,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.controller,
    required this.exercise,
  });
  final GymLogController controller;
  final Exercise exercise;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => IconButton(
          tooltip: controller.isFavorite(exercise.id)
              ? 'Hapus favorit'
              : 'Simpan favorit',
          onPressed: controller.favoritesLoading ||
                  controller.savingFavorite ||
                  controller.favoriteError != null
              ? null
              : () => changeFavorite(context, controller, exercise),
          icon: Icon(
            controller.isFavorite(exercise.id)
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: controller.isFavorite(exercise.id)
                ? AppColors.green
                : AppColors.muted,
          ),
        ),
      );
}

Future<void> changeFavorite(
  BuildContext context,
  GymLogController controller,
  Exercise exercise,
) async {
  final wasSaved = controller.isFavorite(exercise.id);
  final message = await controller.toggleFavorite(exercise);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message ??
            (wasSaved
                ? 'Latihan dihapus dari favorit.'
                : 'Latihan disimpan ke favorit.'),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.controller,
    required this.onTap,
  });
  final Exercise exercise;
  final GymLogController controller;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.line),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              child: Row(
                children: [
                  ExercisePicture(exercise: exercise),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          exercise.category.label,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          exercise.equipmentLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FavoriteButton(controller: controller, exercise: exercise),
                ],
              ),
            ),
          ),
        ),
      );
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: AppColors.green),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.6),
            ),
            if (onPressed != null) ...[
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onPressed,
                child: Text(buttonLabel ?? 'Coba lagi'),
              ),
            ],
          ],
        ),
      );
}

class ExerciseSkeleton extends StatelessWidget {
  const ExerciseSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var index = 0; index < 3; index++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            height: 14, width: 135, color: AppColors.line),
                        const SizedBox(height: 10),
                        Container(height: 10, width: 90, color: AppColors.line),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          const CircularProgressIndicator(strokeWidth: 2.5),
          const SizedBox(height: 12),
          const Text('Memuat latihan...',
              style: TextStyle(color: AppColors.muted)),
        ],
      );
}

IconData categoryIcon(ExerciseCategory category) => switch (category.name) {
      'Chest' => Icons.accessibility_new_rounded,
      'Back' => Icons.sports_gymnastics_rounded,
      'Legs' || 'Calves' => Icons.directions_walk_rounded,
      'Shoulders' => Icons.sports_handball_rounded,
      'Arms' => Icons.fitness_center_rounded,
      'Abs' => Icons.self_improvement_rounded,
      _ => Icons.directions_run_rounded,
    };
