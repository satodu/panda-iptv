import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../models/content_filter_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'content_filter_modal.dart';

/// Barra de filtros rápidos horizontal oriental brutalista
/// Funciona com 1-toque em mobile, mouse em desktop e D-Pad em Android TV.
class QuickFilterBar extends StatelessWidget {
  final Widget? leading;
  final List<Widget> children;
  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;

  const QuickFilterBar({
    super.key,
    this.leading,
    required this.children,
    this.hasActiveFilters = false,
    this.onClearFilters,
  });

  /// Factory para Filmes (VOD) e Séries
  static Widget content({
    required BuildContext context,
    required ContentFilterState filterState,
    required ValueChanged<ContentFilterState> onFilterChanged,
  }) {
    return _ContentQuickFilterBar(
      filterState: filterState,
      onFilterChanged: onFilterChanged,
    );
  }

  /// Factory para TV Ao Vivo
  static Widget live({
    required BuildContext context,
    required LiveFilterState filterState,
    required ValueChanged<LiveFilterState> onFilterChanged,
  }) {
    return _LiveQuickFilterBar(
      filterState: filterState,
      onFilterChanged: onFilterChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(
          bottom: BorderSide(color: AppColors.borderHairline),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 8),
          ],
          ...children,
          if (hasActiveFilters && onClearFilters != null) ...[
            const SizedBox(width: 8),
            _QuickActionPill(
              label: context.tr('filter.clear'),
              icon: Icons.close_rounded,
              isDestructive: true,
              isSelected: false,
              onTap: onClearFilters!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContentQuickFilterBar extends StatelessWidget {
  final ContentFilterState filterState;
  final ValueChanged<ContentFilterState> onFilterChanged;

  const _ContentQuickFilterBar({
    required this.filterState,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasActive = filterState.hasActiveFilters;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(
          bottom: BorderSide(color: AppColors.borderHairline),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          // Botão principal de abrir modal completo de filtros
          _FilterModalTriggerButton(
            label: context.tr('filter.button'),
            activeCount: filterState.activeFiltersCount,
            onTap: () {
              ContentFilterModal.showContentFilter(
                context: context,
                currentState: filterState,
                onApply: onFilterChanged,
              );
            },
          ),
          const SizedBox(width: 8),

          // Pílula de Gênero / Estilo (se ativo)
          if (filterState.genre != null && filterState.genre != 'all') ...[
            _QuickActionPill(
              label: filterState.genre!.toUpperCase(),
              icon: Icons.movie_filter_rounded,
              isSelected: true,
              onTap: () {
                onFilterChanged(filterState.copyWith(genre: 'all'));
              },
            ),
            const SizedBox(width: 6),
          ],

          // Lançamentos
          _QuickActionPill(
            label: context.tr('filter.top_releases'),
            icon: Icons.local_fire_department_rounded,
            isSelected: filterState.onlyRecentReleases,
            onTap: () {
              onFilterChanged(
                filterState.copyWith(onlyRecentReleases: !filterState.onlyRecentReleases),
              );
            },
          ),
          const SizedBox(width: 6),

          // Dublados
          _QuickActionPill(
            label: context.tr('filter.audio_dub'),
            isSelected: filterState.audioOption == ContentAudioOption.dubbed,
            onTap: () {
              onFilterChanged(
                filterState.copyWith(
                  audioOption: filterState.audioOption == ContentAudioOption.dubbed
                      ? ContentAudioOption.all
                      : ContentAudioOption.dubbed,
                ),
              );
            },
          ),
          const SizedBox(width: 6),

          // Legendados
          _QuickActionPill(
            label: context.tr('filter.audio_sub'),
            isSelected: filterState.audioOption == ContentAudioOption.subtitled,
            onTap: () {
              onFilterChanged(
                filterState.copyWith(
                  audioOption: filterState.audioOption == ContentAudioOption.subtitled
                      ? ContentAudioOption.all
                      : ContentAudioOption.subtitled,
                ),
              );
            },
          ),
          const SizedBox(width: 6),

          // 4K UHD
          _QuickActionPill(
            label: context.tr('filter.quality_4k'),
            isSelected: filterState.qualityOption == ContentQualityOption.q4k,
            onTap: () {
              onFilterChanged(
                filterState.copyWith(
                  qualityOption: filterState.qualityOption == ContentQualityOption.q4k
                      ? ContentQualityOption.all
                      : ContentQualityOption.q4k,
                ),
              );
            },
          ),
          const SizedBox(width: 6),

          // Novidades do Provedor
          _QuickActionPill(
            label: context.tr('filter.sort_added'),
            icon: Icons.fiber_new_rounded,
            isSelected: filterState.sortOption == ContentSortOption.addedServer,
            onTap: () {
              onFilterChanged(
                filterState.copyWith(
                  sortOption: filterState.sortOption == ContentSortOption.addedServer
                      ? ContentSortOption.recentYear
                      : ContentSortOption.addedServer,
                ),
              );
            },
          ),
          const SizedBox(width: 6),

          // Melhor Nota
          _QuickActionPill(
            label: context.tr('filter.sort_rating'),
            icon: Icons.star_rounded,
            isSelected: filterState.sortOption == ContentSortOption.rating,
            onTap: () {
              onFilterChanged(
                filterState.copyWith(
                  sortOption: filterState.sortOption == ContentSortOption.rating
                      ? ContentSortOption.recentYear
                      : ContentSortOption.rating,
                ),
              );
            },
          ),

          // Limpar se houver ativo
          if (hasActive) ...[
            const SizedBox(width: 8),
            _QuickActionPill(
              label: context.tr('filter.clear'),
              icon: Icons.close_rounded,
              isDestructive: true,
              isSelected: false,
              onTap: () => onFilterChanged(ContentFilterState.initial),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveQuickFilterBar extends StatelessWidget {
  final LiveFilterState filterState;
  final ValueChanged<LiveFilterState> onFilterChanged;

  const _LiveQuickFilterBar({
    required this.filterState,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasActive = filterState.hasActiveFilters;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(
          bottom: BorderSide(color: AppColors.borderHairline),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          // Botão principal de abrir modal completo de filtros
          _FilterModalTriggerButton(
            label: context.tr('filter.button'),
            activeCount: filterState.activeFiltersCount,
            onTap: () {
              ContentFilterModal.showLiveFilter(
                context: context,
                currentState: filterState,
                onApply: onFilterChanged,
              );
            },
          ),
          const SizedBox(width: 8),

          // Com EPG (Guia)
          _QuickActionPill(
            label: context.tr('filter.live_filter_with_epg'),
            icon: Icons.live_tv_rounded,
            isSelected: filterState.filterOption == LiveFilterOption.withEpg,
            onTap: () {
              onFilterChanged(
                filterState.copyWith(
                  filterOption: filterState.filterOption == LiveFilterOption.withEpg
                      ? LiveFilterOption.all
                      : LiveFilterOption.withEpg,
                ),
              );
            },
          ),
          const SizedBox(width: 6),

          // 4K UHD
          _QuickActionPill(
            label: context.tr('filter.quality_4k'),
            isSelected: filterState.filterOption == LiveFilterOption.q4k,
            onTap: () {
              onFilterChanged(
                filterState.copyWith(
                  filterOption: filterState.filterOption == LiveFilterOption.q4k
                      ? LiveFilterOption.all
                      : LiveFilterOption.q4k,
                ),
              );
            },
          ),
          const SizedBox(width: 6),

          // 1080p FHD
          _QuickActionPill(
            label: context.tr('filter.quality_fhd'),
            isSelected: filterState.filterOption == LiveFilterOption.qFhd,
            onTap: () {
              onFilterChanged(
                filterState.copyWith(
                  filterOption: filterState.filterOption == LiveFilterOption.qFhd
                      ? LiveFilterOption.all
                      : LiveFilterOption.qFhd,
                ),
              );
            },
          ),
          const SizedBox(width: 6),

          // Ordenar por Número (#)
          _QuickActionPill(
            label: context.tr('filter.live_sort_number'),
            icon: Icons.tag_rounded,
            isSelected: filterState.sortOption == LiveSortOption.channelNumber,
            onTap: () {
              onFilterChanged(
                filterState.copyWith(
                  sortOption: filterState.sortOption == LiveSortOption.channelNumber
                      ? LiveSortOption.defaultProvider
                      : LiveSortOption.channelNumber,
                ),
              );
            },
          ),
          const SizedBox(width: 6),

          // A - Z
          _QuickActionPill(
            label: context.tr('filter.sort_alpha_asc'),
            isSelected: filterState.sortOption == LiveSortOption.alphaAsc,
            onTap: () {
              onFilterChanged(
                filterState.copyWith(
                  sortOption: filterState.sortOption == LiveSortOption.alphaAsc
                      ? LiveSortOption.defaultProvider
                      : LiveSortOption.alphaAsc,
                ),
              );
            },
          ),

          // Limpar
          if (hasActive) ...[
            const SizedBox(width: 8),
            _QuickActionPill(
              label: context.tr('filter.clear'),
              icon: Icons.close_rounded,
              isDestructive: true,
              isSelected: false,
              onTap: () => onFilterChanged(LiveFilterState.initial),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterModalTriggerButton extends StatefulWidget {
  final String label;
  final int activeCount;
  final VoidCallback onTap;

  const _FilterModalTriggerButton({
    required this.label,
    required this.activeCount,
    required this.onTap,
  });

  @override
  State<_FilterModalTriggerButton> createState() => _FilterModalTriggerButtonState();
}

class _FilterModalTriggerButtonState extends State<_FilterModalTriggerButton> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isFocused ? 1.05 : (_isHovered ? 1.02 : 1.0);
    final hasActive = widget.activeCount > 0;

    return FocusableActionDetector(
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onTap(),
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.diagonal3Values(scale, scale, 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: hasActive
                ? AppColors.accentPrimary.withValues(alpha: 0.15)
                : (_isFocused ? AppColors.surfaceHover : AppColors.surfaceCard),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isFocused
                  ? AppColors.accentCyan
                  : (hasActive ? AppColors.accentPrimary : AppColors.borderHairline),
              width: _isFocused || hasActive ? 1.5 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.accentCyan.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 13,
                color: hasActive ? AppColors.accentPrimary : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: AppTypography.mono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: hasActive ? AppColors.accentPrimary : AppColors.textPrimary,
                ),
              ),
              if (hasActive) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${widget.activeCount}',
                    style: AppTypography.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionPill extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final bool isDestructive;
  final VoidCallback onTap;

  const _QuickActionPill({
    required this.label,
    this.icon,
    required this.isSelected,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  State<_QuickActionPill> createState() => _QuickActionPillState();
}

class _QuickActionPillState extends State<_QuickActionPill> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isFocused ? 1.05 : (_isHovered ? 1.02 : 1.0);

    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (widget.isDestructive) {
      bgColor = _isFocused ? AppColors.statusError.withValues(alpha: 0.2) : AppColors.surfaceCard;
      borderColor = _isFocused ? AppColors.statusError : AppColors.statusError.withValues(alpha: 0.4);
      textColor = AppColors.statusError;
    } else if (widget.isSelected) {
      bgColor = AppColors.accentPrimary;
      borderColor = AppColors.accentPrimary;
      textColor = Colors.white;
    } else {
      bgColor = _isFocused ? AppColors.surfaceHover : AppColors.surfaceCard;
      borderColor = _isFocused ? AppColors.accentCyan : AppColors.borderHairline;
      textColor = _isFocused ? AppColors.accentCyan : AppColors.textMuted;
    }

    return FocusableActionDetector(
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onTap(),
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.diagonal3Values(scale, scale, 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: (widget.isDestructive ? AppColors.statusError : AppColors.accentCyan)
                          .withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 11,
                  color: textColor,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: AppTypography.mono(
                  fontSize: 10,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
