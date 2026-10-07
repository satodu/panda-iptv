import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/brutalist_entrance.dart';
import '../../../core/widgets/hanko_badge.dart';
import '../../../core/widgets/hanko_loader.dart';
import '../../../core/widgets/tech_crosses.dart';
import '../../../core/widgets/focusable_category_chip.dart';
import '../../auth/presentation/auth_provider.dart';
import '../models/series_category.dart';
import '../models/series_item.dart';
import 'series_detail_screen.dart';
import 'series_provider.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final account = context.read<AuthProvider>().currentAccount;
      if (account != null) {
        context.read<SeriesProvider>().init(account);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seriesProv = context.watch<SeriesProvider>();
    final account = context.watch<AuthProvider>().currentAccount;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar Responsiva
            _buildTopBar(context, seriesProv, isNarrow),

            // Categories Bar
            _buildCategorySelector(context, seriesProv, account),

            // Sub-barra com contagem e status
            if (!seriesProv.isLoadingSeries && seriesProv.error == null && seriesProv.filteredSeries.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.canvas,
                  border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
                ),
                child: Row(
                  children: [
                    Text(
                      _getSelectedCategoryName(seriesProv),
                      style: AppTypography.mono(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '[ ${seriesProv.filteredSeries.length} TÍTULOS ]',
                      style: AppTypography.mono(fontSize: 10, color: AppColors.accentCyan),
                    ),
                    const Spacer(),
                    const TechCrosses(count: 3, opacity: 0.15),
                  ],
                ),
              ),

            // Series Grid
            Expanded(
              child: seriesProv.isLoadingSeries
                  ? const Center(child: HankoLoader(label: 'CARREGANDO SÉRIES.'))
                  : seriesProv.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.statusError, size: 36),
                              const SizedBox(height: 12),
                              Text('ERRO AO CARREGAR.', style: AppTypography.titleMedium(color: AppColors.statusError)),
                              const SizedBox(height: 6),
                              Text(seriesProv.error!, style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
                                onPressed: () {
                                  if (account != null) seriesProv.init(account);
                                },
                                child: Text('TENTAR NOVAMENTE.', style: AppTypography.button()),
                              ),
                            ],
                          ),
                        )
                      : seriesProv.filteredSeries.isEmpty
                          ? Center(
                              child: Text(
                                'NENHUMA SÉRIE ENCONTRADA.',
                                style: AppTypography.mono(fontSize: 13, color: AppColors.textMuted),
                              ),
                            )
                          : _buildSeriesGrid(context, seriesProv.filteredSeries),
            ),
          ],
        ),
      ),
    );
  }

  String _getSelectedCategoryName(SeriesProvider seriesProv) {
    if (seriesProv.selectedCategoryId == null || seriesProv.selectedCategoryId == 'all') {
      return 'TODAS AS SÉRIES';
    }
    final cat = seriesProv.categories.cast<SeriesCategory?>().firstWhere(
          (c) => c?.categoryId == seriesProv.selectedCategoryId,
          orElse: () => null,
        );
    return cat != null ? cat.categoryName.toUpperCase() : 'CATEGORIA';
  }

  Widget _buildTopBar(BuildContext context, SeriesProvider seriesProv, bool isNarrow) {
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
                  onChanged: (val) => seriesProv.setSearchQuery(val),
                  style: AppTypography.body(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'DIGITE O NOME DA SÉRIE...',
                    hintStyle: AppTypography.mono(fontSize: 11, color: AppColors.textDisabled),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.accentPrimary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              seriesProv.setSearchQuery('');
                            },
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Text(
            'SÉRIES.',
            style: AppTypography.titleMedium(fontSize: isNarrow ? 14 : 16),
          ),
          if (!isNarrow) ...[
            const SizedBox(width: 16),
            const TechCrosses(count: 3, opacity: 0.2),
          ],
          const Spacer(),

          // No mobile: botão de busca com badge ativo se houver texto
          if (isNarrow) ...[
            if (_searchController.text.isNotEmpty) ...[
              GestureDetector(
                onTap: () => setState(() => _isSearchExpanded = true),
                child: const HankoBadge(
                  text: 'BUSCA ATIVA',
                  borderColor: AppColors.accentPrimary,
                  textColor: AppColors.accentPrimary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              icon: Icon(
                Icons.search_rounded,
                color: _searchController.text.isNotEmpty ? AppColors.accentPrimary : AppColors.textPrimary,
              ),
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
                onChanged: (val) => seriesProv.setSearchQuery(val),
                style: AppTypography.body(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'BUSCAR SÉRIE...',
                  hintStyle: AppTypography.mono(fontSize: 11, color: AppColors.textDisabled),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            seriesProv.setSearchQuery('');
                          },
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

  Widget _buildCategorySelector(BuildContext context, SeriesProvider seriesProv, dynamic account) {
    if (seriesProv.isLoadingCategories) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: HankoLoader.compact(label: 'CATEGORIAS.'),
        ),
      );
    }

    if (seriesProv.categories.isEmpty) return const SizedBox.shrink();

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
        itemCount: seriesProv.categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isSelected = isAll ? (seriesProv.selectedCategoryId == null || seriesProv.selectedCategoryId == 'all') : seriesProv.selectedCategoryId == seriesProv.categories[index - 1].categoryId;

          final label = isAll ? 'TODOS' : seriesProv.categories[index - 1].categoryName.toUpperCase();

          return FocusableCategoryChip(
            label: label,
            isSelected: isSelected,
            onTap: () {
              if (account != null) {
                seriesProv.selectCategory(account, isAll ? 'all' : seriesProv.categories[index - 1].categoryId);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildSeriesGrid(BuildContext context, List<SeriesItem> seriesList) {
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
          padding: EdgeInsets.all(isNarrow ? 12 : 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isNarrow ? 10 : 14,
            mainAxisSpacing: isNarrow ? 10 : 14,
            childAspectRatio: isNarrow ? 0.57 : 0.63,
          ),
          itemCount: seriesList.length,
          itemBuilder: (context, index) {
            final item = seriesList[index];
            return BrutalistEntrance(
              index: index,
              child: _buildSeriesCard(context, item),
            );
          },
        );
      },
    );
  }

  Widget _buildSeriesCard(BuildContext context, SeriesItem item) {
    return Tooltip(
      message: item.name,
      waitDuration: const Duration(milliseconds: 600),
      child: BentoCard(
        padding: EdgeInsets.zero,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SeriesDetailScreen(item: item),
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
                    child: item.cover != null && item.cover!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.cover!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.surfaceCard,
                              child: const Center(
                                child: Icon(Icons.video_collection_outlined, size: 36, color: AppColors.textMuted),
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.surfaceCard,
                            child: const Center(
                              child: Icon(Icons.video_collection_outlined, size: 36, color: AppColors.textMuted),
                            ),
                          ),
                  ),
                  if (item.rating > 0)
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
                          '★ ${item.rating.toStringAsFixed(1)}',
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
                    item.name.toUpperCase().endsWith('.') ? item.name.toUpperCase() : '${item.name.toUpperCase()}.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sectionTitle(fontSize: 11).copyWith(height: 1.2),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '[ SÉRIE // ON DEMAND ]',
                    style: AppTypography.mono(fontSize: 9, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
