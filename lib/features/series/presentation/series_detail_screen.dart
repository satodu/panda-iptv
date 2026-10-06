import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/storage/favorite_item.dart';
import '../../../core/storage/favorites_service.dart';
import '../../../core/storage/watch_history_service.dart';
import '../../../core/storage/watched_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/hanko_badge.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _checkFavorite();
    WatchedService.loadWatched();
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

  Future<void> _loadDetail() async {
    final account = context.read<AuthProvider>().currentAccount;
    if (account == null) return;

    final detail = await context.read<SeriesProvider>().loadSeriesDetail(account, widget.item.seriesId);
    if (mounted) {
      setState(() {
        _detail = detail;
        _loading = false;
        if (detail != null && detail.seasonNumbers.isNotEmpty) {
          _selectedSeason = detail.seasonNumbers.first;
        }
      });
    }
  }

  void _playEpisode(EpisodeItem episode) {
    final account = context.read<AuthProvider>().currentAccount;
    if (account == null) return;

    final seriesProvider = context.read<SeriesProvider>();
    final episodes = _detail?.episodesBySeason[_selectedSeason] ?? [];

    final playlist = episodes.map((ep) {
      final url = seriesProvider.buildStreamUrl(account, ep.id, ep.containerExtension);
      final epCandidates = [
        ep.image,
        _detail?.cover,
        _detail?.backdrop,
        widget.item.cover,
      ];
      final epCover = epCandidates.firstWhere(
        (c) => c != null && c.trim().isNotEmpty,
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
      episode.image,
      _detail?.cover,
      _detail?.backdrop,
      widget.item.cover,
    ];
    final selectedCover = selectedCandidates.firstWhere(
      (c) => c != null && c.trim().isNotEmpty,
      orElse: () => null,
    );

    final mediaId = 'series_${widget.item.seriesId}_${episode.id}';
    final saved = WatchHistoryService.getItem(mediaId);
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
    ).then((_) => WatchHistoryService.loadHistory());
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
                      child: CircularProgressIndicator(color: AppColors.accentPrimary),
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
                                  width: 240,
                                  child: _buildPoster(cover),
                                ),
                                const SizedBox(width: 32),
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
                                const SizedBox(height: 20),
                                _buildInfoSection(title, rating, plot, isNarrow),
                              ],
                            ),

                          const SizedBox(height: 32),

                          // Temporadas e Episódios
                          _buildSeasonsAndEpisodes(),
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
          style: AppTypography.displayLarge().copyWith(fontSize: isNarrow ? 22 : 28),
        ),
        const SizedBox(height: 8),

        if (_detail?.genre != null && _detail!.genre!.isNotEmpty) ...[
          Text(
            _detail!.genre!.toUpperCase(),
            style: AppTypography.mono(fontSize: 12, color: AppColors.accentCyan),
          ),
          const SizedBox(height: 12),
        ],

        Text(
          plot,
          style: AppTypography.body(color: AppColors.textPrimary).copyWith(height: 1.5),
        ),
        const SizedBox(height: 16),

        if (_detail?.cast != null && _detail!.cast!.isNotEmpty) ...[
          Text(
            'ELENCO: ${_detail!.cast}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
        ],
        OutlinedButton.icon(
          onPressed: _toggleFavorite,
          icon: Icon(
            _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            color: _isFavorite ? AppColors.statusLive : AppColors.textPrimary,
            size: 18,
          ),
          label: Text(
            _isFavorite ? 'SALVO NOS FAVORITOS.' : 'ADICIONAR AOS FAVORITOS.',
            style: AppTypography.mono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isFavorite ? AppColors.statusLive : AppColors.textPrimary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _isFavorite ? AppColors.statusLive : AppColors.borderHairline,
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
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

              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() => _selectedSeason = season);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentPrimary : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.accentPrimary : AppColors.borderHairline,
                    ),
                  ),
                  child: Text(
                    'TEMPORADA $season',
                    style: AppTypography.mono(
                      fontSize: 11,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
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
                                : AppColors.surfaceHover,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isWatched
                                  ? AppColors.statusLive.withValues(alpha: 0.5)
                                  : AppColors.borderHairline,
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
                                  ],
                                ],
                              ),
                              if (ep.duration != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '[ DURAÇÃO: ${ep.duration} ]',
                                  style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted),
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
}
