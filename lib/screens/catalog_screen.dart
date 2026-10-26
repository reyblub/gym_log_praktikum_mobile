import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../controllers/gym_log_controller.dart';
import '../models/exercise.dart';
import '../widgets/common_widgets.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    required this.controller,
    required this.onExercise,
  });
  final GymLogController controller;
  final ValueChanged<Exercise> onExercise;
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final TextEditingController _search;
  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.controller.query);
    widget.controller.addListener(_synchronizeQuery);
  }

  void _synchronizeQuery() {
    if (_search.text != widget.controller.query) {
      _search.value = TextEditingValue(
        text: widget.controller.query,
        selection: TextSelection.collapsed(
          offset: widget.controller.query.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_synchronizeQuery);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller;
    return PageWidth(
      child: RefreshIndicator(
        onRefresh: state.reload,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Latihan',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _search,
                      onChanged: state.updateQuery,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => state.reload(),
                      decoration: InputDecoration(
                        hintText: 'Cari latihan... (mis. bench)',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: state.query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                onPressed: () => state.updateQuery(''),
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('Semua'),
                              selected: state.categoryId == null,
                              showCheckmark: false,
                              selectedColor: AppColors.mint,
                              onSelected: (_) => state.selectCategory(null),
                            ),
                          ),
                          for (final category in state.categories)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(category.label),
                                selected: state.categoryId == category.id,
                                showCheckmark: false,
                                selectedColor: AppColors.mint,
                                onSelected: (_) =>
                                    state.selectCategory(category.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (state.categoryError != null)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              state.categoryError!,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: state.loadCategories,
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (!state.loading && state.error == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          '${state.total} latihan ditemukan',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (state.loading)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(child: ExerciseSkeleton()),
              )
            else if (state.error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: StatusPanel(
                    icon: Icons.cloud_off_rounded,
                    title: 'Gagal memuat latihan',
                    message: state.error!,
                    onPressed: state.reload,
                  ),
                ),
              )
            else if (state.exercises.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: StatusPanel(
                    icon: Icons.search_off_rounded,
                    title: 'Latihan tidak ditemukan',
                    message:
                        'Coba kata kunci lain atau pilih kategori lainnya.',
                    buttonLabel: 'Reset pencarian',
                    onPressed: () =>
                        state.selectCategory(null, clearQuery: true),
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final exercise = state.exercises[index];
                    return ExerciseCard(
                      exercise: exercise,
                      controller: state,
                      onTap: () => widget.onExercise(exercise),
                    );
                  }, childCount: state.exercises.length),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
                  child: Column(
                    children: [
                      if (state.paginationError != null) ...[
                        Text(
                          state.paginationError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (state.loadingMore)
                        const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      else if (state.hasMore)
                        OutlinedButton.icon(
                          onPressed: state.loadMore,
                          icon: const Icon(Icons.expand_more_rounded),
                          label: Text(
                            state.paginationError == null
                                ? 'Muat lebih banyak'
                                : 'Coba lagi',
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Semua hasil sudah ditampilkan.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
