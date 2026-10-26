import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../controllers/gym_log_controller.dart';
import '../models/exercise.dart';
import '../widgets/common_widgets.dart';

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.controller,
  });
  final Exercise exercise;
  final GymLogController controller;
  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late Future<Exercise> _detail;
  @override
  void initState() {
    super.initState();
    _detail = widget.controller.api.fetchDetail(widget.exercise.id);
  }

  void _retry() => setState(() {
        _detail = widget.controller.api.fetchDetail(widget.exercise.id);
      });

  @override
  Widget build(BuildContext context) => FutureBuilder<Exercise>(
        future: _detail,
        initialData: widget.exercise,
        builder: (context, snapshot) {
          final exercise = snapshot.data ?? widget.exercise;
          return AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              final saved = widget.controller.isFavorite(exercise.id);
              return Scaffold(
                appBar: AppBar(
                  title: const Text(
                    'Detail latihan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                body: PageWidth(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    children: [
                      if (snapshot.connectionState != ConnectionState.done)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      if (snapshot.hasError &&
                          snapshot.connectionState == ConnectionState.done)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4DB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pembaruan detail belum berhasil.',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                exercise.isLocal
                                    ? 'Data yang sudah dimuat tetap dapat dibaca. '
                                        'Coba muat ulang detail latihan.'
                                    : 'Data yang sudah dimuat tetap dapat dibaca. '
                                        'Gambar memerlukan koneksi internet.',
                                style: const TextStyle(height: 1.5),
                              ),
                              TextButton(
                                onPressed: _retry,
                                child: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        ),
                      ExercisePicture(exercise: exercise, large: true),
                      const SizedBox(height: 22),
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 26,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.7,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Tag(
                            label: exercise.category.label,
                            icon: Icons.accessibility_new_rounded,
                          ),
                          ...exercise.equipment.map(
                            (equipment) => _Tag(
                              label: equipment,
                              icon: Icons.fitness_center_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _DetailCard(
                        title: 'Otot utama',
                        icon: Icons.accessibility_new_rounded,
                        child: Text(
                          exercise.muscles.isEmpty
                              ? 'Otot utama belum dicantumkan pada sumber.'
                              : exercise.muscles.join(' • '),
                          style: const TextStyle(
                            height: 1.6,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _DetailCard(
                        title: 'Cara melakukan',
                        icon: Icons.format_list_bulleted_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              exercise.description.isEmpty
                                  ? 'Panduan gerakan belum tersedia untuk latihan ini.'
                                  : exercise.description,
                              style: const TextStyle(fontSize: 14, height: 1.7),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Bahasa panduan: ${exercise.languageLabel}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          title: const Text(
                            'Sumber & atribusi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          leading:
                              const Icon(Icons.info_outline_rounded, size: 20),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(18, 0, 18, 18),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (exercise.isLocal)
                              const Text(
                                'Katalog contoh GymLog untuk UTS praktikum. '
                                'Nama, kategori, alat, otot, dan panduan dibaca '
                                'dari JSON lokal. Ilustrasi menampilkan kategori '
                                'latihan dengan ikon bawaan Flutter.',
                                style: TextStyle(fontSize: 12, height: 1.6),
                              ),
                            if (!exercise.isLocal) ...[
                              Text(
                                'Data: wger • ${exercise.author}',
                                style: const TextStyle(fontSize: 12, height: 1.6),
                              ),
                              Text(
                                'Lisensi teks: ${exercise.licenseName}',
                                style: const TextStyle(fontSize: 12, height: 1.6),
                              ),
                              if (exercise.licenseUrl.isNotEmpty)
                                SelectableText(
                                  exercise.licenseUrl,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                    height: 1.6,
                                  ),
                                ),
                              if (exercise.imageUrl != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Gambar: ${exercise.imageAuthor} • ${exercise.imageLicense}',
                                  style:
                                      const TextStyle(fontSize: 12, height: 1.6),
                                ),
                                if (exercise.imageLicenseUrl.isNotEmpty)
                                  SelectableText(
                                    exercise.imageLicenseUrl,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                      height: 1.6,
                                    ),
                                  ),
                              ],
                              const SizedBox(height: 10),
                              const Text(
                                'Deskripsi ditampilkan dari sumber; format HTML diubah menjadi teks.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SelectableText(
                                exercise.sourceUrl,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.green,
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Salin tautan sumber'),
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: exercise.sourceUrl),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Tautan sumber disalin.'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: SafeArea(
                  child: PageWidth(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: FilledButton.icon(
                        onPressed: widget.controller.favoritesLoading ||
                                widget.controller.savingFavorite ||
                                widget.controller.favoriteError != null
                            ? null
                            : () => changeFavorite(
                                  context,
                                  widget.controller,
                                  exercise,
                                ),
                        icon: Icon(
                          saved
                              ? Icons.bookmark_remove_rounded
                              : Icons.bookmark_add_outlined,
                        ),
                        label: Text(
                          saved ? 'Hapus dari favorit' : 'Simpan favorit',
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.green),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}
