import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/storage/favorite_item.dart';
import '../../../core/storage/favorites_service.dart';
import '../../../core/storage/recent_channels_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/brutalist_entrance.dart';
import '../../../core/widgets/hanko_loader.dart';
import '../../../core/widgets/tech_crosses.dart';
import '../../../core/widgets/quick_filter_bar.dart';
import '../../../core/widgets/focusable_category_chip.dart';
import '../../../core/widgets/content_filter_modal.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../player/models/playlist_item.dart';
import '../../player/presentation/video_player_screen.dart';
import '../models/live_category.dart';
import '../models/live_stream_item.dart';
import 'live_provider.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    FavoritesService.loadFavorites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final account = context.read<AuthProvider>().currentAccount;
      final live = context.read<LiveProvider>();
      // Ao entrar na tela, limpa qualquer busca residual para exibir catálogo completo
      live.setSearchQuery('');
      _searchController.clear();
      if (account != null) {
        live.init(account);
      }
    });
  }

  void _performSearch(String val, LiveProvider live) {
    _debounceTimer?.cancel();
    live.setSearchQuery(val.trim());
    setState(() {});
  }

  void _onSearchChanged(String val, LiveProvider live) {
    // Se o usuário apagou todo o texto no campo e havia uma busca ativa, restaura o catálogo
    if (val.trim().isEmpty && live.searchQuery.isNotEmpty) {
      live.setSearchQuery('');
    }
    setState(() {});
  }

  void _clearSearch(LiveProvider live) {
    _debounceTimer?.cancel();
    _searchController.clear();
    live.setSearchQuery('');
    setState(() {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = context.watch<LiveProvider>();
    final account = context.watch<AuthProvider>().currentAccount;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _clearSearch(live);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar Responsiva
            _buildTopBar(context, live, account, isNarrow),

            // Barra de Categorias
            _buildCategorySelector(context, live, account),

            // Barra de Filtros & Ordenação Rápida
            QuickFilterBar.live(
              context: context,
              filterState: live.filterState,
              onFilterChanged: (newState) => live.setFilterState(newState),
            ),

            // Sub-barra com contagem e status
            if (!live.isLoadingChannels && live.error == null && live.filteredChannels.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.canvas,
                  border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
                ),
                child: Row(
                  children: [
                    Text(
                      _getSelectedCategoryName(context, live),
                      style: AppTypography.mono(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '[ ${live.filteredChannels.length} ${context.tr('live.channels_count')} ]',
                      style: AppTypography.mono(fontSize: 10, color: AppColors.accentCyan),
                    ),
                    const Spacer(),
                    const TechCrosses(count: 3, opacity: 0.15),
                  ],
                ),
              ),

            // Channels Grid
            Expanded(
              child: live.isLoadingChannels
                  ? const Center(child: HankoLoader(label: 'CARREGANDO CANAIS.'))
                  : live.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.statusError, size: 36),
                              const SizedBox(height: 12),
                              Text(
                                context.tr('common.error_loading'),
                                style: AppTypography.titleMedium(color: AppColors.statusError),
                              ),
                              const SizedBox(height: 6),
                              Text(live.error!, style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
                                onPressed: () {
                                  if (account != null) live.init(account);
                                },
                                child: Text(context.tr('common.retry'), style: AppTypography.button()),
                              ),
                            ],
                          ),
                        )
                      : live.filteredChannels.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    context.tr('live.empty'),
                                    style: AppTypography.mono(fontSize: 13, color: AppColors.textMuted),
                                  ),
                                  if (live.searchQuery.isNotEmpty || live.filterState.hasActiveFilters) ...[
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.surfaceHover,
                                        side: const BorderSide(color: AppColors.accentPrimary),
                                      ),
                                      onPressed: () {
                                        _clearSearch(live);
                                        live.resetFilterState();
                                      },
                                      icon: const Icon(Icons.clear_all_rounded, size: 16, color: AppColors.accentPrimary),
                                      label: Text(
                                        context.tr('common.clear_search_filters'),
                                        style: AppTypography.button(color: AppColors.accentPrimary),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : _buildChannelsGrid(context, live, account),
            ),
          ],
        ),
      ),
    ),
  );
}

  String _getSelectedCategoryName(BuildContext context, LiveProvider live) {
    if (live.selectedCategoryId == null || live.selectedCategoryId == 'all') {
      return context.tr('live.all_channels');
    }
    final cat = live.categories.cast<LiveCategory?>().firstWhere(
          (c) => c?.categoryId == live.selectedCategoryId,
          orElse: () => null,
        );
    return cat != null ? cat.categoryName.toUpperCase() : 'CATEGORIA';
  }

  Widget _buildTopBar(BuildContext context, LiveProvider live, dynamic account, bool isNarrow) {
    final hasSearch = _searchController.text.isNotEmpty || live.searchQuery.isNotEmpty;

    if (isNarrow && _isSearchExpanded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () {
                setState(() => _isSearchExpanded = false);
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (val) => _performSearch(val, live),
                  onChanged: (val) => _onSearchChanged(val, live),
                  style: AppTypography.body(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: context.tr('live.search_hint'),
                    hintStyle: AppTypography.mono(fontSize: 11, color: AppColors.textDisabled),
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.search_rounded, size: 18, color: AppColors.accentPrimary),
                      tooltip: context.tr('common.search'),
                      onPressed: () => _performSearch(_searchController.text, live),
                    ),
                    suffixIcon: hasSearch
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                            onPressed: () => _clearSearch(live),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    filled: true,
                    fillColor: AppColors.surfaceHover,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderHairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderHairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.accentPrimary),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () {
              _clearSearch(live);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 4),
          Text(
            context.tr('live.title'),
            style: AppTypography.titleMedium(fontSize: isNarrow ? 14 : 16),
          ),
          if (!isNarrow) ...[
            const SizedBox(width: 16),
            const TechCrosses(count: 3, opacity: 0.2),
          ],
          const Spacer(),

          // Botão Filtros
          Stack(
            children: [
              IconButton(
                tooltip: context.tr('filter.title'),
                icon: Icon(
                  Icons.tune_rounded,
                  color: live.filterState.hasActiveFilters ? AppColors.accentPrimary : AppColors.textPrimary,
                ),
                onPressed: () {
                  ContentFilterModal.showLiveFilter(
                    context: context,
                    currentState: live.filterState,
                    onApply: (newState) => live.setFilterState(newState),
                  );
                },
              ),
              if (live.filterState.hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accentPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),

          // Botão Atualizar Catálogo
          IconButton(
            tooltip: context.tr('common.refresh'),
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: () {
              if (account != null) {
                live.refresh(account);
              }
            },
          ),
          const SizedBox(width: 4),

          if (isNarrow) ...[
            if (hasSearch) ...[
              GestureDetector(
                onTap: () => setState(() => _isSearchExpanded = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.accentPrimary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BUSCA: "${live.searchQuery.isNotEmpty ? live.searchQuery : _searchController.text}"',
                        style: AppTypography.mono(fontSize: 10, color: AppColors.accentPrimary, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _clearSearch(live),
                        child: const Icon(Icons.close_rounded, size: 14, color: AppColors.accentPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              icon: Icon(
                Icons.search_rounded,
                color: hasSearch ? AppColors.accentPrimary : AppColors.textPrimary,
              ),
              onPressed: () {
                setState(() => _isSearchExpanded = true);
              },
            ),
          ] else ...[
            SizedBox(
              width: 240,
              height: 38,
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (val) => _performSearch(val, live),
                onChanged: (val) => _onSearchChanged(val, live),
                style: AppTypography.body(fontSize: 13),
                decoration: InputDecoration(
                  hintText: context.tr('live.search_desktop_hint'),
                  hintStyle: AppTypography.mono(fontSize: 11, color: AppColors.textDisabled),
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                    tooltip: context.tr('common.search'),
                    onPressed: () => _performSearch(_searchController.text, live),
                  ),
                  suffixIcon: hasSearch
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                          onPressed: () => _clearSearch(live),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  filled: true,
                  fillColor: AppColors.surfaceHover,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderHairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderHairline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.accentPrimary),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context, LiveProvider live, dynamic account) {
    if (live.isLoadingCategories) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: HankoLoader.compact(label: 'CATEGORIAS.'),
        ),
      );
    }

    if (live.categories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: live.categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isSelected = isAll
              ? (live.selectedCategoryId == null || live.selectedCategoryId == 'all')
              : live.selectedCategoryId == live.categories[index - 1].categoryId;

          final label = isAll ? context.tr('common.all') : live.categories[index - 1].categoryName.toUpperCase();

          return FocusableCategoryChip(
            label: label,
            isSelected: isSelected,
            onTap: () {
              if (account != null) {
                live.selectCategory(account, isAll ? 'all' : live.categories[index - 1].categoryId);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildChannelsGrid(BuildContext context, LiveProvider live, dynamic account) {
    final channels = live.filteredChannels;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 6;
        } else if (constraints.maxWidth > 900) {
          crossAxisCount = 5;
        } else if (constraints.maxWidth > 650) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 420) {
          crossAxisCount = 3;
        }

        final isNarrow = constraints.maxWidth < 600;

        return GridView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.all(isNarrow ? 12 : 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isNarrow ? 10 : 14,
            mainAxisSpacing: isNarrow ? 10 : 14,
            childAspectRatio: 1.15,
          ),
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            return BrutalistEntrance(
              index: index,
              child: _buildChannelCard(context, live, account, channel, index, channels),
            );
          },
        );
      },
    );
  }

  Widget _buildChannelCard(
    BuildContext context,
    LiveProvider live,
    dynamic account,
    LiveStreamItem channel,
    int index,
    List<LiveStreamItem> allChannels,
  ) {
    final streamUrl = account != null ? live.buildStreamUrl(account, channel.streamId) : '';

    return BentoCard(
      padding: EdgeInsets.zero,
      onTap: () {
        if (account == null || streamUrl.isEmpty) return;

        // Registra canal como recentemente assistido
        RecentChannelsService.recordChannelWatched(
          streamId: channel.streamId,
          name: channel.name,
          streamIcon: channel.streamIcon,
          categoryName: channel.categoryName,
          channelNumber: channel.formattedNumber,
          streamUrl: streamUrl,
        );

        // Monta a playlist com todos os canais filtrados para permitir zapping imediato
        final playlist = allChannels.map((c) {
          return PlaylistItem(
            id: c.streamId.toString(),
            title: c.name,
            subtitle: c.categoryName ?? context.tr('live.channel_number'),
            streamUrl: live.buildStreamUrl(account, c.streamId),
            cover: c.streamIcon,
            mediaType: 'live',
          );
        }).toList();

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              title: channel.name,
              subtitle: channel.categoryName ?? '${context.tr('live.channel_number')} ${channel.formattedNumber}',
              streamUrl: streamUrl,
              mediaId: channel.streamId.toString(),
              cover: channel.streamIcon,
              mediaType: 'live',
              playlist: playlist,
              initialPlaylistIndex: index,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo do Canal com tags de sobreposição
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: AppColors.surfaceCard,
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: channel.streamIcon != null && channel.streamIcon!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: channel.streamIcon!,
                            fit: BoxFit.contain,
                            memCacheWidth: 200,
                            memCacheHeight: 200,
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.live_tv_rounded,
                              size: 32,
                              color: AppColors.textMuted,
                            ),
                          )
                        : const Icon(
                            Icons.live_tv_rounded,
                            size: 32,
                            color: AppColors.textMuted,
                          ),
                  ),
                ),

                // Tag de Número do Canal (topo esquerdo)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.borderHairline),
                    ),
                    child: Text(
                      channel.formattedNumber,
                      style: AppTypography.mono(fontSize: 9, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                // Tag de Resolução e Botão Favoritar (topo direito)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: channel.resolutionTag == '4K'
                                ? AppColors.statusLive
                                : AppColors.accentPrimary.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          channel.resolutionTag,
                          style: AppTypography.mono(
                            fontSize: 9,
                            color: channel.resolutionTag == '4K' ? AppColors.statusLive : AppColors.accentCyan,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ValueListenableBuilder<List<FavoriteItem>>(
                        valueListenable: FavoritesService.favoritesNotifier,
                        builder: (context, _, __) {
                          final favId = 'live_${channel.streamId}';
                          final isFav = FavoritesService.isFavoriteSync(favId);
                          return InkWell(
                            canRequestFocus: false,
                            onTap: () async {
                              final favItem = FavoriteItem(
                                id: favId,
                                title: channel.name,
                                type: 'live',
                                cover: channel.streamIcon,
                                genre: channel.categoryName,
                                streamUrl: streamUrl,
                                channelNumber: channel.formattedNumber,
                                addedAt: DateTime.now(),
                              );
                              final nowFav = await FavoritesService.toggleFavorite(favItem);
                              if (context.mounted) {
                                AppToast.info(
                                  context,
                                  nowFav ? context.tr('live.fav_added') : context.tr('live.fav_removed'),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isFav ? AppColors.statusLive : AppColors.borderHairline,
                                ),
                              ),
                              child: Icon(
                                isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 13,
                                color: isFav ? AppColors.statusLive : AppColors.textMuted,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Rodapé do card: Nome do Canal em CAIXA-ALTA com PONTO FINAL
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.surfaceHover,
              border: Border(top: BorderSide(color: AppColors.borderHairline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    channel.name.toUpperCase().endsWith('.')
                        ? channel.name.toUpperCase()
                        : '${channel.name.toUpperCase()}.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.statusLive,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
