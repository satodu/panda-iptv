import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import '../../../core/widgets/brutalist_button.dart';
import '../../../core/widgets/brutalist_entrance.dart';
import '../../../core/widgets/hanko_badge.dart';
import '../../../core/widgets/hanko_loader.dart';
import '../../../core/widgets/tech_crosses.dart';
import '../../../core/services/tmdb_service.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../player/presentation/video_player_screen.dart';
import '../models/vod_detail.dart';
import '../models/vod_item.dart';
import 'actor_detail_screen.dart';
import 'vod_provider.dart';

class VodDetailScreen extends StatefulWidget {
  final VodItem item;

  const VodDetailScreen({super.key, required this.item});

  @override
  State<VodDetailScreen> createState() => _VodDetailScreenState();
}

class _VodDetailScreenState extends State<VodDetailScreen> {
  VodDetail? _detail;
  bool _loading = true;
  bool _isFavorite = false;

  List<TmdbMovie> _similarMovies = [];
  List<TmdbActor> _cast = [];
  bool _loadingTmdb = false;
  String? _movieDuration;

  @override
  void initState() {
    super.initState();
    WatchHistoryService.loadHistory();
    FullWatchHistoryService.loadHistory();
    WatchedService.loadWatched();
    _loadDetail();
    _checkFavorite();
  }

  WatchHistoryItem? _getSavedMovieHistory() {
    final mediaId = 'vod_${widget.item.streamId}';
    final active = WatchHistoryService.getItem(mediaId);
    if (active != null) return active;
    return FullWatchHistoryService.getItem(mediaId);
  }

  void _checkFavorite() async {
    final isFav = await FavoritesService.isFavorite('vod_${widget.item.streamId}');
    if (mounted) setState(() => _isFavorite = isFav);
  }

  void _toggleFavorite() async {
    final item = FavoriteItem(
      id: 'vod_${widget.item.streamId}',
      title: widget.item.name,
      type: 'movie',
      cover: _detail?.cover ?? widget.item.streamIcon,
      rating: _detail?.rating ?? widget.item.rating,
      genre: _detail?.genre,
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

    final detail = await context.read<VodProvider>().loadVodDetail(account, widget.item.streamId);
    if (mounted) {
      setState(() {
        _detail = detail;
        _movieDuration = detail?.duration;
        _loading = false;
      });
      _loadTmdbData(detail);
    }
  }

  Future<void> _loadTmdbData(VodDetail? detail) async {
    if (detail == null) return;
    setState(() => _loadingTmdb = true);

    int? tmdbId = detail.tmdbId;
    if (tmdbId == null || tmdbId == 0) {
      tmdbId = await TmdbService.searchMovieId(
        widget.item.name,
        year: detail.releaseDate,
      );
    }

    if (tmdbId != null && tmdbId > 0 && mounted) {
      final similar = await TmdbService.getSimilarMovies(tmdbId);
      final cast = await TmdbService.getMovieCredits(tmdbId);

      // Se a duração do provedor for nula ou inválida, busca do TMDB
      if (_movieDuration == null || _movieDuration!.isEmpty) {
        final runtime = await TmdbService.getMovieRuntime(tmdbId);
        if (runtime != null && runtime > 0) {
          final h = runtime ~/ 60;
          final m = runtime % 60;
          _movieDuration = h > 0 ? '${h}h ${m}m' : '${m}m';
        }
      }

      if (mounted) {
        setState(() {
          _similarMovies = similar;
          _cast = cast;
          _loadingTmdb = false;
        });
      }
    } else if (mounted) {
      setState(() => _loadingTmdb = false);
    }
  }

  void _playMovie({bool fromStart = false}) {
    final account = context.read<AuthProvider>().currentAccount;
    if (account == null) return;

    final vodProvider = context.read<VodProvider>();
    final ext = _detail?.containerExtension ?? widget.item.containerExtension;
    final streamUrl = vodProvider.buildStreamUrl(account, widget.item.streamId, ext);

    final mediaId = 'vod_${widget.item.streamId}';
    final saved = _getSavedMovieHistory();
    final initialPos = (!fromStart && saved != null && saved.positionMs > 5000) ? saved.positionMs : null;

    bool isValidImg(String? s) {
      if (s == null) return false;
      final t = s.trim().toLowerCase();
      return t.isNotEmpty && t != 'null' && t != 'undefined' && (t.startsWith('http://') || t.startsWith('https://'));
    }

    final coverCandidates = [
      widget.item.streamIcon,
      _detail?.cover,
      _detail?.backdrop,
    ];
    final coverUrl = coverCandidates.firstWhere(
      isValidImg,
      orElse: () => null,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          title: widget.item.name,
          subtitle: 'FILMES // VOD',
          streamUrl: streamUrl,
          mediaId: mediaId,
          cover: coverUrl,
          initialPositionMs: initialPos,
          mediaType: 'movie',
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

    final backdrop = _detail?.backdrop ?? widget.item.streamIcon;
    final cover = _detail?.cover ?? widget.item.streamIcon;
    final plot = _detail?.plot ?? 'Sem sinopse disponível.';
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
                      'DETALHES DO FILME.',
                      style: AppTypography.titleMedium(fontSize: isNarrow ? 14 : 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: WatchedService.watchedNotifier,
                    builder: (context, watchedSet, _) {
                      final isWatched = watchedSet.contains('vod_${widget.item.streamId}');
                      return IconButton(
                        icon: Icon(
                          isWatched ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                          color: isWatched ? AppColors.statusLive : AppColors.textPrimary,
                          size: 22,
                        ),
                        tooltip: isWatched ? 'Marcar como não visto' : 'Marcar como visto',
                        onPressed: () {
                          WatchedService.toggleWatched('vod_${widget.item.streamId}');
                          if (!isWatched) {
                            AppToast.success(context, 'MARCADO COMO VISTO.');
                          } else {
                            AppToast.info(context, 'DESMARCADO COMO VISTO.');
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 4),
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
                      child: HankoLoader(label: 'CARREGANDO FILME.'),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(isNarrow ? 16 : 24),
                      child: isLandscape
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Poster
                                    SizedBox(
                                      width: 260,
                                      child: _buildPoster(cover),
                                    ),
                                    const SizedBox(width: 32),
                                    // Informações
                                    Expanded(
                                      child: _buildInfoSection(title, rating, plot, isLandscape, isNarrow),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 36),
                                _buildCastSection(context, isNarrow),
                                const SizedBox(height: 36),
                                _buildSimilarMoviesSection(context, isNarrow),
                              ],
                            )
                          : Column(
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
                                _buildInfoSection(title, rating, plot, isLandscape, isNarrow),
                                const SizedBox(height: 32),
                                _buildCastSection(context, isNarrow),
                                const SizedBox(height: 32),
                                _buildSimilarMoviesSection(context, isNarrow),
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
                    child: Icon(Icons.movie_outlined, size: 48, color: AppColors.textMuted),
                  ),
                ),
              )
            : Container(
                color: AppColors.surfaceCard,
                child: const Center(
                  child: Icon(Icons.movie_outlined, size: 48, color: AppColors.textMuted),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoSection(String title, double rating, String plot, bool isLandscape, bool isNarrow) {
    final mediaId = 'vod_${widget.item.streamId}';

    return ValueListenableBuilder<Set<String>>(
      valueListenable: WatchedService.watchedNotifier,
      builder: (context, watchedSet, _) {
        final isWatched = watchedSet.contains(mediaId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isWatched)
                  const HankoBadge(
                    text: 'VISTO',
                    borderColor: AppColors.statusLive,
                    textColor: AppColors.statusLive,
                  ),
                if (rating > 0)
                  HankoBadge(
                    text: '★ ${rating.toStringAsFixed(1)}',
                    borderColor: AppColors.accentPrimary,
                    textColor: AppColors.accentPrimary,
                  ),
                if (_movieDuration != null &&
                    _movieDuration!.isNotEmpty &&
                    _movieDuration != '0' &&
                    _movieDuration != '00:00:00' &&
                    _movieDuration != '0m')
                  HankoBadge(text: _movieDuration!),
                if (_detail?.releaseDate != null && _detail!.releaseDate!.isNotEmpty)
                  HankoBadge(text: _detail!.releaseDate!),
                const HankoBadge(text: '1080P HD', borderColor: AppColors.accentCyan, textColor: AppColors.accentCyan),
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
            const SizedBox(height: 24),

            if (_detail?.director != null && _detail!.director!.isNotEmpty) ...[
              Text(
                'DIRETOR: ${_detail!.director}',
                style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
            ],

            if (_detail?.cast != null && _detail!.cast!.isNotEmpty) ...[
              Text(
                'ELENCO: ${_detail!.cast}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
            ],

            // Banner Continuar Assistindo (se houver filme em andamento)
            ValueListenableBuilder<List<WatchHistoryItem>>(
              valueListenable: WatchHistoryService.historyNotifier,
              builder: (context, _, __) {
                return ValueListenableBuilder<List<WatchHistoryItem>>(
                  valueListenable: FullWatchHistoryService.historyNotifier,
                  builder: (context, _, __) {
                    final savedItem = _getSavedMovieHistory();
                    if (savedItem == null) return const SizedBox.shrink();
                    final isWatched = WatchedService.isWatchedSync(mediaId);
                    if (isWatched || savedItem.progress <= 0 || savedItem.positionMs <= 5000) {
                      return const SizedBox.shrink();
                    }

                    return _buildContinueWatchingBanner(savedItem, isNarrow);
                  },
                );
              },
            ),

            const SizedBox(height: 16),
            ValueListenableBuilder<List<WatchHistoryItem>>(
              valueListenable: WatchHistoryService.historyNotifier,
              builder: (context, _, __) {
                final savedItem = _getSavedMovieHistory();
                final isInProgress = savedItem != null &&
                    !isWatched &&
                    savedItem.progress > 0 &&
                    savedItem.positionMs > 5000;

                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: isLandscape ? 220 : double.infinity,
                      child: BrutalistButton(
                        label: isInProgress ? 'CONTINUAR FILME.' : 'ASSISTIR AGORA.',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => _playMovie(fromStart: false),
                      ),
                    ),
                    if (isInProgress)
                      OutlinedButton.icon(
                        onPressed: () => _playMovie(fromStart: true),
                        icon: const Icon(Icons.replay_rounded, size: 18, color: AppColors.textPrimary),
                        label: Text(
                          'DO INÍCIO.',
                          style: AppTypography.mono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        style: ButtonStyle(
                          side: WidgetStateProperty.resolveWith<BorderSide>((states) {
                            if (states.contains(WidgetState.focused)) {
                              return const BorderSide(color: AppColors.accentCyan, width: 2.0);
                            }
                            return const BorderSide(color: AppColors.borderHairline, width: 1.0);
                          }),
                          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.focused)) {
                              return AppColors.surfaceHover;
                            }
                            return Colors.transparent;
                          }),
                          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () {
                        WatchedService.toggleWatched(mediaId);
                        if (!isWatched) {
                          AppToast.success(context, 'MARCADO COMO VISTO.');
                        } else {
                          AppToast.info(context, 'DESMARCADO COMO VISTO.');
                        }
                      },
                      icon: Icon(
                        isWatched ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                        color: isWatched ? AppColors.statusLive : AppColors.textPrimary,
                        size: 18,
                      ),
                      label: Text(
                        isWatched ? 'VISTO.' : 'MARCAR COMO VISTO.',
                        style: AppTypography.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isWatched ? AppColors.statusLive : AppColors.textPrimary,
                        ),
                      ),
                      style: ButtonStyle(
                        side: WidgetStateProperty.resolveWith<BorderSide>((states) {
                          if (states.contains(WidgetState.focused)) {
                            return const BorderSide(color: AppColors.accentCyan, width: 2.0);
                          }
                          return BorderSide(
                            color: isWatched ? AppColors.statusLive : AppColors.borderHairline,
                            width: 1.0,
                          );
                        }),
                        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                          if (states.contains(WidgetState.focused)) {
                            return AppColors.surfaceHover;
                          }
                          return Colors.transparent;
                        }),
                        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                        color: _isFavorite ? AppColors.statusLive : AppColors.textPrimary,
                        size: 18,
                      ),
                      label: Text(
                        _isFavorite ? 'SALVO NOS FAVORITOS.' : 'FAVORITAR.',
                        style: AppTypography.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isFavorite ? AppColors.statusLive : AppColors.textPrimary,
                        ),
                      ),
                      style: ButtonStyle(
                        side: WidgetStateProperty.resolveWith<BorderSide>((states) {
                          if (states.contains(WidgetState.focused)) {
                            return const BorderSide(color: AppColors.accentCyan, width: 2.0);
                          }
                          return BorderSide(
                            color: _isFavorite ? AppColors.statusLive : AppColors.borderHairline,
                            width: 1.0,
                          );
                        }),
                        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                          if (states.contains(WidgetState.focused)) {
                            return AppColors.surfaceHover;
                          }
                          return Colors.transparent;
                        }),
                        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildContinueWatchingBanner(WatchHistoryItem savedItem, bool isNarrow) {
    final remainingText = savedItem.remainingMinutes > 0 ? '${savedItem.remainingMinutes}M RESTANTES' : null;
    final progressPercent = (savedItem.progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: BentoCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 10,
        backgroundColor: AppColors.surfaceHover,
        onTap: () => _playMovie(fromStart: false),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (remainingText != null)
                        Text(
                          remainingText,
                          style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted),
                        )
                      else
                        const SizedBox.shrink(),
                      Text(
                        '[ $progressPercent% ]',
                        style: AppTypography.mono(fontSize: 10, color: AppColors.accentCyan),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'CONTINUAR DE ONDE PAROU.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sectionTitle(fontSize: isNarrow ? 12 : 13).copyWith(height: 1.25),
                  ),
                  const SizedBox(height: 8),
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

  Widget _buildCastSection(BuildContext context, bool isNarrow) {
    if (_cast.isEmpty) {
      if (_loadingTmdb) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: HankoLoader.compact(label: 'CARREGANDO ELENCO.'),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'ELENCO PRINCIPAL.',
                  style: AppTypography.sectionTitle(fontSize: isNarrow ? 14 : 16),
                ),
                const SizedBox(width: 8),
                const HankoBadge(
                  text: 'TMDB',
                  borderColor: AppColors.accentCyan,
                  textColor: AppColors.accentCyan,
                ),
              ],
            ),
            const TechCrosses(count: 3, spacing: 6),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 165,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            itemCount: _cast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final actor = _cast[index];
              return BrutalistEntrance(
                index: index,
                child: BentoCard(
                  padding: const EdgeInsets.all(8),
                  borderRadius: 10,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ActorDetailScreen(
                          actorId: actor.id,
                          actorName: actor.name,
                          actorPhoto: actor.profileUrl,
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 95,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 60,
                            height: 60,
                            color: AppColors.surfaceHover,
                            child: actor.profileUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: actor.profileUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.person_rounded,
                                      size: 30,
                                      color: AppColors.textDisabled,
                                    ),
                                  )
                                : const Icon(Icons.person_rounded, size: 30, color: AppColors.textDisabled),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          actor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTypography.titleMedium(fontSize: 11),
                        ),
                        if (actor.character != null && actor.character!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            actor.character!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTypography.mono(fontSize: 9, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarMoviesSection(BuildContext context, bool isNarrow) {
    if (_similarMovies.isEmpty) return const SizedBox.shrink();

    final vodProvider = context.read<VodProvider>();
    final allIptvMovies = vodProvider.filteredMovies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'TÍTULOS SEMELHANTES.',
                  style: AppTypography.sectionTitle(fontSize: isNarrow ? 14 : 16),
                ),
                const SizedBox(width: 8),
                HankoBadge(
                  text: '[ ${_similarMovies.length} ]',
                  borderColor: AppColors.accentPrimary,
                  textColor: AppColors.accentPrimary,
                ),
              ],
            ),
            const TechCrosses(count: 3, spacing: 6),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _similarMovies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final movie = _similarMovies[index];
              final poster = movie.posterUrl;

              final iptvMatch = allIptvMovies.cast<VodItem?>().firstWhere(
                (m) => m != null && m.name.toLowerCase().contains(movie.title.toLowerCase()),
                orElse: () => null,
              );

              return BrutalistEntrance(
                index: index,
                child: BentoCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 10,
                  onTap: () {
                    if (iptvMatch != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VodDetailScreen(item: iptvMatch),
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
                  child: SizedBox(
                    width: 125,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                child: poster != null
                                    ? CachedNetworkImage(
                                        imageUrl: poster,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => _buildFallbackCover(),
                                      )
                                    : _buildFallbackCover(),
                              ),
                              if (iptvMatch != null)
                                const Positioned(
                                  top: 6,
                                  left: 6,
                                  child: HankoBadge(
                                    text: 'PLAY',
                                    borderColor: AppColors.statusLive,
                                    textColor: AppColors.statusLive,
                                  ),
                                ),
                              if (movie.rating > 0)
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: HankoBadge(
                                    text: '★ ${movie.rating.toStringAsFixed(1)}',
                                    borderColor: AppColors.accentPrimary,
                                    textColor: AppColors.accentPrimary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      color: AppColors.surfaceCard,
      child: const Center(
        child: Icon(Icons.movie_outlined, size: 32, color: AppColors.textDisabled),
      ),
    );
  }
}
