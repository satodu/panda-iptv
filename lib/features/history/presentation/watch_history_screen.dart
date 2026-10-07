import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/storage/full_watch_history_service.dart';
import '../../../core/storage/watch_history_item.dart';
import '../../../core/storage/watched_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/brutalist_button.dart';
import '../../../core/widgets/brutalist_entrance.dart';
import '../../../core/widgets/focusable_category_chip.dart';
import '../../../core/widgets/hanko_badge.dart';
import '../../../core/widgets/tech_crosses.dart';
import '../../player/presentation/video_player_screen.dart';
import '../../series/models/series_item.dart';
import '../../series/presentation/series_detail_screen.dart';
import '../../series/presentation/series_provider.dart';
import '../../vod/models/vod_item.dart';
import '../../vod/presentation/vod_detail_screen.dart';
import '../../vod/presentation/vod_provider.dart';

class WatchHistoryScreen extends StatefulWidget {
  const WatchHistoryScreen({super.key});

  @override
  State<WatchHistoryScreen> createState() => _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends State<WatchHistoryScreen> {
  String _selectedTab = 'all'; // 'all', 'movie', 'series'

  @override
  void initState() {
    super.initState();
    FullWatchHistoryService.loadHistory();
    WatchedService.loadWatched();
  }

  void _onPlayItem(WatchHistoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          title: item.title,
          subtitle: item.subtitle,
          streamUrl: item.streamUrl,
          mediaId: item.id,
          cover: item.cover,
          initialPositionMs: item.positionMs,
          mediaType: item.type,
        ),
      ),
    ).then((_) {
      FullWatchHistoryService.loadHistory();
      WatchedService.loadWatched();
    });
  }

  void _onOpenSeriesDetails(WatchHistoryItem item) {
    final sId = item.seriesId ?? 0;
    final seriesProv = context.read<SeriesProvider>();
    final matched = seriesProv.seriesList.where((s) => s.seriesId == sId).firstOrNull;

    final targetSeries = matched ??
        SeriesItem(
          seriesId: sId,
          name: item.title,
          cover: item.cover,
          rating: 0.0,
          categoryId: '0',
        );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeriesDetailScreen(item: targetSeries),
      ),
    ).then((_) {
      FullWatchHistoryService.loadHistory();
      WatchedService.loadWatched();
    });
  }

  void _onOpenMovieDetails(WatchHistoryItem item) {
    final vId = item.vodStreamId ?? 0;
    final vodProv = context.read<VodProvider>();
    final matched = vodProv.filteredMovies.where((m) => m.streamId == vId).firstOrNull;

    final targetMovie = matched ??
        VodItem(
          streamId: vId,
          name: item.title,
          streamIcon: item.cover,
          rating: 0.0,
          categoryId: '0',
        );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VodDetailScreen(item: targetMovie),
      ),
    ).then((_) {
      FullWatchHistoryService.loadHistory();
      WatchedService.loadWatched();
    });
  }

  Future<void> _onDeleteItem(WatchHistoryItem item) async {
    await FullWatchHistoryService.removeItem(item.id);
    if (mounted) {
      AppToast.show(
        context,
        context.tr('history.item_deleted'),
        type: ToastType.info,
      );
    }
  }

  Future<void> _onConfirmClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderHairline),
          ),
          title: Text(
            context.tr('history.clear_confirm_title'),
            style: AppTypography.sectionTitle(fontSize: 16),
          ),
          content: Text(
            context.tr('history.clear_confirm_desc'),
            style: AppTypography.mono(fontSize: 13, color: AppColors.textMuted),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            BrutalistButton(
              label: context.tr('common.cancel'),
              isSecondary: true,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            const SizedBox(width: 8),
            BrutalistButton(
              label: context.tr('history.confirm_delete'),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await FullWatchHistoryService.clearHistory();
      if (mounted) {
        AppToast.show(
          context,
          context.tr('history.clear_all'),
          type: ToastType.success,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isNarrow),
            _buildFilterSelector(),
            Expanded(
              child: ValueListenableBuilder<List<WatchHistoryItem>>(
                valueListenable: FullWatchHistoryService.historyNotifier,
                builder: (context, allItems, _) {
                  return ValueListenableBuilder<Set<String>>(
                    valueListenable: WatchedService.watchedNotifier,
                    builder: (context, watchedSet, _) {
                      final filtered = allItems.where((item) {
                        if (_selectedTab == 'movie') return item.type == 'movie';
                        if (_selectedTab == 'series') return item.type == 'series';
                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: isNarrow ? 14 : 24,
                          vertical: 16,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isWatched = watchedSet.contains(item.id) ||
                              (item.durationMs > 0 && (item.positionMs / item.durationMs) >= 0.93);

                          return BrutalistEntrance(
                            index: index,
                            child: _buildHistoryCard(item, isWatched, isNarrow),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isNarrow) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Text(
            context.tr('history.title'),
            style: AppTypography.titleMedium(fontSize: isNarrow ? 14 : 16),
          ),
          if (!isNarrow) ...[
            const SizedBox(width: 12),
            HankoBadge(
              text: context.tr('history.badge'),
              borderColor: AppColors.accentCyan,
              textColor: AppColors.accentCyan,
            ),
            const SizedBox(width: 12),
            const TechCrosses(count: 3, opacity: 0.2),
          ],
          const Spacer(),
          ValueListenableBuilder<List<WatchHistoryItem>>(
            valueListenable: FullWatchHistoryService.historyNotifier,
            builder: (context, items, _) {
              if (items.isEmpty) return const SizedBox.shrink();
              return BrutalistButton(
                label: context.tr('history.clear_all'),
                isSecondary: true,
                icon: Icons.delete_sweep_rounded,
                onPressed: _onConfirmClearAll,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
      ),
      child: Row(
        children: [
          FocusableCategoryChip(
            label: context.tr('history.tab_all'),
            isSelected: _selectedTab == 'all',
            onTap: () => setState(() => _selectedTab = 'all'),
          ),
          const SizedBox(width: 8),
          FocusableCategoryChip(
            label: context.tr('history.tab_movies'),
            isSelected: _selectedTab == 'movie',
            onTap: () => setState(() => _selectedTab = 'movie'),
          ),
          const SizedBox(width: 8),
          FocusableCategoryChip(
            label: context.tr('history.tab_series'),
            isSelected: _selectedTab == 'series',
            onTap: () => setState(() => _selectedTab = 'series'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_toggle_off_rounded, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              context.tr('history.empty'),
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('history.empty_desc'),
              textAlign: TextAlign.center,
              style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            const TechCrosses(count: 3, opacity: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(WatchHistoryItem item, bool isWatched, bool isNarrow) {
    final isSeries = item.type == 'series';
    final hasCover = item.cover != null &&
        item.cover!.trim().isNotEmpty &&
        item.cover != 'null' &&
        item.cover != 'undefined';

    return BentoCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 10,
      onTap: () {
        if (isSeries) {
          _onOpenSeriesDetails(item);
        } else {
          _onPlayItem(item);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capa do Conteúdo
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: isNarrow ? 65 : 85,
              height: isNarrow ? 95 : 120,
              color: AppColors.surfaceHover,
              child: hasCover
                  ? CachedNetworkImage(
                      imageUrl: item.cover!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildFallbackCover(isSeries),
                    )
                  : _buildFallbackCover(isSeries),
            ),
          ),
          const SizedBox(width: 14),

          // Informações e Ações
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Linha de Badges & Status
                Row(
                  children: [
                    HankoBadge(
                      text: isSeries ? 'SÉRIE' : 'FILME',
                      borderColor: isSeries ? AppColors.accentCyan : AppColors.accentPrimary,
                      textColor: isSeries ? AppColors.accentCyan : AppColors.accentPrimary,
                    ),
                    const SizedBox(width: 6),
                    if (isWatched)
                      HankoBadge(
                        text: context.tr('history.watched_badge'),
                        borderColor: AppColors.statusLive,
                        textColor: AppColors.statusLive,
                      )
                    else if (item.progress > 0) ...[
                      HankoBadge(
                        text: '${(item.progress * 100).toInt()}%',
                        borderColor: AppColors.accentCyan,
                        textColor: AppColors.accentCyan,
                      ),
                      if (item.remainingMinutes > 0) ...[
                        const SizedBox(width: 6),
                        HankoBadge(
                          text: '${item.remainingMinutes}M RESTANTES',
                          borderColor: AppColors.borderHairline,
                          textColor: AppColors.textMuted,
                        ),
                      ],
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Título
                Text(
                  item.title.toUpperCase().endsWith('.') ? item.title.toUpperCase() : '${item.title.toUpperCase()}.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sectionTitle(fontSize: isNarrow ? 12 : 14).copyWith(height: 1.2),
                ),

                // Subtítulo (Episódio / Temporada / Ano)
                if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],

                // Barra de Progresso (se em andamento)
                if (!isWatched && item.durationMs > 0 && item.progress > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 3,
                      backgroundColor: AppColors.surfaceHover,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Linha de Ações (Voltar para série / Reproduzir / Excluir)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (isSeries)
                      BrutalistButton(
                        label: context.tr('history.view_series_button'),
                        icon: Icons.tv_rounded,
                        isSecondary: false,
                        onPressed: () => _onOpenSeriesDetails(item),
                      ),
                    BrutalistButton(
                      label: isWatched
                          ? context.tr('history.watch_button')
                          : context.tr('history.resume_button'),
                      icon: Icons.play_arrow_rounded,
                      isSecondary: isSeries, // Se é série, o botão de abrir série é primário
                      onPressed: () => _onPlayItem(item),
                    ),
                    if (!isSeries)
                      BrutalistButton(
                        label: 'DETALHES.',
                        icon: Icons.info_outline_rounded,
                        isSecondary: true,
                        onPressed: () => _onOpenMovieDetails(item),
                      ),
                    IconButton(
                      tooltip: context.tr('history.delete_button'),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textMuted),
                      onPressed: () => _onDeleteItem(item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCover(bool isSeries) {
    return Container(
      color: AppColors.surfaceHover,
      child: Center(
        child: Icon(
          isSeries ? Icons.tv_rounded : Icons.movie_outlined,
          color: AppColors.textDisabled,
          size: 28,
        ),
      ),
    );
  }
}
