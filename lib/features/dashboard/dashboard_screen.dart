import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/storage/favorite_item.dart';
import '../../core/storage/favorites_service.dart';
import '../../core/storage/recent_channel_item.dart';
import '../../core/storage/recent_channels_service.dart';
import '../../core/storage/watch_history_item.dart';
import '../../core/storage/watch_history_service.dart';
import '../../core/storage/full_watch_history_service.dart';
import '../../core/storage/watched_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/bento_card_background.dart';
import '../../core/widgets/brutalist_button.dart';
import '../../core/widgets/brutalist_entrance.dart';
import '../../core/widgets/hanko_badge.dart';
import '../../core/widgets/tech_crosses.dart';
import '../auth/presentation/auth_provider.dart';
import '../favorites/presentation/favorites_screen.dart';
import '../history/presentation/watch_history_screen.dart';
import '../live/presentation/live_screen.dart';
import '../player/presentation/video_player_screen.dart';
import '../series/presentation/series_screen.dart';
import '../../core/services/update_service.dart';
import '../settings/presentation/settings_screen.dart';
import '../vod/presentation/vod_screen.dart';
import '../vod/presentation/vod_provider.dart';
import '../series/presentation/series_provider.dart';
import '../live/presentation/live_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UpdateInfo? _updateInfo;
  bool _isDownloadingUpdate = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    WatchHistoryService.loadHistory();
    FullWatchHistoryService.loadHistory();
    WatchedService.loadWatched();
    RecentChannelsService.loadChannels();
    FavoritesService.loadFavorites();
    _checkForUpdates();
  }

  void _checkForUpdates() async {
    final info = await UpdateService.checkForUpdate();
    if (mounted && info != null && info.hasUpdate) {
      setState(() => _updateInfo = info);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.accentPrimary, width: 1.2),
          ),
          content: Row(
            children: [
              const Icon(Icons.system_update_rounded, color: AppColors.accentPrimary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'NOVA VERSÃO DISPONÍVEL // v${info.latestVersion}',
                  style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'ATUALIZAR.',
            textColor: AppColors.accentPrimary,
            onPressed: _startUpdate,
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  void _startUpdate() {
    if (_updateInfo == null || _isDownloadingUpdate) return;

    setState(() {
      _isDownloadingUpdate = true;
      _downloadProgress = 0.0;
    });

    UpdateService.downloadAndInstall(
      updateInfo: _updateInfo!,
      onProgress: (progress) {
        if (mounted) setState(() => _downloadProgress = progress);
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isDownloadingUpdate = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surfaceCard,
              content: Text(
                'ERRO AO ATUALIZAR: $error',
                style: AppTypography.mono(color: AppColors.statusError),
              ),
            ),
          );
        }
      },
      onReadyToInstall: () {
        if (mounted) setState(() => _isDownloadingUpdate = false);
      },
    );
  }

  Future<bool> _showExitConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderHairline),
          ),
          title: Row(
            children: [
              const Icon(Icons.exit_to_app_rounded, color: AppColors.accentPrimary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('dashboard.exit_title'),
                  style: AppTypography.sectionTitle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: Text(
            context.tr('dashboard.exit_message'),
            style: AppTypography.mono(fontSize: 13, color: AppColors.textPrimary),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          actions: [
            BrutalistButton(
              label: context.tr('dashboard.exit_cancel'),
              isSecondary: true,
              autofocus: true,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            const SizedBox(width: 8),
            BrutalistButton(
              label: context.tr('dashboard.exit_confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await SystemNavigator.pop();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentAccount?.userInfo;
    final server = auth.currentAccount?.serverInfo;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmationDialog();
      },
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.escape ||
               event.logicalKey == LogicalKeyboardKey.goBack)) {
            _showExitConfirmationDialog();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
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

                    // Continuar Assistindo (se houver histórico e não estiver concluído/visto)
                    ValueListenableBuilder<List<WatchHistoryItem>>(
                      valueListenable: WatchHistoryService.historyNotifier,
                      builder: (context, historyItems, _) {
                        return ValueListenableBuilder<Set<String>>(
                          valueListenable: WatchedService.watchedNotifier,
                          builder: (context, watchedSet, _) {
                            final continueItems = historyItems.where((item) {
                              final isWatched = watchedSet.contains(item.id);
                              final isFinished = item.durationMs > 0 &&
                                  (item.positionMs / item.durationMs) >= 0.93;
                              return !isWatched && !isFinished;
                            }).toList();
                            return _buildContinueWatchingSection(context, continueItems);
                          },
                        );
                      },
                    ),

                    // Últimos Canais Assistidos (se houver histórico)
                    ValueListenableBuilder<List<RecentChannelItem>>(
                      valueListenable: RecentChannelsService.recentChannelsNotifier,
                      builder: (context, recentChannels, _) {
                        return _buildRecentChannelsSection(context, recentChannels);
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

          // Botão Histórico (Filmes e Séries)
          _FocusableTopBarIconButton(
            tooltip: context.tr('history.tooltip'),
            icon: Icons.history_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WatchHistoryScreen()),
              );
            },
          ),
          const SizedBox(width: 6),

          // Botão Configurações
          _FocusableTopBarIconButton(
            tooltip: 'Configurações',
            icon: Icons.settings_outlined,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 6),

          // Botão Desconectar
          _FocusableTopBarIconButton(
            tooltip: context.tr('dashboard.logout_tooltip'),
            icon: Icons.power_settings_new_rounded,
            color: AppColors.textMuted,
            onPressed: () {
              context.read<VodProvider>().clear();
              context.read<SeriesProvider>().clear();
              context.read<LiveProvider>().clear();
              auth.logout();
            },
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
                if (_updateInfo != null) ...[
                  const SizedBox(height: 14),
                  if (_isDownloadingUpdate) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'BAIXANDO ATUALIZAÇÃO v${_updateInfo!.latestVersion}...',
                              style: AppTypography.mono(
                                fontSize: 11,
                                color: AppColors.accentPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${(_downloadProgress * 100).toInt()}%',
                              style: AppTypography.mono(fontSize: 11, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _downloadProgress > 0 ? _downloadProgress : null,
                            minHeight: 4,
                            backgroundColor: AppColors.surfaceHover,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _startUpdate,
                          icon: const Icon(Icons.system_update_rounded, size: 16),
                          label: Text(
                            'ATUALIZAR PARA v${_updateInfo!.latestVersion}.',
                            style: AppTypography.mono(
                              fontSize: isNarrow ? 10 : 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const HankoBadge(
                          text: '[ NOVA VERSÃO DISPONÍVEL ]',
                          borderColor: AppColors.accentCyan,
                          textColor: AppColors.accentCyan,
                        ),
                      ],
                    ),
                  ],
                ],
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
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LiveScreen()),
          );
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
    final coverClean = item.cover?.trim().toLowerCase();
    final hasCover = coverClean != null &&
        coverClean.isNotEmpty &&
        coverClean != 'null' &&
        coverClean != 'undefined' &&
        (coverClean.startsWith('http://') || coverClean.startsWith('https://'));
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
        width: 320,
        height: 180,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Fundo ambiente escurecido com a capa
              if (hasCover) ...[
                CachedNetworkImage(
                  imageUrl: item.cover!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _buildFallbackCover(isSeries),
                ),
                Container(
                  color: Colors.black.withValues(alpha: 0.88),
                ),
              ] else
                _buildFallbackCover(isSeries),

              // Conteúdo em layout dividido: Poster nítido à esquerda + detalhes à direita
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Capa vertical em destaque (Oriental Brutalism)
                    Container(
                      width: 95,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accentPrimary.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (hasCover)
                              CachedNetworkImage(
                                imageUrl: item.cover!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _buildFallbackCover(isSeries),
                              )
                            else
                              _buildFallbackCover(isSeries),
                            // Indicador discreto de play sobre o poster
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppColors.accentPrimary.withValues(alpha: 0.95),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Painel com Informações e Progresso
                    Expanded(
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
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  HankoBadge(
                                    text: isSeries ? 'SÉRIE' : 'FILME',
                                    borderColor: isSeries ? AppColors.accentCyan : AppColors.accentPrimary,
                                    textColor: isSeries ? AppColors.accentCyan : AppColors.accentPrimary,
                                  ),
                                  if (item.remainingMinutes > 0)
                                    HankoBadge(
                                      text: '${item.remainingMinutes}M',
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

                          // Título e Subtítulo
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title.toUpperCase().endsWith('.')
                                    ? item.title.toUpperCase()
                                    : '${item.title.toUpperCase()}.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMedium(fontSize: 12, color: AppColors.textPrimary),
                              ),
                              if (item.subtitle != null && item.subtitle!.trim().isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  item.subtitle!.trim().toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.mono(fontSize: 10, color: AppColors.accentCyan),
                                ),
                              ],
                            ],
                          ),

                          // Barra de Progresso em Azul Elétrico
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '[ ${(item.progress * 100).toInt()}% ]',
                                    style: AppTypography.mono(fontSize: 9, color: AppColors.textMuted),
                                  ),
                                  const TechCrosses(count: 2, spacing: 3),
                                ],
                              ),
                              const SizedBox(height: 4),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentChannelsSection(BuildContext context, List<RecentChannelItem> items) {
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
                  context.tr('dashboard.recent_channels_title'),
                  style: AppTypography.sectionTitle(),
                ),
                const SizedBox(width: 10),
                HankoBadge(
                  text: '[ ${items.length} ]',
                  borderColor: AppColors.statusLive,
                  textColor: AppColors.statusLive,
                ),
              ],
            ),
            const TechCrosses(count: 3, spacing: 6),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return BrutalistEntrance(
                index: index,
                child: _buildRecentChannelCard(context, item),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRecentChannelCard(BuildContext context, RecentChannelItem item) {
    final hasLogo = item.streamIcon != null && item.streamIcon!.trim().isNotEmpty;
    final favId = 'live_${item.streamId}';

    return BentoCard(
      padding: EdgeInsets.zero,
      borderRadius: 12,
      onTap: () {
        // Atualiza a posição nos canais recentes
        RecentChannelsService.recordChannelWatched(
          streamId: item.streamId,
          name: item.name,
          streamIcon: item.streamIcon,
          categoryName: item.categoryName,
          channelNumber: item.channelNumber,
          streamUrl: item.streamUrl,
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              title: item.name,
              subtitle: item.categoryName ?? 'CANAL AO VIVO',
              streamUrl: item.streamUrl,
              mediaId: item.streamId.toString(),
              cover: item.streamIcon,
              mediaType: 'live',
            ),
          ),
        );
      },
      child: SizedBox(
        width: 260,
        height: 160,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Fundo estilizado com gradiente
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surfaceHover,
                      AppColors.surfaceCard,
                      AppColors.canvas,
                    ],
                  ),
                ),
              ),

              // Logo central do canal
              Center(
                child: Opacity(
                  opacity: 0.85,
                  child: hasLogo
                      ? CachedNetworkImage(
                          imageUrl: item.streamIcon!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.live_tv_rounded,
                            size: 40,
                            color: AppColors.textDisabled,
                          ),
                        )
                      : const Icon(
                          Icons.live_tv_rounded,
                          size: 40,
                          color: AppColors.textDisabled,
                        ),
                ),
              ),

              // Gradiente de legibilidade para o rodapé e topo
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.90),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // Conteúdo sobreposto
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Linha Superior: Tags à esquerda, Botões de Favoritar e Fechar à direita
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            HankoBadge(
                              text: item.channelNumber ?? '#LIVE',
                              borderColor: AppColors.accentCyan,
                              textColor: AppColors.accentCyan,
                            ),
                            const SizedBox(width: 6),
                            const HankoBadge(
                              text: '● AO VIVO',
                              borderColor: AppColors.statusLive,
                              textColor: AppColors.statusLive,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botão Favoritar
                            ValueListenableBuilder<List<FavoriteItem>>(
                              valueListenable: FavoritesService.favoritesNotifier,
                              builder: (context, _, __) {
                                final isFav = FavoritesService.isFavoriteSync(favId);
                                return InkWell(
                                  onTap: () async {
                                    final favItem = FavoriteItem(
                                      id: favId,
                                      title: item.name,
                                      type: 'live',
                                      cover: item.streamIcon,
                                      genre: item.categoryName,
                                      streamUrl: item.streamUrl,
                                      channelNumber: item.channelNumber,
                                      addedAt: DateTime.now(),
                                    );
                                    await FavoritesService.toggleFavorite(favItem);
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceCard.withValues(alpha: 0.85),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isFav ? AppColors.statusLive : AppColors.borderHairline,
                                      ),
                                    ),
                                    child: Icon(
                                      isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                      size: 14,
                                      color: isFav ? AppColors.statusLive : AppColors.textMuted,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            // Botão Fechar / Remover dos recentes
                            InkWell(
                              onTap: () => RecentChannelsService.removeChannel(item.streamId),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(4),
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
                          ],
                        ),
                      ],
                    ),

                    // Linha Inferior: Play Icon + Nome do Canal + Categoria
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.accentPrimary,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.name.toUpperCase().endsWith('.')
                                    ? item.name.toUpperCase()
                                    : '${item.name.toUpperCase()}.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.mono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (item.categoryName != null && item.categoryName!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.categoryName!.toUpperCase(),
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

class _FocusableTopBarIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const _FocusableTopBarIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  State<_FocusableTopBarIconButton> createState() => _FocusableTopBarIconButtonState();
}

class _FocusableTopBarIconButtonState extends State<_FocusableTopBarIconButton> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;
    final scale = _isFocused ? 1.15 : (_isHovered ? 1.05 : 1.0);

    return FocusableActionDetector(
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onPressed(),
        ),
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.diagonal3Values(scale, scale, 1.0),
            transformAlignment: Alignment.center,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: active ? AppColors.surfaceHover : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isFocused ? AppColors.accentCyan : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.accentCyan.withValues(alpha: 0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: _isFocused
                  ? AppColors.accentCyan
                  : (widget.color ?? (active ? AppColors.accentPrimary : AppColors.textPrimary)),
            ),
          ),
        ),
      ),
    );
  }
}

