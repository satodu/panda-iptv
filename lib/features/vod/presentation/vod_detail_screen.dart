import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/brutalist_button.dart';
import '../../../core/widgets/hanko_badge.dart';
import '../../../core/widgets/tech_crosses.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../player/presentation/video_player_screen.dart';
import '../models/vod_detail.dart';
import '../models/vod_item.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final account = context.read<AuthProvider>().currentAccount;
    if (account == null) return;

    final detail = await context.read<VodProvider>().loadVodDetail(account, widget.item.streamId);
    if (mounted) {
      setState(() {
        _detail = detail;
        _loading = false;
      });
    }
  }

  void _playMovie() {
    final account = context.read<AuthProvider>().currentAccount;
    if (account == null) return;

    final vodProvider = context.read<VodProvider>();
    final ext = _detail?.containerExtension ?? widget.item.containerExtension;
    final streamUrl = vodProvider.buildStreamUrl(account, widget.item.streamId, ext);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          title: widget.item.name,
          subtitle: 'FILMES // VOD',
          streamUrl: streamUrl,
        ),
      ),
    );
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

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text('DETALHES DO FILME.', style: AppTypography.titleMedium()),
                  const Spacer(),
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
                      padding: const EdgeInsets.all(24),
                      child: isLandscape
                          ? Row(
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
                                  child: _buildInfoSection(title, rating, plot),
                                ),
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
                                _buildInfoSection(title, rating, plot),
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

  Widget _buildInfoSection(String title, double rating, String plot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (rating > 0) ...[
              HankoBadge(
                text: '★ ${rating.toStringAsFixed(1)}',
                borderColor: AppColors.accentPrimary,
                textColor: AppColors.accentPrimary,
              ),
              const SizedBox(width: 10),
            ],
            if (_detail?.duration != null) ...[
              HankoBadge(text: _detail!.duration!),
              const SizedBox(width: 10),
            ],
            if (_detail?.releaseDate != null && _detail!.releaseDate!.isNotEmpty) ...[
              HankoBadge(text: _detail!.releaseDate!),
              const SizedBox(width: 10),
            ],
            const HankoBadge(text: '1080P HD', borderColor: AppColors.accentCyan, textColor: AppColors.accentCyan),
          ],
        ),
        const SizedBox(height: 14),
        Text(title, style: AppTypography.displayLarge()),
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

        const SizedBox(height: 16),
        SizedBox(
          width: 240,
          child: BrutalistButton(
            label: 'ASSISTIR AGORA.',
            icon: Icons.play_arrow_rounded,
            onPressed: _playMovie,
          ),
        ),
      ],
    );
  }
}
