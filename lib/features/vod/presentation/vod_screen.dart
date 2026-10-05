import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/tech_crosses.dart';
import '../../auth/presentation/auth_provider.dart';
import '../models/vod_item.dart';
import 'vod_detail_screen.dart';
import 'vod_provider.dart';

class VodScreen extends StatefulWidget {
  const VodScreen({super.key});

  @override
  State<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends State<VodScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final account = context.read<AuthProvider>().currentAccount;
      if (account != null) {
        context.read<VodProvider>().init(account);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vod = context.watch<VodProvider>();
    final account = context.watch<AuthProvider>().currentAccount;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context, vod),

            // Categories Bar
            _buildCategorySelector(context, vod, account),

            // Movies Grid
            Expanded(
              child: vod.isLoadingMovies
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary))
                  : vod.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.statusError, size: 36),
                              const SizedBox(height: 12),
                              Text('ERRO AO CARREGAR.', style: AppTypography.titleMedium(color: AppColors.statusError)),
                              const SizedBox(height: 6),
                              Text(vod.error!, style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
                                onPressed: () {
                                  if (account != null) vod.init(account);
                                },
                                child: Text('TENTAR NOVAMENTE.', style: AppTypography.button()),
                              ),
                            ],
                          ),
                        )
                      : vod.filteredMovies.isEmpty
                          ? Center(
                              child: Text(
                                'NENHUM FILME ENCONTRADO.',
                                style: AppTypography.mono(fontSize: 13, color: AppColors.textMuted),
                              ),
                            )
                          : _buildMoviesGrid(context, vod.filteredMovies),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, VodProvider vod) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Text('FILMES.', style: AppTypography.titleMedium()),
          const SizedBox(width: 16),
          const TechCrosses(count: 3, opacity: 0.2),
          const Spacer(),
          // Campo de busca
          SizedBox(
            width: 220,
            height: 38,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => vod.setSearchQuery(val),
              style: AppTypography.body(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'BUSCAR FILME...',
                hintStyle: AppTypography.mono(fontSize: 11, color: AppColors.textDisabled),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          vod.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                filled: true,
                fillColor: AppColors.surfaceHover,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderHairline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderHairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.accentPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context, VodProvider vod, dynamic account) {
    if (vod.isLoadingCategories) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPrimary),
          ),
        ),
      );
    }

    if (vod.categories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: vod.categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isSelected = isAll ? (vod.selectedCategoryId == null || vod.selectedCategoryId == 'all') : vod.selectedCategoryId == vod.categories[index - 1].categoryId;

          final label = isAll ? 'TODOS' : vod.categories[index - 1].categoryName.toUpperCase();

          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (account != null) {
                vod.selectCategory(account, isAll ? 'all' : vod.categories[index - 1].categoryId);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentPrimary : AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.accentPrimary : AppColors.borderHairline,
                ),
              ),
              child: Text(
                label,
                style: AppTypography.mono(
                  fontSize: 11,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoviesGrid(BuildContext context, List<VodItem> movies) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 6;
        } else if (constraints.maxWidth > 900) {
          crossAxisCount = 5;
        } else if (constraints.maxWidth > 650) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 450) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.65,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
            return _buildMovieCard(context, movie);
          },
        );
      },
    );
  }

  Widget _buildMovieCard(BuildContext context, VodItem movie) {
    return BentoCard(
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VodDetailScreen(item: movie),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: movie.streamIcon != null && movie.streamIcon!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: movie.streamIcon!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceCard,
                            child: const Center(
                              child: Icon(Icons.movie_outlined, size: 36, color: AppColors.textMuted),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceCard,
                          child: const Center(
                            child: Icon(Icons.movie_outlined, size: 36, color: AppColors.textMuted),
                          ),
                        ),
                ),
                if (movie.rating > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '★ ${movie.rating.toStringAsFixed(1)}',
                        style: AppTypography.mono(fontSize: 10, color: AppColors.accentPrimary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.name.toUpperCase().endsWith('.') ? movie.name.toUpperCase() : '${movie.name.toUpperCase()}.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sectionTitle(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '[ VOD // HD ]',
                  style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
