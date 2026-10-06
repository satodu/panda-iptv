import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/tmdb_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/brutalist_entrance.dart';
import '../../../core/widgets/hanko_badge.dart';
import '../../../core/widgets/tech_crosses.dart';
import '../models/vod_item.dart';
import 'vod_detail_screen.dart';
import 'vod_provider.dart';

class ActorDetailScreen extends StatefulWidget {
  final int actorId;
  final String actorName;
  final String? actorPhoto;

  const ActorDetailScreen({
    super.key,
    required this.actorId,
    required this.actorName,
    this.actorPhoto,
  });

  @override
  State<ActorDetailScreen> createState() => _ActorDetailScreenState();
}

class _ActorDetailScreenState extends State<ActorDetailScreen> {
  TmdbActorDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActor();
  }

  void _loadActor() async {
    final detail = await TmdbService.getActorDetail(widget.actorId);
    if (mounted) {
      setState(() {
        _detail = detail;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final name = _detail?.name ?? widget.actorName;
    final photo = _detail?.profileUrl ?? widget.actorPhoto;
    final bio = _detail?.biography != null && _detail!.biography!.trim().isNotEmpty
        ? _detail!.biography!
        : 'Sem biografia disponível.';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
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
                      'PERFIL DO ATOR.',
                      style: AppTypography.titleMedium(fontSize: isNarrow ? 14 : 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const TechCrosses(count: 3, opacity: 0.2),
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
                          // Header: Foto + Informações
                          isLandscape
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildActorPhoto(photo, isNarrow),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildActorInfo(name, bio, isNarrow),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _buildActorPhoto(photo, isNarrow),
                                    const SizedBox(height: 16),
                                    _buildActorInfo(name, bio, isNarrow),
                                  ],
                                ),

                          const SizedBox(height: 32),

                          // Filmografia / Filmes do Ator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'FILMOGRAFIA.',
                                    style: AppTypography.sectionTitle(),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_detail != null)
                                    HankoBadge(
                                      text: '[ ${_detail!.filmography.length} ]',
                                      borderColor: AppColors.accentPrimary,
                                      textColor: AppColors.accentPrimary,
                                    ),
                                ],
                              ),
                              const TechCrosses(count: 3, spacing: 6),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildFilmographyGrid(context, isNarrow),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActorPhoto(String? photo, bool isNarrow) {
    return Container(
      width: isNarrow ? 120 : 160,
      height: isNarrow ? 160 : 210,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: photo != null && photo.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photo,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.person_rounded, size: 48, color: AppColors.textDisabled),
                ),
              )
            : const Center(
                child: Icon(Icons.person_rounded, size: 48, color: AppColors.textDisabled),
              ),
      ),
    );
  }

  Widget _buildActorInfo(String name, String bio, bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HankoBadge(
          text: 'ELENCO PRINCIPAL // TMDB',
          borderColor: AppColors.accentCyan,
          textColor: AppColors.accentCyan,
        ),
        const SizedBox(height: 8),
        Text(
          name.toUpperCase(),
          style: AppTypography.displayLarge().copyWith(fontSize: isNarrow ? 22 : 28),
        ),
        if (_detail?.placeOfBirth != null) ...[
          const SizedBox(height: 4),
          Text(
            'ORIGEM: ${_detail!.placeOfBirth}',
            style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
        if (_detail?.birthday != null) ...[
          const SizedBox(height: 2),
          Text(
            'NASCIMENTO: ${_detail!.birthday}',
            style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          bio,
          style: AppTypography.body(color: AppColors.textPrimary).copyWith(height: 1.5),
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFilmographyGrid(BuildContext context, bool isNarrow) {
    if (_detail == null || _detail!.filmography.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'NENHUM FILME ENCONTRADO.',
            style: AppTypography.mono(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final vodProvider = context.read<VodProvider>();
    final allIptvMovies = vodProvider.filteredMovies;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 5;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.65,
          ),
          itemCount: _detail!.filmography.length,
          itemBuilder: (context, index) {
            final movie = _detail!.filmography[index];
            final poster = movie.posterUrl;

            // Tenta encontrar se o filme existe na lista do IPTV
            final iptvMatch = allIptvMovies.cast<VodItem?>().firstWhere(
              (m) => m != null && m.name.toLowerCase().contains(movie.title.toLowerCase()),
              orElse: () => null,
            );

            return BrutalistEntrance(
              index: index,
              child: BentoCard(
                padding: EdgeInsets.zero,
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
                          'Título não encontrado na lista atual do seu IPTV.',
                          style: AppTypography.mono(color: AppColors.accentCyan),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
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
                              top: 8,
                              left: 8,
                              child: HankoBadge(
                                text: 'DISPONÍVEL',
                                borderColor: AppColors.statusLive,
                                textColor: AppColors.statusLive,
                              ),
                            ),
                          if (movie.rating > 0)
                            Positioned(
                              bottom: 8,
                              right: 8,
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
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium(fontSize: 12),
                          ),
                          if (movie.releaseDate != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              movie.releaseDate!.split('-').first,
                              style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
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
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      color: AppColors.surfaceCard,
      child: const Center(
        child: Icon(Icons.movie_outlined, size: 36, color: AppColors.textDisabled),
      ),
    );
  }
}
