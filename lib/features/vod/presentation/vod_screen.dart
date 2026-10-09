import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/brutalist_entrance.dart';
import '../../../core/widgets/hanko_loader.dart';
import '../../../core/widgets/tech_crosses.dart';
import '../../../core/widgets/focusable_category_chip.dart';
import '../../../core/widgets/quick_filter_bar.dart';
import '../../../core/widgets/content_filter_modal.dart';
import '../../auth/presentation/auth_provider.dart';
import '../models/vod_category.dart';
import '../models/vod_item.dart';
import 'vod_detail_screen.dart';
import 'vod_provider.dart';

class VodScreen extends StatefulWidget {
  const VodScreen({super.key});

  @override
  State<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends State<VodScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final account = context.read<AuthProvider>().currentAccount;
      final vod = context.read<VodProvider>();
      // Ao entrar na tela, limpa qualquer busca residual para exibir catálogo completo
      vod.setSearchQuery('');
      _searchController.clear();
      if (account != null) {
        vod.init(account);
      }
    });
  }

  void _performSearch(String val, VodProvider vod) {
    _debounceTimer?.cancel();
    vod.setSearchQuery(val.trim());
    setState(() {});
  }

  void _onSearchChanged(String val, VodProvider vod) {
    // Se o usuário apagou todo o texto no campo e havia uma busca ativa, restaura o catálogo
    if (val.trim().isEmpty && vod.searchQuery.isNotEmpty) {
      vod.setSearchQuery('');
    }
    setState(() {});
  }

  void _clearSearch(VodProvider vod) {
    _debounceTimer?.cancel();
    _searchController.clear();
    vod.setSearchQuery('');
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
    final vod = context.watch<VodProvider>();
    final account = context.watch<AuthProvider>().currentAccount;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _clearSearch(vod);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar Responsiva
            _buildTopBar(context, vod, account, isNarrow),

            // Categories Bar
            _buildCategorySelector(context, vod, account),

            // Barra de Filtros & Ordenação Rápida
            QuickFilterBar.content(
              context: context,
              filterState: vod.filterState,
              onFilterChanged: (newState) => vod.setFilterState(newState),
            ),

            // Sub-barra com contagem e status
            if (!vod.isLoadingMovies && vod.error == null && vod.filteredMovies.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.canvas,
                  border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
                ),
                child: Row(
                  children: [
                    Text(
                      _getSelectedCategoryName(vod),
                      style: AppTypography.mono(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '[ ${vod.filteredMovies.length} TÍTULOS ]',
                      style: AppTypography.mono(fontSize: 10, color: AppColors.accentCyan),
                    ),
                    const Spacer(),
                    const TechCrosses(count: 3, opacity: 0.15),
                  ],
                ),
              ),

            // Movies Grid
            Expanded(
              child: vod.isLoadingMovies
                  ? const Center(child: HankoLoader(label: 'CARREGANDO FILMES.'))
                  : vod.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.statusError, size: 36),
                              const SizedBox(height: 12),
                              Text('ERRO AO CARREGAR.', style: AppTypography.titleMedium(color: AppColors.statusError)),
                              const SizedBox(height: 6),
                              Text(vod.error!, style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
                                onPressed: () {
                                  if (account != null) vod.init(account);
                                },
                                child: Text('TENTAR NOVAMENTE.', style: AppTypography.button()),
                              ),
                            ],
                          ),
                        )
                      : vod.filteredMovies.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    context.tr('common.not_found'),
                                    style: AppTypography.mono(fontSize: 13, color: AppColors.textMuted),
                                  ),
                                  if (vod.searchQuery.isNotEmpty || vod.filterState.hasActiveFilters) ...[
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.surfaceHover,
                                        side: const BorderSide(color: AppColors.accentPrimary),
                                      ),
                                      onPressed: () {
                                        _clearSearch(vod);
                                        vod.resetFilterState();
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
                          : _buildMoviesGrid(context, vod.filteredMovies),
            ),
          ],
        ),
      ),
    ),
  );
}

  String _getSelectedCategoryName(VodProvider vod) {
    if (vod.selectedCategoryId == null || vod.selectedCategoryId == 'all') {
      return 'TODOS OS FILMES';
    }
    final cat = vod.categories.cast<VodCategory?>().firstWhere(
          (c) => c?.categoryId == vod.selectedCategoryId,
          orElse: () => null,
        );
    return cat != null ? cat.categoryName.toUpperCase() : 'CATEGORIA';
  }

  Widget _buildTopBar(BuildContext context, VodProvider vod, dynamic account, bool isNarrow) {
    final hasSearch = _searchController.text.isNotEmpty || vod.searchQuery.isNotEmpty;

    // Modo Mobile Vertical com busca expandida
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
                  onSubmitted: (val) => _performSearch(val, vod),
                  onChanged: (val) => _onSearchChanged(val, vod),
                  style: AppTypography.body(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: context.tr('vod.search_hint'),
                    hintStyle: AppTypography.mono(fontSize: 11, color: AppColors.textDisabled),
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.search_rounded, size: 18, color: AppColors.accentPrimary),
                      tooltip: context.tr('common.search'),
                      onPressed: () => _performSearch(_searchController.text, vod),
                    ),
                    suffixIcon: hasSearch
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                            onPressed: () => _clearSearch(vod),
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

    // Top Bar Padrão (ou Desktop / Modo fechado no Mobile)
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
              _clearSearch(vod);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 4),
          Text(
            'FILMES.',
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
                  color: vod.filterState.hasActiveFilters ? AppColors.accentPrimary : AppColors.textPrimary,
                ),
                onPressed: () {
                  ContentFilterModal.showContentFilter(
                    context: context,
                    currentState: vod.filterState,
                    onApply: (newState) => vod.setFilterState(newState),
                  );
                },
              ),
              if (vod.filterState.hasActiveFilters)
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
                vod.refresh(account);
              }
            },
          ),
          const SizedBox(width: 4),

          // No mobile: se houver busca ativa, mostra chip com termo e botão de fechar (sem lupa redundante).
          // Se não houver busca ativa, mostra apenas o botão da lupa.
          if (isNarrow) ...[
            if (hasSearch)
              Flexible(
                child: GestureDetector(
                  onTap: () => setState(() => _isSearchExpanded = true),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.accentPrimary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'BUSCA: "${vod.searchQuery.isNotEmpty ? vod.searchQuery : _searchController.text}"',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: AppTypography.mono(
                              fontSize: 10,
                              color: AppColors.accentPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _clearSearch(vod),
                          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.accentPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
                tooltip: context.tr('common.search'),
                onPressed: () {
                  setState(() => _isSearchExpanded = true);
                },
              ),
          ] else ...[
            // Desktop / Landscape: campo de busca inline elegante
            SizedBox(
              width: 240,
              height: 38,
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (val) => _performSearch(val, vod),
                onChanged: (val) => _onSearchChanged(val, vod),
                style: AppTypography.body(fontSize: 13),
                decoration: InputDecoration(
                  hintText: context.tr('vod.search_desktop_hint'),
                  hintStyle: AppTypography.mono(fontSize: 11, color: AppColors.textDisabled),
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                    tooltip: context.tr('common.search'),
                    onPressed: () => _performSearch(_searchController.text, vod),
                  ),
                  suffixIcon: hasSearch
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                          onPressed: () => _clearSearch(vod),
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

  Widget _buildCategorySelector(BuildContext context, VodProvider vod, dynamic account) {
    if (vod.isLoadingCategories) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: HankoLoader.compact(label: 'CATEGORIAS.'),
        ),
      );
    }

    if (vod.categories.isEmpty) return const SizedBox.shrink();

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
        itemCount: vod.categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isSelected = isAll ? (vod.selectedCategoryId == null || vod.selectedCategoryId == 'all') : vod.selectedCategoryId == vod.categories[index - 1].categoryId;

          final label = isAll ? 'TODOS' : vod.categories[index - 1].categoryName.toUpperCase();

          return FocusableCategoryChip(
            label: label,
            isSelected: isSelected,
            autofocus: isAll,
            onTap: () {
              if (account != null) {
                vod.selectCategory(account, isAll ? 'all' : vod.categories[index - 1].categoryId);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMoviesGrid(BuildContext context, List<VodItem> movies) {
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
            childAspectRatio: 0.63,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
            return BrutalistEntrance(
              index: index,
              child: _buildMovieCard(context, movie),
            );
          },
        );
      },
    );
  }

  Widget _buildMovieCard(BuildContext context, VodItem movie) {
    return BentoCard(
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VodDetailScreen(item: movie),
          ),
        );
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
                  child: movie.streamIcon != null && movie.streamIcon!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: movie.streamIcon!,
                          fit: BoxFit.cover,
                          memCacheWidth: 320,
                          memCacheHeight: 480,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceCard,
                            child: const Center(
                              child: Icon(Icons.movie_outlined, size: 36, color: AppColors.textMuted),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceCard,
                          child: const Center(
                            child: Icon(Icons.movie_outlined, size: 36, color: AppColors.textMuted),
                          ),
                        ),
                ),
                // Pílula com o Ano (canto superior esquerdo)
                if (movie.displayYear != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        movie.displayYear!,
                        style: AppTypography.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                // Pílula com a Nota (canto superior direito)
                if (movie.rating > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '★ ${movie.rating.toStringAsFixed(1)}',
                        style: AppTypography.mono(fontSize: 10, color: AppColors.accentPrimary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  movie.name.toUpperCase().endsWith('.') ? movie.name.toUpperCase() : '${movie.name.toUpperCase()}.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sectionTitle(fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  '[ VOD // HD ]',
                  style: AppTypography.mono(fontSize: 9, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
