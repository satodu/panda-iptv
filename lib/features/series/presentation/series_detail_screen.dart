import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/tmdb_service.dart';
import '../../../core/storage/favorite_item.dart';
import '../../../core/storage/favorites_service.dart';
import '../../../core/storage/watch_history_item.dart';
import '../../../core/storage/watch_history_service.dart';
import '../../../core/storage/full_watch_history_service.dart';
import '../../../core/storage/watched_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/brutalist_entrance.dart';
import '../../../core/widgets/hanko_badge.dart';
import '../../../core/widgets/hanko_loader.dart';
import '../../../core/widgets/tech_crosses.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../player/models/playlist_item.dart';
import '../../player/presentation/video_player_screen.dart';
import '../models/series_detail.dart';
import '../models/series_item.dart';
import 'series_provider.dart';

class SeriesDetailScreen extends StatefulWidget {
  final SeriesItem item;

  const SeriesDetailScreen({super.key, required this.item});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  SeriesDetail? _detail;
  bool _loading = true;
  String? _selectedSeason;
  bool _isFavorite = false;

  int _activeTab = 0; // 0 = EPISÓDIOS, 1 = SEMELHANTES
  List<TmdbMovie> _similarSeries = [];
  bool _loadingTmdb = false;

  @override
  void initState() {
    super.initState();
    WatchHistoryService.loadHistory();
    FullWatchHistoryService.loadHistory();
    WatchedService.loadWatched();
    _loadDetail();
    _checkFavorite();
  }

  void _checkFavorite() async {
    final isFav = await FavoritesService.isFavorite('series_${widget.item.seriesId}');
    if (mounted) setState(() => _isFavorite = isFav);
  }

  void _toggleFavorite() async {
    final item = FavoriteItem(
      id: 'series_${widget.item.seriesId}',
      title: widget.item.name,
      type: 'series',
      cover: _detail?.cover ?? widget.item.cover,
      rating: _detail?.rating ?? widget.item.rating,
      genre: _detail?.genre ?? widget.item.genre,
      addedAt: DateTime.now(),
    );
    final isFav = await FavoritesService.toggleFavorite(item);
    if (mounted) {
      setState(() => _isFavorite = isFav);
      if (isFav) {
        AppToast.favorite(context, 'ADICIONADO AOS FAVORITOS.');
      } else {
        AppToast.info(context, 'REMOVIDO DOS FAVORITOS.');
      }
    }
  }

  WatchHistoryItem? _getSavedSeriesHistory() {
    final active = WatchHistoryService.historyNotifier.value
        .where((h) => h.type == 'series' && h.seriesId == widget.item.seriesId)
        .firstOrNull;
    if (active != null) return active;
    return FullWatchHistoryService.historyNotifier.value
        .where((h) => h.type == 'series' && h.seriesId == widget.item.seriesId)
        .firstOrNull;
  }

  void _resumeSavedHistory(WatchHistoryItem savedItem) {
    if (_detail != null && savedItem.episodeId != null) {
      final targetEpId = savedItem.episodeId.toString();
      for (final entry in _detail!.episodesBySeason.entries) {
        final ep = entry.value.where((e) => e.id == targetEpId).firstOrNull;
        if (ep != null) {
          setState(() => _selectedSeason = entry.key);
          _playEpisode(ep);
          return;
        }
      }
    }

    final account = context.read<AuthProvider>().currentAccount;
    if (account == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          title: widget.item.name,
          subtitle: savedItem.subtitle,
          streamUrl: savedItem.streamUrl,
          mediaId: savedItem.id,
          cover: savedItem.cover ?? widget.item.cover,
          initialPositionMs: savedItem.positionMs > 5000 ? savedItem.positionMs : null,
          mediaType: 'series',
        ),
      ),
    ).then((_) {
      WatchHistoryService.loadHistory();
      FullWatchHistoryService.loadHistory();
      WatchedService.loadWatched();
    });
  }

  Future<void> _loadDetail() async {
    final account = context.read<AuthProvider>().currentAccount;
    if (account == null) return;

    final detail = await context.read<SeriesProvider>().loadSeriesDetail(account, widget.item.seriesId);
    if (mounted) {
      setState(() {
        _detail = detail;
        _loading = false;
        if (detail != null && detail.seasonNumbers.isNotEmpty) {
          String? initialSeason;
          final savedItem = _getSavedSeriesHistory();
          if (savedItem != null && savedItem.episodeId != null) {
            final targetEpId = savedItem.episodeId.toString();
            for (final entry in detail.episodesBySeason.entries) {
              if (entry.value.any((ep) => ep.id == targetEpId)) {
                initialSeason = entry.key;
                break;
              }
            }
          }
          _selectedSeason = initialSeason ?? detail.seasonNumbers.first;
        }
      });
      _loadTmdbData(detail);
    }
  }

  Future<void> _loadTmdbData(SeriesDetail? detail) async {
    setState(() => _loadingTmdb = true);
    final tvId = await TmdbService.searchTvId(widget.item.name, year: detail?.releaseDate);
    if (tvId != null && tvId > 0 && mounted) {
      final similar = await TmdbService.getSimilarTv(tvId);
      if (mounted) {
        setState(() {
          _similarSeries = similar;
          _loadingTmdb = false;
        });
      }
    } else if (mounted) {
      setState(() => _loadingTmdb = false);
    }
  }

  void _playEpisode(EpisodeItem episode) {
    final account = context.read<AuthProvider>().currentAccount;
    if (account == null) return;

    final seriesProvider = context.read<SeriesProvider>();
    final episodes = _detail?.episodesBySeason[_selectedSeason] ?? [];

    bool isValidImg(String? s) {
      if (s == null) return false;
      final t = s.trim().toLowerCase();
      return t.isNotEmpty && t != 'null' && t != 'undefined' && (t.startsWith('http://') || t.startsWith('https://'));
    }

    final playlist = episodes.map((ep) {
      final url = seriesProvider.buildStreamUrl(account, ep.id, ep.containerExtension);
      final epCandidates = [
        widget.item.cover,
        _detail?.cover,
        _detail?.backdrop,
        ep.image,
      ];
      final epCover = epCandidates.firstWhere(
        isValidImg,
        orElse: () => null,
      );

      return PlaylistItem(
        id: 'series_${widget.item.seriesId}_${ep.id}',
        title: widget.item.name,
        subtitle: 'TEMP $_selectedSeason // EP ${ep.episodeNum} - ${ep.title}',
        streamUrl: url,
        cover: epCover,
        mediaType: 'series',
      );
    }).toList();

    final currentIndex = episodes.indexWhere((e) => e.id == episode.id);

    final selectedCandidates = [
      widget.item.cover,
      _detail?.cover,
      _detail?.backdrop,
      episode.image,
    ];
    final selectedCover = selectedCandidates.firstWhere(
      isValidImg,
      orElse: () => null,
    );

    final mediaId = 'series_${widget.item.seriesId}_${episode.id}';
    final saved = WatchHistoryService.getItem(mediaId) ?? FullWatchHistoryService.getItem(mediaId);
    final initialPos = (saved != null && saved.positionMs > 5000) ? saved.positionMs : null;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          title: widget.item.name,
          subtitle: 'TEMP $_selectedSeason // EP ${episode.episodeNum} - ${episode.title}',
          streamUrl: seriesProvider.buildStreamUrl(account, episode.id, episode.containerExtension),
          mediaId: mediaId,
          cover: selectedCover,
          initialPositionMs: initialPos,
          mediaType: 'series',
          playlist: playlist.isNotEmpty ? playlist : null,
          initialPlaylistIndex: currentIndex >= 0 ? currentIndex : 0,
        ),
      ),
    ).then((_) {
      WatchHistoryService.loadHistory();
      FullWatchHistoryService.loadHistory();
      WatchedService.loadWatched();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final title = (widget.item.name).toUpperCase().endsWith('.')
        ? widget.item.name.toUpperCase()
        : '${widget.item.name.toUpperCase()}.';

    final backdrop = _detail?.backdrop ?? widget.item.cover;
    final cover = _detail?.cover ?? widget.item.cover;
    final plot = _detail?.plot ?? widget.item.plot ?? 'Sem sinopse disponível.';
    final rating = _detail?.rating != null && _detail!.rating > 0 ? _detail!.rating : widget.item.rating;

    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar Responsiva
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'DETALHES DA SÉRIE.',
                      style: AppTypography.titleMedium(fontSize: isNarrow ? 14 : 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: _isFavorite ? AppColors.statusLive : AppColors.textPrimary,
                      size: 22,
                    ),
                    tooltip: _isFavorite ? 'Remover dos Favoritos' : 'Adicionar aos Favoritos',
                    onPressed: _toggleFavorite,
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 8),
                    const TechCrosses(count: 3, opacity: 0.2),
                  ],
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(
                      child: HankoLoader(label: 'CARREGANDO SÉRIE.'),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(isNarrow ? 16 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLandscape)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: _buildPoster(cover),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildInfoSection(title, rating, plot, isNarrow),
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (backdrop != null && backdrop.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: CachedNetworkImage(
                                        imageUrl: backdrop,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const SizedBox(),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                _buildInfoSection(title, rating, plot, isNarrow),
                              ],
                            ),

                          const SizedBox(height: 16),

                          // Tabs de Conteúdo: Episódios vs Títulos Semelhantes
                          _buildTabsHeader(isNarrow),
                          const SizedBox(height: 12),

                          if (_activeTab == 0)
                            _buildSeasonsAndEpisodes()
                          else
                            _buildSimilarSeries(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(String? cover) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: cover != null && cover.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: cover,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceCard,
                  child: const Center(
                    child: Icon(Icons.video_collection_outlined, size: 48, color: AppColors.textMuted),
                  ),
                ),
              )
            : Container(
                color: AppColors.surfaceCard,
                child: const Center(
                  child: Icon(Icons.video_collection_outlined, size: 48, color: AppColors.textMuted),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoSection(String title, double rating, String plot, bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (rating > 0)
              HankoBadge(
                text: '★ ${rating.toStringAsFixed(1)}',
                borderColor: AppColors.accentPrimary,
                textColor: AppColors.accentPrimary,
              ),
            if (_detail?.releaseDate != null && _detail!.releaseDate!.isNotEmpty)
              HankoBadge(text: _detail!.releaseDate!),
            const HankoBadge(text: 'SÉRIE', borderColor: AppColors.accentCyan, textColor: AppColors.accentCyan),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: AppTypography.displayLarge().copyWith(fontSize: isNarrow ? 18 : 22),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),

        if (_detail?.genre != null && _detail!.genre!.isNotEmpty) ...[
          Text(
            _detail!.genre!.toUpperCase(),
            style: AppTypography.mono(fontSize: 11, color: AppColors.accentCyan),
          ),
          const SizedBox(height: 8),
        ],

        Text(
          plot,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body(color: AppColors.textPrimary).copyWith(fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 10),

        if (_detail?.cast != null && _detail!.cast!.isNotEmpty) ...[
          Text(
            'ELENCO: ${_detail!.cast}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: _toggleFavorite,
          icon: Icon(
            _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            color: _isFavorite ? AppColors.statusLive : AppColors.textPrimary,
            size: 16,
          ),
          label: Text(
            _isFavorite ? 'SALVO NOS FAVORITOS.' : 'ADICIONAR AOS FAVORITOS.',
            style: AppTypography.mono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _isFavorite ? AppColors.statusLive : AppColors.textPrimary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _isFavorite ? AppColors.statusLive : AppColors.borderHairline,
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        // Banner Continuar Assistindo (se houver episódio em andamento)
        ValueListenableBuilder<List<WatchHistoryItem>>(
          valueListenable: WatchHistoryService.historyNotifier,
          builder: (context, _, __) {
            return ValueListenableBuilder<List<WatchHistoryItem>>(
              valueListenable: FullWatchHistoryService.historyNotifier,
              builder: (context, _, __) {
                final savedItem = _getSavedSeriesHistory();
                if (savedItem == null) return const SizedBox.shrink();
                final isWatched = WatchedService.isWatchedSync(savedItem.id);
                if (isWatched) return const SizedBox.shrink();

                return _buildContinueWatchingBanner(savedItem, isNarrow);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildContinueWatchingBanner(WatchHistoryItem savedItem, bool isNarrow) {
    final remainingText = savedItem.remainingMinutes > 0 ? '${savedItem.remainingMinutes}M RESTANTES' : null;
    final progressPercent = (savedItem.progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: BentoCard(
        padding: const EdgeInsets.all(12),
        borderRadius: 10,
        backgroundColor: AppColors.surfaceHover,
        onTap: () => _resumeSavedHistory(savedItem),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accentPrimary.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.accentPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      HankoBadge(
                        text: context.tr('series.continue_watching'),
                        borderColor: AppColors.accentPrimary,
                        textColor: AppColors.accentPrimary,
                      ),
                      if (remainingText != null) ...[
                        const SizedBox(width: 6),
                        HankoBadge(
                          text: remainingText,
                          borderColor: AppColors.borderHairline,
                          textColor: AppColors.textMuted,
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '[ $progressPercent% ]',
                        style: AppTypography.mono(fontSize: 10, color: AppColors.accentCyan),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    savedItem.subtitle != null && savedItem.subtitle!.isNotEmpty
                        ? savedItem.subtitle!.toUpperCase()
                        : savedItem.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sectionTitle(fontSize: isNarrow ? 12 : 13),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: savedItem.progress,
                      minHeight: 3,
                      backgroundColor: AppColors.surfaceCard,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonsAndEpisodes() {
    if (_detail == null || _detail!.seasonNumbers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Center(
          child: Text(
            'NENHUM EPISÓDIO ENCONTRADO.',
            style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      );
    }

    final episodes = _selectedSeason != null
        ? (_detail!.episodesBySeason[_selectedSeason] ?? [])
        : <EpisodeItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TEMPORADAS & EPISÓDIOS.', style: AppTypography.sectionTitle()),
            const TechCrosses(count: 3, opacity: 0.2),
          ],
        ),
        const SizedBox(height: 14),

        // Tabs de Temporada
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _detail!.seasonNumbers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final season = _detail!.seasonNumbers[index];
              final isSelected = season == _selectedSeason;

              return _FocusableSeasonChip(
                season: season,
                isSelected: isSelected,
                onSelected: () {
                  setState(() => _selectedSeason = season);
                },
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Lista de episódios
        if (episodes.isEmpty)
          Center(
            child: Text(
              'SEM EPISÓDIOS NESSA TEMPORADA.',
              style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: episodes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final ep = episodes[index];
              final epMediaId = 'series_${widget.item.seriesId}_${ep.id}';

              return ValueListenableBuilder<Set<String>>(
                valueListenable: WatchedService.watchedNotifier,
                builder: (context, watchedSet, _) {
                  final isWatched = watchedSet.contains(epMediaId);
                  final savedEp = WatchHistoryService.getItem(epMediaId) ??
                      FullWatchHistoryService.getItem(epMediaId);
                  final isInProgress = !isWatched && savedEp != null && savedEp.progress > 0;

                  return BentoCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onTap: () => _playEpisode(ep),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isWatched
                                ? AppColors.statusLive.withValues(alpha: 0.15)
                                : (isInProgress
                                    ? AppColors.accentPrimary.withValues(alpha: 0.15)
                                    : AppColors.surfaceHover),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isWatched
                                  ? AppColors.statusLive.withValues(alpha: 0.5)
                                  : (isInProgress
                                      ? AppColors.accentPrimary.withValues(alpha: 0.6)
                                      : AppColors.borderHairline),
                            ),
                          ),
                          child: Text(
                            '${ep.episodeNum}',
                            style: AppTypography.mono(
                              fontSize: 13,
                              color: isWatched ? AppColors.statusLive : AppColors.accentPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      ep.title.toUpperCase(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.sectionTitle(
                                        fontSize: 13,
                                        color: isWatched ? AppColors.textMuted : AppColors.textPrimary,
                                      ).copyWith(height: 1.2),
                                    ),
                                  ),
                                  if (isWatched) ...[
                                    const SizedBox(width: 8),
                                    const HankoBadge(
                                      text: 'VISTO',
                                      borderColor: AppColors.statusLive,
                                      textColor: AppColors.statusLive,
                                    ),
                                  ] else if (isInProgress) ...[
                                    const SizedBox(width: 8),
                                    HankoBadge(
                                      text: '${(savedEp.progress * 100).toInt()}%',
                                      borderColor: AppColors.accentCyan,
                                      textColor: AppColors.accentCyan,
                                    ),
                                  ],
                                ],
                              ),
                              if (ep.duration != null &&
                                  ep.duration!.isNotEmpty &&
                                  ep.duration != '0' &&
                                  ep.duration != '00:00:00' &&
                                  ep.duration != '0:00' &&
                                  ep.duration != '0m') ...[
                                const SizedBox(height: 2),
                                Text(
                                  '[ DURAÇÃO: ${ep.duration} ]',
                                  style: AppTypography.mono(fontSize: 10, color: AppColors.accentCyan),
                                ),
                              ],
                              if (isInProgress) ...[
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: savedEp.progress,
                                    minHeight: 2,
                                    backgroundColor: AppColors.surfaceCard,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: isWatched ? 'Marcar como não visto' : 'Marcar como visto',
                          icon: Icon(
                            isWatched ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                            color: isWatched ? AppColors.statusLive : AppColors.textMuted,
                            size: 22,
                          ),
                          onPressed: () => WatchedService.toggleWatched(epMediaId),
                        ),
                        IconButton(
                          tooltip: 'Assistir',
                          icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.accentPrimary, size: 30),
                          onPressed: () => _playEpisode(ep),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildTabsHeader(bool isNarrow) {
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabButton(
            title: context.tr('series.episodes_tab'),
            badge: _detail != null ? '${_detail!.seasonNumbers.length} TEMP' : null,
            isSelected: _activeTab == 0,
            onTap: () => setState(() => _activeTab = 0),
            isFullWidth: true,
          ),
          const SizedBox(height: 10),
          _buildTabButton(
            title: context.tr('series.similar_tab'),
            badge: _similarSeries.isNotEmpty
                ? '${_similarSeries.length}'
                : (_loadingTmdb ? '...' : null),
            isSelected: _activeTab == 1,
            onTap: () => setState(() => _activeTab = 1),
            isFullWidth: true,
          ),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTabButton(
            title: context.tr('series.episodes_tab'),
            badge: _detail != null ? '${_detail!.seasonNumbers.length} TEMP' : null,
            isSelected: _activeTab == 0,
            onTap: () => setState(() => _activeTab = 0),
          ),
          const SizedBox(width: 10),
          _buildTabButton(
            title: context.tr('series.similar_tab'),
            badge: _similarSeries.isNotEmpty
                ? '${_similarSeries.length}'
                : (_loadingTmdb ? '...' : null),
            isSelected: _activeTab == 1,
            onTap: () => setState(() => _activeTab = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return _FocusableTabButton(
      title: title,
      badge: badge,
      isSelected: isSelected,
      onTap: onTap,
      isFullWidth: isFullWidth,
    );
  }

  Widget _buildSimilarSeries() {
    if (_loadingTmdb && _similarSeries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: HankoLoader(label: 'BUSCANDO SEMELHANTES.'),
        ),
      );
    }

    if (_similarSeries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.movie_filter_outlined, size: 40, color: AppColors.textDisabled),
              const SizedBox(height: 12),
              Text(
                context.tr('series.no_similar'),
                textAlign: TextAlign.center,
                style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final seriesProvider = context.read<SeriesProvider>();
    final allSeries = seriesProvider.filteredSeries.isNotEmpty
        ? seriesProvider.filteredSeries
        : seriesProvider.seriesList;

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(context.tr('series.similar_title'), style: AppTypography.sectionTitle()),
                const SizedBox(width: 8),
                const HankoBadge(text: 'TMDB', borderColor: AppColors.accentCyan, textColor: AppColors.accentCyan),
              ],
            ),
            const TechCrosses(count: 3, opacity: 0.2),
          ],
        ),
        const SizedBox(height: 16),
        if (!isLandscape)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _similarSeries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final show = _similarSeries[index];
              final iptvMatch = _findIptvMatch(show.title, allSeries);
              final year = show.releaseDate != null && show.releaseDate!.length >= 4
                  ? show.releaseDate!.substring(0, 4)
                  : '';

              return BrutalistEntrance(
                index: index,
                child: BentoCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  borderRadius: 10,
                  onTap: () {
                    if (iptvMatch != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SeriesDetailScreen(item: iptvMatch),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.surfaceCard,
                          content: Text(
                            'Título não disponível na lista atual do seu IPTV.',
                            style: AppTypography.mono(color: AppColors.accentCyan),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      // Poster thumbnail compacto
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 48,
                          height: 66,
                          color: AppColors.surfaceHover,
                          child: show.posterUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: show.posterUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(
                                    child: HankoLoader.mini(miniSize: 18),
                                  ),
                                  errorWidget: (_, __, ___) => _buildFallbackCover(),
                                )
                              : _buildFallbackCover(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Duas linhas de informações ocupando 100% de largura
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Linha 1: Título da Série
                            Text(
                              show.title.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleMedium(
                                fontSize: 13,
                                color: iptvMatch != null ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Linha 2: Metadados, Avaliação e Badges
                            Row(
                              children: [
                                if (year.isNotEmpty) ...[
                                  Text(
                                    year,
                                    style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (show.rating > 0) ...[
                                  HankoBadge(
                                    text: '★ ${show.rating.toStringAsFixed(1)}',
                                    borderColor: AppColors.accentPrimary.withValues(alpha: 0.6),
                                    textColor: AppColors.accentPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (iptvMatch != null)
                                  const HankoBadge(
                                    text: 'DISPONÍVEL',
                                    borderColor: AppColors.statusLive,
                                    textColor: AppColors.statusLive,
                                  )
                                else
                                  const HankoBadge(
                                    text: 'TMDB',
                                    borderColor: AppColors.borderHairline,
                                    textColor: AppColors.textMuted,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: iptvMatch != null ? AppColors.accentPrimary : AppColors.textDisabled,
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = (constraints.maxWidth / 160).floor().clamp(2, 6);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.58,
                ),
                itemCount: _similarSeries.length,
                itemBuilder: (context, index) {
                  final show = _similarSeries[index];
                  final iptvMatch = _findIptvMatch(show.title, allSeries);

                  return BrutalistEntrance(
                    index: index,
                    child: BentoCard(
                      padding: EdgeInsets.zero,
                      borderRadius: 10,
                      onTap: () {
                        if (iptvMatch != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SeriesDetailScreen(item: iptvMatch),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.surfaceCard,
                              content: Text(
                                'Título não disponível na lista atual do seu IPTV.',
                                style: AppTypography.mono(color: AppColors.accentCyan),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Poster da Série
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                  child: show.posterUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: show.posterUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => const Center(
                                            child: HankoLoader.mini(miniSize: 22),
                                          ),
                                          errorWidget: (_, __, ___) => _buildFallbackCover(),
                                        )
                                      : _buildFallbackCover(),
                                ),
                                if (iptvMatch != null)
                                  const Positioned(
                                    top: 6,
                                    left: 6,
                                    child: HankoBadge(
                                      text: 'DISPONÍVEL',
                                      borderColor: AppColors.statusLive,
                                      textColor: AppColors.statusLive,
                                    ),
                                  ),
                                if (show.rating > 0)
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: HankoBadge(
                                      text: '★ ${show.rating.toStringAsFixed(1)}',
                                      borderColor: AppColors.accentPrimary,
                                      textColor: AppColors.accentPrimary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Informações
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  show.title.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.titleMedium(fontSize: 11, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  iptvMatch != null
                                      ? '[ NO SEU CATÁLOGO ]'
                                      : (show.releaseDate != null && show.releaseDate!.length >= 4
                                          ? show.releaseDate!.substring(0, 4)
                                          : 'TMDB'),
                                  style: AppTypography.mono(
                                    fontSize: 9.5,
                                    color: iptvMatch != null ? AppColors.accentCyan : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  SeriesItem? _findIptvMatch(String title, List<SeriesItem> catalog) {
    final cleanTmdb = _cleanString(title);
    if (cleanTmdb.isEmpty) return null;
    for (final s in catalog) {
      final cleanCatalog = _cleanString(s.name);
      if (cleanCatalog == cleanTmdb ||
          cleanCatalog.contains(cleanTmdb) ||
          cleanTmdb.contains(cleanCatalog)) {
        return s;
      }
    }
    return null;
  }

  String _cleanString(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  Widget _buildFallbackCover() {
    return Container(
      color: AppColors.surfaceCard,
      child: const Center(
        child: Icon(Icons.tv_rounded, color: AppColors.textDisabled, size: 32),
      ),
    );
  }
}

class _FocusableSeasonChip extends StatefulWidget {
  final String season;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FocusableSeasonChip({
    required this.season,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  State<_FocusableSeasonChip> createState() => _FocusableSeasonChipState();
}

class _FocusableSeasonChipState extends State<_FocusableSeasonChip> {
  bool _isFocused = false;
  bool _isHovered = false;

  void _onFocusChanged(bool focused) {
    setState(() => _isFocused = focused);
    if (focused && mounted) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _isFocused ? 1.05 : (_isHovered ? 1.02 : 1.0);

    return FocusableActionDetector(
      onShowFocusHighlight: _onFocusChanged,
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onSelected(),
        ),
      },
      child: GestureDetector(
        onTap: widget.onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.diagonal3Values(scale, scale, 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accentPrimary
                : (_isFocused ? AppColors.surfaceHover : AppColors.surfaceCard),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused
                  ? AppColors.accentCyan
                  : (widget.isSelected ? AppColors.accentPrimary : AppColors.borderHairline),
              width: _isFocused ? 2.0 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.accentCyan.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            'TEMP ${widget.season}',
            style: AppTypography.mono(
              fontSize: 12,
              color: widget.isSelected
                  ? Colors.white
                  : (_isFocused ? AppColors.accentCyan : AppColors.textPrimary),
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _FocusableTabButton extends StatefulWidget {
  final String title;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFullWidth;

  const _FocusableTabButton({
    required this.title,
    this.badge,
    required this.isSelected,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  State<_FocusableTabButton> createState() => _FocusableTabButtonState();
}

class _FocusableTabButtonState extends State<_FocusableTabButton> {
  bool _isFocused = false;
  bool _isHovered = false;

  void _onFocusChanged(bool focused) {
    setState(() => _isFocused = focused);
    if (focused && mounted) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: _onFocusChanged,
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onTap(),
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accentPrimary.withValues(alpha: 0.15)
                : (_isFocused || _isHovered ? AppColors.surfaceHover : AppColors.surfaceCard),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused
                  ? AppColors.accentCyan
                  : (widget.isSelected ? AppColors.accentPrimary : AppColors.borderHairline),
              width: _isFocused ? 2.0 : (widget.isSelected ? 1.5 : 1.0),
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.accentCyan.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: widget.isFullWidth ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: AppTypography.mono(
                  fontSize: 12,
                  color: _isFocused
                      ? AppColors.accentCyan
                      : (widget.isSelected ? AppColors.textPrimary : AppColors.textMuted),
                ).copyWith(fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500),
              ),
              if (widget.badge != null) ...[
                const SizedBox(width: 8),
                HankoBadge(
                  text: widget.badge!,
                  borderColor: widget.isSelected ? AppColors.accentPrimary : AppColors.borderHairline,
                  textColor: widget.isSelected ? AppColors.accentPrimary : AppColors.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

