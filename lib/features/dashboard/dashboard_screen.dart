import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/storage/watch_history_item.dart';
import '../../core/storage/watch_history_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/bento_card_background.dart';
import '../../core/widgets/brutalist_entrance.dart';
import '../../core/widgets/hanko_badge.dart';
import '../../core/widgets/tech_crosses.dart';
import '../auth/presentation/auth_provider.dart';
import '../favorites/presentation/favorites_screen.dart';
import '../player/presentation/video_player_screen.dart';
import '../series/presentation/series_screen.dart';
import '../vod/presentation/vod_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WatchHistoryService.loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentAccount?.userInfo;
    final server = auth.currentAccount?.serverInfo;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Barra Superior de Status (Brutalismo Minimalista Responsivo)
            _buildTopBar(context, auth, user, server, isNarrow),

            // Conteúdo Rolável
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 16 : 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Banner (Destaque / Hub Principal)
                    _buildHeroBanner(context, isNarrow),
                    const SizedBox(height: 24),

                    // Continuar Assistindo (se houver histórico)
                    ValueListenableBuilder<List<WatchHistoryItem>>(
                      valueListenable: WatchHistoryService.historyNotifier,
                      builder: (context, historyItems, _) {
                        return _buildContinueWatchingSection(context, historyItems);
                      },
                    ),

                    // Título de Seção
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'BIBLIOTECA & NAVEGAÇÃO.',
                          style: AppTypography.sectionTitle(fontSize: isNarrow ? 15 : 18),
                        ),
                        TechCrosses(count: isNarrow ? 3 : 4, spacing: 8),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Grade Bento Responsiva
                    _buildBentoGrid(context, isLandscape),
                    const SizedBox(height: 28),

                    // Rodapé técnico
                    Center(
                      child: Text(
                        'PANDA IPTV // ARCH LINUX & ANDROID CORE // MPV ACCELERATED',
                        textAlign: TextAlign.center,
                        style: AppTypography.mono(fontSize: 10, color: AppColors.textDisabled),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AuthProvider auth, dynamic user, dynamic server, bool isNarrow) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24, vertical: isNarrow ? 10 : 14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          bottom: BorderSide(color: AppColors.borderHairline, width: 1),
        ),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: isNarrow ? 22 : 24,
                  height: isNarrow ? 22 : 24,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PANDA IPTV.',
                style: AppTypography.titleMedium(
                  color: AppColors.textPrimary,
                  fontSize: isNarrow ? 13 : 14,
                ),
              ),
            ],
          ),
          if (!isNarrow) ...[
            const SizedBox(width: 16),
            const TechCrosses(count: 3, opacity: 0.2),
          ],
          const Spacer(),

          // Badge de Usuário (limpo e direto, sem contagem de conexões)
          if (user != null) ...[
            HankoBadge(
              text: user.username.toUpperCase(),
              borderColor: AppColors.accentPrimary,
              textColor: AppColors.textPrimary,
            ),
            const SizedBox(width: 8),
          ],

          // Botão Desconectar
          IconButton(
            tooltip: 'Desconectar',
            icon: const Icon(Icons.power_settings_new_rounded, size: 20, color: AppColors.textMuted),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isNarrow) {
    return BentoCard(
      padding: EdgeInsets.all(isNarrow ? 16 : 24),
      backgroundColor: AppColors.surfaceCard,
      background: const BentoCardBackground(
        accentColor: AppColors.accentPrimary,
        watermarkKanji: '熊猫',
        technicalTag: 'PANDA.IPTV // CORE.HUB [ 1080P ]',
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HankoBadge(text: 'CENTRAL DE MÍDIA // HUB', isLive: true),
                const SizedBox(height: 10),
                Text(
                  'BEM-VINDO AO PANDA.',
                  style: AppTypography.displayLarge(
                    color: AppColors.textPrimary,
                  ).copyWith(fontSize: isNarrow ? 20 : 28),
                ),
                const SizedBox(height: 6),
                Text(
                  'Acesse transmissões ao vivo com baixa latência e biblioteca sob demanda.',
                  style: AppTypography.body(
                    color: AppColors.textMuted,
                    fontSize: isNarrow ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: isNarrow ? 44 : 58,
                  height: isNarrow ? 44 : 58,
                  fit: BoxFit.cover,
                ),
              ),
              if (!isNarrow) ...[
                const SizedBox(height: 8),
                Text(
                  '放送\n中心',
                  textAlign: TextAlign.center,
                  style: AppTypography.orientalAccent(fontSize: 18),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context, bool isLandscape) {
    final cards = [
      _BentoItem(
        title: 'AO VIVO.',
        subtitle: 'Canais de televisão em tempo real e guia EPG.',
        badge: 'LIVE STREAMS',
        icon: Icons.live_tv_rounded,
        color: AppColors.accentPrimary,
        kanji: '生放送',
        watermarkKanji: '生',
        technicalTag: 'SYS // 01.LIVE [ 24H ]',
        onTap: () {
          AppToast.info(context, 'MÓDULO AO VIVO EM DESENVOLVIMENTO.');
        },
      ),
      _BentoItem(
        title: 'FILMES.',
        subtitle: 'Catálogo de filmes em alta definição (VOD).',
        badge: 'CINEMA HD',
        icon: Icons.movie_rounded,
        color: AppColors.accentCyan,
        kanji: '映画',
        watermarkKanji: '映',
        technicalTag: 'VOD // 4K.CINEMA [ 2160P ]',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VodScreen()),
          );
        },
      ),
      _BentoItem(
        title: 'SÉRIES.',
        subtitle: 'Temporadas completas organizadas por episódios.',
        badge: 'ON DEMAND',
        icon: Icons.video_collection_rounded,
        color: AppColors.textPrimary,
        kanji: '連載',
        watermarkKanji: '連',
        technicalTag: 'SERIES // EP.RUN [ ON-DEMAND ]',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SeriesScreen()),
          );
        },
      ),
      _BentoItem(
        title: 'FAVORITOS.',
        subtitle: 'Acesso rápido aos seus canais e conteúdos salvos.',
        badge: 'FAV. LIST',
        icon: Icons.star_rounded,
        color: AppColors.statusLive,
        kanji: '保存',
        watermarkKanji: '星',
        technicalTag: 'FAV // PIN.SAV [ QUICK ]',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
          );
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 1 ? 2.1 : 1.25,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final item = cards[index];
            return BrutalistEntrance(
              index: index,
              child: BentoCard(
                onTap: item.onTap,
                background: BentoCardBackground(
                  accentColor: item.color,
                  watermarkKanji: item.watermarkKanji,
                  technicalTag: item.technicalTag,
                  watermarkIcon: item.icon,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: item.color.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Icon(item.icon, size: 22, color: item.color),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HankoBadge(text: item.badge, borderColor: item.color),
                            const SizedBox(width: 8),
                            Text(item.kanji, style: AppTypography.orientalAccent(fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: AppTypography.sectionTitle(fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
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

  Widget _buildContinueWatchingSection(BuildContext context, List<WatchHistoryItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'CONTINUAR ASSISTINDO.',
                  style: AppTypography.sectionTitle(),
                ),
                const SizedBox(width: 10),
                HankoBadge(
                  text: '[ ${items.length} ]',
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
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return BrutalistEntrance(
                index: index,
                child: _buildContinueWatchingCard(context, item),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContinueWatchingCard(BuildContext context, WatchHistoryItem item) {
    final hasCover = item.cover != null && item.cover!.trim().isNotEmpty;
    final isSeries = item.type == 'series';

    return BentoCard(
      padding: EdgeInsets.zero,
      borderRadius: 12,
      onTap: () {
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
        ).then((_) => WatchHistoryService.loadHistory());
      },
      child: SizedBox(
        width: 280,
        height: 180,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Capa de fundo
              if (hasCover)
                CachedNetworkImage(
                  imageUrl: item.cover!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _buildFallbackCover(isSeries),
                )
              else
                _buildFallbackCover(isSeries),

              // Gradiente brutalista para contraste e legibilidade
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.92),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),

              // Conteúdo em camadas
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Linha Superior: Tags e Botão Remover
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          children: [
                            HankoBadge(
                              text: isSeries ? 'SÉRIE' : 'FILME',
                              borderColor: isSeries ? AppColors.accentCyan : AppColors.accentPrimary,
                              textColor: isSeries ? AppColors.accentCyan : AppColors.accentPrimary,
                            ),
                            if (item.remainingMinutes > 0)
                              HankoBadge(
                                text: '${item.remainingMinutes}M RESTANTES',
                                borderColor: AppColors.borderHairline,
                                textColor: AppColors.textPrimary,
                              ),
                          ],
                        ),
                        InkWell(
                          onTap: () => WatchHistoryService.removeItem(item.id),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard.withValues(alpha: 0.8),
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
                      ],
                    ),

                    // Linha Inferior: Play Icon + Informações + Barra de Progresso
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.accentPrimary.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.titleMedium(fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.subtitle!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.mono(fontSize: 10, color: AppColors.accentCyan),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Barra de Progresso em Azul Elétrico
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: item.progress,
                            minHeight: 3.5,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCover(bool isSeries) {
    return Container(
      color: AppColors.surfaceCard,
      child: Center(
        child: Icon(
          isSeries ? Icons.video_collection_outlined : Icons.movie_filter_outlined,
          size: 40,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }
}

class _BentoItem {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final String kanji;
  final String? watermarkKanji;
  final String? technicalTag;
  final VoidCallback onTap;

  _BentoItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    required this.kanji,
    this.watermarkKanji,
    this.technicalTag,
    required this.onTap,
  });
}
