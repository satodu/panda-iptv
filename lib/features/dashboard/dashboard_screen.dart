import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/storage/watch_history_item.dart';
import '../../core/storage/watch_history_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/bento_card.dart';
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

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Barra Superior de Status (Brutalismo Minimalista)
            _buildTopBar(context, auth, user, server),

            // Conteúdo Rolável
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Banner (Destaque / Hub Principal)
                    _buildHeroBanner(context),
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
                          style: AppTypography.sectionTitle(),
                        ),
                        const TechCrosses(count: 4, spacing: 8),
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

  Widget _buildTopBar(BuildContext context, AuthProvider auth, dynamic user, dynamic server) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          bottom: BorderSide(color: AppColors.borderHairline, width: 1),
        ),
      ),
      child: Row(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'PANDA IPTV.',
                style: AppTypography.titleMedium(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(width: 16),
          const TechCrosses(count: 3, opacity: 0.2),
          const Spacer(),

          // Badge de Usuário e Conexão
          if (user != null) ...[
            HankoBadge(text: user.username),
            const SizedBox(width: 10),
            HankoBadge(
              text: 'CONEXÃO: ${user.activeCons}/${user.maxConnections}',
              borderColor: AppColors.accentCyan,
              textColor: AppColors.accentCyan,
            ),
            const SizedBox(width: 12),
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

  Widget _buildHeroBanner(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: AppColors.surfaceCard,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HankoBadge(text: 'CENTRAL DE MÍDIA // HUB', isLive: true),
                const SizedBox(height: 12),
                Text(
                  'BEM-VINDO AO PANDA.',
                  style: AppTypography.displayLarge(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Acesse transmissões ao vivo com baixa latência e biblioteca sob demanda.',
                  style: AppTypography.body(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/logo.png',
              width: 58,
              height: 58,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '放送\n中心',
            textAlign: TextAlign.center,
            style: AppTypography.orientalAccent(fontSize: 22),
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
        icon: Icons.tv_rounded,
        color: AppColors.accentPrimary,
        kanji: '生放送',
        onTap: () {
          AppToast.info(context, 'MÓDULO AO VIVO EM DESENVOLVIMENTO.');
        },
      ),
      _BentoItem(
        title: 'FILMES.',
        subtitle: 'Catálogo de filmes em alta definição (VOD).',
        badge: 'CINEMA HD',
        icon: Icons.movie_filter_outlined,
        color: AppColors.accentCyan,
        kanji: '映画',
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
        icon: Icons.video_collection_outlined,
        color: AppColors.textPrimary,
        kanji: '連載',
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
        icon: Icons.star_border_rounded,
        color: AppColors.statusLive,
        kanji: '保存',
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
            childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.25,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final item = cards[index];
            return BrutalistEntrance(
              index: index,
              child: BentoCard(
                onTap: item.onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HankoBadge(text: item.badge, borderColor: item.color),
                        Text(item.kanji, style: AppTypography.orientalAccent(fontSize: 14)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon, size: 28, color: item.color),
                        const SizedBox(height: 8),
                        Text(item.title, style: AppTypography.sectionTitle()),
                        const SizedBox(height: 4),
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
  final VoidCallback onTap;

  _BentoItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    required this.kanji,
    required this.onTap,
  });
}
