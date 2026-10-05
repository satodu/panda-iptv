import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/hanko_badge.dart';
import '../../core/widgets/tech_crosses.dart';
import '../auth/presentation/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                    // Hero Banner Jellyfin-Like (Destaque / Continuar Assistindo)
                    _buildHeroBanner(context),
                    const SizedBox(height: 24),

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
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accentPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
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
                const HankoBadge(text: 'JELLYFIN HUB // HUB CENTRAL', isLive: true),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Módulo Ao Vivo em carregamento...')),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Módulo Filmes em carregamento...')),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Módulo Séries em carregamento...')),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lista de Favoritos vazia.')),
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
            return BentoCard(
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
            );
          },
        );
      },
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
