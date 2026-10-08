import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/storage/favorite_item.dart';
import '../../../core/storage/favorites_service.dart';
import '../../../core/storage/recent_channels_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/brutalist_entrance.dart';
import '../../../core/widgets/hanko_badge.dart';
import '../../../core/widgets/focusable_category_chip.dart';
import '../../../core/widgets/tech_crosses.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../player/presentation/video_player_screen.dart';
import '../../series/models/series_item.dart';
import '../../series/presentation/series_detail_screen.dart';
import '../../vod/models/vod_item.dart';
import '../../vod/presentation/vod_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _selectedFilter = 'ALL'; // 'ALL', 'live', 'movie', 'series'

  @override
  void initState() {
    super.initState();
    FavoritesService.loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context),

            // Filter Tabs
            _buildFilterTabs(),

            // Content
            Expanded(
              child: ValueListenableBuilder<List<FavoriteItem>>(
                valueListenable: FavoritesService.favoritesNotifier,
                builder: (context, allFavorites, _) {
                  final filtered = _selectedFilter == 'ALL'
                      ? allFavorites
                      : allFavorites.where((f) => f.type == _selectedFilter).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildGrid(context, filtered);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Text('MEUS FAVORITOS.', style: AppTypography.titleMedium()),
          const SizedBox(width: 10),
          ValueListenableBuilder<List<FavoriteItem>>(
            valueListenable: FavoritesService.favoritesNotifier,
            builder: (context, list, _) {
              return HankoBadge(
                text: '[ ${list.length} ]',
                borderColor: AppColors.statusLive,
                textColor: AppColors.statusLive,
              );
            },
          ),
          const Spacer(),
          const TechCrosses(count: 3, opacity: 0.2),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'ALL', 'label': 'TODOS.'},
      {'key': 'live', 'label': 'AO VIVO.'},
      {'key': 'movie', 'label': 'FILMES.'},
      {'key': 'series', 'label': 'SÉRIES.'},
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedFilter == f['key'];
          return FocusableCategoryChip(
            label: f['label']!,
            isSelected: isSelected,
            onTap: () => setState(() => _selectedFilter = f['key']!),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: const Icon(
                Icons.star_border_rounded,
                size: 54,
                color: AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'NENHUM FAVORITO SALVO.',
              style: AppTypography.sectionTitle(),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione filmes e séries aos favoritos tocando no ícone de estrela nas telas de detalhes.',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            const TechCrosses(count: 5, spacing: 8, opacity: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<FavoriteItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 6;
        } else if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 600) {
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
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return BrutalistEntrance(
              index: index,
              child: _buildItemCard(context, item),
            );
          },
        );
      },
    );
  }

  Widget _buildItemCard(BuildContext context, FavoriteItem item) {
    final isLive = item.type == 'live';
    final isSeries = item.type == 'series';
    final hasCover = item.cover != null && item.cover!.trim().isNotEmpty;

    return BentoCard(
      padding: EdgeInsets.zero,
      onTap: () => _openDetail(context, item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: hasCover
                      ? CachedNetworkImage(
                          imageUrl: item.cover!,
                          fit: isLive ? BoxFit.contain : BoxFit.cover,
                          errorWidget: (_, __, ___) => _buildFallbackCover(item),
                        )
                      : _buildFallbackCover(item),
                ),

                // Gradiente superior para botões
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Badge de tipo (AO VIVO / FILME / SÉRIE)
                Positioned(
                  top: 8,
                  left: 8,
                  child: HankoBadge(
                    text: isLive ? 'AO VIVO' : (isSeries ? 'SÉRIE' : 'FILME'),
                    borderColor: isLive
                        ? AppColors.statusLive
                        : (isSeries ? AppColors.accentCyan : AppColors.accentPrimary),
                    textColor: isLive
                        ? AppColors.statusLive
                        : (isSeries ? AppColors.accentCyan : AppColors.accentPrimary),
                  ),
                ),

                // Botão Remover dos Favoritos
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    canRequestFocus: false,
                    onTap: () {
                      FavoritesService.removeFavorite(item.id);
                      AppToast.info(context, '${item.title} REMOVIDO DOS FAVORITOS.');
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderHairline),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),

                // Rating (apenas filmes e séries)
                if (item.rating != null && item.rating! > 0)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: HankoBadge(
                      text: '★ ${item.rating!.toStringAsFixed(1)}',
                      borderColor: AppColors.accentPrimary,
                      textColor: AppColors.accentPrimary,
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
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  item.genre ?? (isLive ? 'CANAL AO VIVO' : (isSeries ? 'SÉRIE' : 'FILME')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCover(FavoriteItem item) {
    final isLive = item.type == 'live';
    final isSeries = item.type == 'series';

    return Container(
      color: AppColors.surfaceCard,
      child: Center(
        child: Icon(
          isLive
              ? Icons.live_tv_rounded
              : (isSeries ? Icons.video_collection_outlined : Icons.movie_outlined),
          size: 40,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, FavoriteItem item) {
    if (item.type == 'live') {
      final account = context.read<AuthProvider>().currentAccount;
      final rawId = int.tryParse(item.id.replaceFirst('live_', '')) ?? 0;
      final streamUrl = item.streamUrl ??
          (account != null ? '${account.serverUrl}/live/${account.username}/${account.password}/$rawId.ts' : '');

      if (streamUrl.isNotEmpty) {
        RecentChannelsService.recordChannelWatched(
          streamId: rawId,
          name: item.title,
          streamIcon: item.cover,
          categoryName: item.genre,
          channelNumber: item.channelNumber,
          streamUrl: streamUrl,
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              title: item.title,
              subtitle: item.genre ?? 'CANAL AO VIVO',
              streamUrl: streamUrl,
              mediaId: rawId.toString(),
              cover: item.cover,
              mediaType: 'live',
            ),
          ),
        );
      }
      return;
    }

    if (item.type == 'series') {
      final rawId = int.tryParse(item.id.replaceFirst('series_', '')) ?? 0;
      final series = SeriesItem(
        seriesId: rawId,
        name: item.title,
        cover: item.cover,
        rating: item.rating ?? 0.0,
        genre: item.genre,
        categoryId: '0',
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SeriesDetailScreen(item: series)),
      );
    } else {
      final rawId = int.tryParse(item.id.replaceFirst('vod_', '')) ?? 0;
      final movie = VodItem(
        streamId: rawId,
        name: item.title,
        streamIcon: item.cover,
        rating: item.rating ?? 0.0,
        categoryId: '0',
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VodDetailScreen(item: movie)),
      );
    }
  }
}
