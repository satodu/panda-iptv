import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../models/content_filter_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'tech_crosses.dart';

/// Modal responsivo de Filtros & Ordenação
/// Adapta-se automaticamente:
/// - No Mobile (< 600px): Bottom Sheet deslizante com Bento design
/// - No Desktop / TV: Diálogo centralizado navegável via D-pad / Teclado
class ContentFilterModal {
  static Future<void> showContentFilter({
    required BuildContext context,
    required ContentFilterState currentState,
    required ValueChanged<ContentFilterState> onApply,
  }) async {
    final isNarrow = MediaQuery.of(context).size.width < 600;

    if (isNarrow) {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => _ContentFilterSheet(
          initialState: currentState,
          onApply: onApply,
        ),
      );
    } else {
      await showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
            child: _ContentFilterDialog(
              initialState: currentState,
              onApply: onApply,
            ),
          ),
        ),
      );
    }
  }

  static Future<void> showLiveFilter({
    required BuildContext context,
    required LiveFilterState currentState,
    required ValueChanged<LiveFilterState> onApply,
  }) async {
    final isNarrow = MediaQuery.of(context).size.width < 600;

    if (isNarrow) {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => _LiveFilterSheet(
          initialState: currentState,
          onApply: onApply,
        ),
      );
    } else {
      await showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 520),
            child: _LiveFilterDialog(
              initialState: currentState,
              onApply: onApply,
            ),
          ),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// FILTROS DE CONTEÚDO (VOD / SÉRIES)
// ---------------------------------------------------------------------------

class _ContentFilterDialog extends StatefulWidget {
  final ContentFilterState initialState;
  final ValueChanged<ContentFilterState> onApply;

  const _ContentFilterDialog({
    required this.initialState,
    required this.onApply,
  });

  @override
  State<_ContentFilterDialog> createState() => _ContentFilterDialogState();
}

class _ContentFilterDialogState extends State<_ContentFilterDialog> {
  late ContentFilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDialog,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderHairline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const Divider(height: 1, color: AppColors.borderHairline),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildFilterBody(context),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderHairline),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: AppColors.accentPrimary, size: 20),
          const SizedBox(width: 10),
          Text(
            context.tr('filter.title'),
            style: AppTypography.sectionTitle(fontSize: 16),
          ),
          if (_state.hasActiveFilters) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.accentPrimary),
              ),
              child: Text(
                '[ ${_state.activeFiltersCount} ]',
                style: AppTypography.mono(fontSize: 10, color: AppColors.accentPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const Spacer(),
          const TechCrosses(count: 3, opacity: 0.2),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. ORDENAR POR
        _FilterSectionHeader(label: context.tr('filter.sort_by')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PillChip(
              label: context.tr('filter.sort_recent'),
              isSelected: _state.sortOption == ContentSortOption.recentYear,
              icon: Icons.calendar_today_rounded,
              onTap: () => setState(() => _state = _state.copyWith(sortOption: ContentSortOption.recentYear)),
            ),
            _PillChip(
              label: context.tr('filter.sort_added'),
              isSelected: _state.sortOption == ContentSortOption.addedServer,
              icon: Icons.fiber_new_rounded,
              onTap: () => setState(() => _state = _state.copyWith(sortOption: ContentSortOption.addedServer)),
            ),
            _PillChip(
              label: context.tr('filter.sort_rating'),
              isSelected: _state.sortOption == ContentSortOption.rating,
              icon: Icons.star_rounded,
              onTap: () => setState(() => _state = _state.copyWith(sortOption: ContentSortOption.rating)),
            ),
            _PillChip(
              label: context.tr('filter.sort_alpha_asc'),
              isSelected: _state.sortOption == ContentSortOption.alphaAsc,
              onTap: () => setState(() => _state = _state.copyWith(sortOption: ContentSortOption.alphaAsc)),
            ),
            _PillChip(
              label: context.tr('filter.sort_alpha_desc'),
              isSelected: _state.sortOption == ContentSortOption.alphaDesc,
              onTap: () => setState(() => _state = _state.copyWith(sortOption: ContentSortOption.alphaDesc)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. ESTILOS / GÊNEROS
        _FilterSectionHeader(label: context.tr('filter.genres')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ContentFilterState.standardGenres.map((g) {
            final isAll = g == 'all';
            final isSelected = (_state.genre == null && isAll) || (_state.genre == g) || (_state.genre == 'all' && isAll);
            return _PillChip(
              label: isAll ? context.tr('filter.genre_all') : g.toUpperCase(),
              isSelected: isSelected,
              onTap: () => setState(() => _state = _state.copyWith(genre: g)),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // 3. LANÇAMENTOS RECENTES
        _FilterSectionHeader(label: context.tr('filter.top_releases')),
        const SizedBox(height: 8),
        _PillChip(
          label: context.tr('filter.top_releases'),
          isSelected: _state.onlyRecentReleases,
          icon: Icons.local_fire_department_rounded,
          onTap: () => setState(() => _state = _state.copyWith(onlyRecentReleases: !_state.onlyRecentReleases)),
        ),
        const SizedBox(height: 20),

        // 3. ÁUDIO / IDIOMA
        _FilterSectionHeader(label: context.tr('filter.audio')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PillChip(
              label: context.tr('filter.audio_all'),
              isSelected: _state.audioOption == ContentAudioOption.all,
              onTap: () => setState(() => _state = _state.copyWith(audioOption: ContentAudioOption.all)),
            ),
            _PillChip(
              label: context.tr('filter.audio_dub'),
              isSelected: _state.audioOption == ContentAudioOption.dubbed,
              onTap: () => setState(() => _state = _state.copyWith(audioOption: ContentAudioOption.dubbed)),
            ),
            _PillChip(
              label: context.tr('filter.audio_sub'),
              isSelected: _state.audioOption == ContentAudioOption.subtitled,
              onTap: () => setState(() => _state = _state.copyWith(audioOption: ContentAudioOption.subtitled)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 4. QUALIDADE
        _FilterSectionHeader(label: context.tr('filter.quality')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PillChip(
              label: context.tr('filter.quality_all'),
              isSelected: _state.qualityOption == ContentQualityOption.all,
              onTap: () => setState(() => _state = _state.copyWith(qualityOption: ContentQualityOption.all)),
            ),
            _PillChip(
              label: context.tr('filter.quality_4k'),
              isSelected: _state.qualityOption == ContentQualityOption.q4k,
              onTap: () => setState(() => _state = _state.copyWith(qualityOption: ContentQualityOption.q4k)),
            ),
            _PillChip(
              label: context.tr('filter.quality_fhd'),
              isSelected: _state.qualityOption == ContentQualityOption.qFhd,
              onTap: () => setState(() => _state = _state.copyWith(qualityOption: ContentQualityOption.qFhd)),
            ),
            _PillChip(
              label: context.tr('filter.quality_hd'),
              isSelected: _state.qualityOption == ContentQualityOption.qHd,
              onTap: () => setState(() => _state = _state.copyWith(qualityOption: ContentQualityOption.qHd)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 5. STATUS
        _FilterSectionHeader(label: context.tr('filter.status')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PillChip(
              label: context.tr('filter.status_all'),
              isSelected: _state.watchedOption == ContentWatchedOption.all,
              onTap: () => setState(() => _state = _state.copyWith(watchedOption: ContentWatchedOption.all)),
            ),
            _PillChip(
              label: context.tr('filter.status_unwatched'),
              isSelected: _state.watchedOption == ContentWatchedOption.unwatched,
              icon: Icons.visibility_off_rounded,
              onTap: () => setState(() => _state = _state.copyWith(watchedOption: ContentWatchedOption.unwatched)),
            ),
            _PillChip(
              label: context.tr('filter.status_watched'),
              isSelected: _state.watchedOption == ContentWatchedOption.watched,
              icon: Icons.check_circle_rounded,
              onTap: () => setState(() => _state = _state.copyWith(watchedOption: ContentWatchedOption.watched)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.restart_alt_rounded, size: 16, color: AppColors.textMuted),
            label: Text(
              context.tr('filter.clear'),
              style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
            ),
            onPressed: () {
              setState(() => _state = ContentFilterState.initial);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              widget.onApply(_state);
              Navigator.of(context).pop();
            },
            child: Text(
              context.tr('filter.apply'),
              style: AppTypography.button(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentFilterSheet extends StatefulWidget {
  final ContentFilterState initialState;
  final ValueChanged<ContentFilterState> onApply;

  const _ContentFilterSheet({
    required this.initialState,
    required this.onApply,
  });

  @override
  State<_ContentFilterSheet> createState() => _ContentFilterSheetState();
}

class _ContentFilterSheetState extends State<_ContentFilterSheet> {
  late ContentFilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDialog,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.borderHairline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.accentPrimary, size: 18),
                const SizedBox(width: 8),
                Text(
                  context.tr('filter.title'),
                  style: AppTypography.sectionTitle(fontSize: 15),
                ),
                if (_state.hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.accentPrimary),
                    ),
                    child: Text(
                      '[ ${_state.activeFiltersCount} ]',
                      style: AppTypography.mono(fontSize: 10, color: AppColors.accentPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderHairline),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildFilterBody(context),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderHairline),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderHairline),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() => _state = ContentFilterState.initial);
                    },
                    child: Text(
                      context.tr('filter.clear'),
                      style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      widget.onApply(_state);
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      context.tr('filter.apply'),
                      style: AppTypography.button(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterSectionHeader(label: context.tr('filter.sort_by')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _PillChip(
              label: context.tr('filter.sort_recent'),
              isSelected: _state.sortOption == ContentSortOption.recentYear,
              icon: Icons.calendar_today_rounded,
              onTap: () => setState(() => _state = _state.copyWith(sortOption: ContentSortOption.recentYear)),
            ),
            _PillChip(
              label: context.tr('filter.sort_added'),
              isSelected: _state.sortOption == ContentSortOption.addedServer,
              icon: Icons.fiber_new_rounded,
              onTap: () => setState(() => _state = _state.copyWith(sortOption: ContentSortOption.addedServer)),
            ),
            _PillChip(
              label: context.tr('filter.sort_rating'),
              isSelected: _state.sortOption == ContentSortOption.rating,
              icon: Icons.star_rounded,
              onTap: () => setState(() => _state = _state.copyWith(sortOption: ContentSortOption.rating)),
            ),
            _PillChip(
              label: context.tr('filter.sort_alpha_asc'),
              isSelected: _state.sortOption == ContentSortOption.alphaAsc,
              onTap: () => setState(() => _state = _state.copyWith(sortOption: ContentSortOption.alphaAsc)),
            ),
            _PillChip(
              label: context.tr('filter.sort_alpha_desc'),
              isSelected: _state.sortOption == ContentSortOption.alphaDesc,
              onTap: () => setState(() => _state = _state.copyWith(sortOption: ContentSortOption.alphaDesc)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _FilterSectionHeader(label: context.tr('filter.genres')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ContentFilterState.standardGenres.map((g) {
            final isAll = g == 'all';
            final isSelected = (_state.genre == null && isAll) || (_state.genre == g) || (_state.genre == 'all' && isAll);
            return _PillChip(
              label: isAll ? context.tr('filter.genre_all') : g.toUpperCase(),
              isSelected: isSelected,
              onTap: () => setState(() => _state = _state.copyWith(genre: g)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        _FilterSectionHeader(label: context.tr('filter.top_releases')),
        const SizedBox(height: 8),
        _PillChip(
          label: context.tr('filter.top_releases'),
          isSelected: _state.onlyRecentReleases,
          icon: Icons.local_fire_department_rounded,
          onTap: () => setState(() => _state = _state.copyWith(onlyRecentReleases: !_state.onlyRecentReleases)),
        ),
        const SizedBox(height: 16),

        _FilterSectionHeader(label: context.tr('filter.audio')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _PillChip(
              label: context.tr('filter.audio_all'),
              isSelected: _state.audioOption == ContentAudioOption.all,
              onTap: () => setState(() => _state = _state.copyWith(audioOption: ContentAudioOption.all)),
            ),
            _PillChip(
              label: context.tr('filter.audio_dub'),
              isSelected: _state.audioOption == ContentAudioOption.dubbed,
              onTap: () => setState(() => _state = _state.copyWith(audioOption: ContentAudioOption.dubbed)),
            ),
            _PillChip(
              label: context.tr('filter.audio_sub'),
              isSelected: _state.audioOption == ContentAudioOption.subtitled,
              onTap: () => setState(() => _state = _state.copyWith(audioOption: ContentAudioOption.subtitled)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _FilterSectionHeader(label: context.tr('filter.quality')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _PillChip(
              label: context.tr('filter.quality_all'),
              isSelected: _state.qualityOption == ContentQualityOption.all,
              onTap: () => setState(() => _state = _state.copyWith(qualityOption: ContentQualityOption.all)),
            ),
            _PillChip(
              label: context.tr('filter.quality_4k'),
              isSelected: _state.qualityOption == ContentQualityOption.q4k,
              onTap: () => setState(() => _state = _state.copyWith(qualityOption: ContentQualityOption.q4k)),
            ),
            _PillChip(
              label: context.tr('filter.quality_fhd'),
              isSelected: _state.qualityOption == ContentQualityOption.qFhd,
              onTap: () => setState(() => _state = _state.copyWith(qualityOption: ContentQualityOption.qFhd)),
            ),
            _PillChip(
              label: context.tr('filter.quality_hd'),
              isSelected: _state.qualityOption == ContentQualityOption.qHd,
              onTap: () => setState(() => _state = _state.copyWith(qualityOption: ContentQualityOption.qHd)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _FilterSectionHeader(label: context.tr('filter.status')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _PillChip(
              label: context.tr('filter.status_all'),
              isSelected: _state.watchedOption == ContentWatchedOption.all,
              onTap: () => setState(() => _state = _state.copyWith(watchedOption: ContentWatchedOption.all)),
            ),
            _PillChip(
              label: context.tr('filter.status_unwatched'),
              isSelected: _state.watchedOption == ContentWatchedOption.unwatched,
              icon: Icons.visibility_off_rounded,
              onTap: () => setState(() => _state = _state.copyWith(watchedOption: ContentWatchedOption.unwatched)),
            ),
            _PillChip(
              label: context.tr('filter.status_watched'),
              isSelected: _state.watchedOption == ContentWatchedOption.watched,
              icon: Icons.check_circle_rounded,
              onTap: () => setState(() => _state = _state.copyWith(watchedOption: ContentWatchedOption.watched)),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FILTROS DE TV AO VIVO (LIVE STREAM)
// ---------------------------------------------------------------------------

class _LiveFilterDialog extends StatefulWidget {
  final LiveFilterState initialState;
  final ValueChanged<LiveFilterState> onApply;

  const _LiveFilterDialog({
    required this.initialState,
    required this.onApply,
  });

  @override
  State<_LiveFilterDialog> createState() => _LiveFilterDialogState();
}

class _LiveFilterDialogState extends State<_LiveFilterDialog> {
  late LiveFilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDialog,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderHairline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const Divider(height: 1, color: AppColors.borderHairline),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildBody(context),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderHairline),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: AppColors.accentPrimary, size: 20),
          const SizedBox(width: 10),
          Text(
            context.tr('filter.title'),
            style: AppTypography.sectionTitle(fontSize: 16),
          ),
          if (_state.hasActiveFilters) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.accentPrimary),
              ),
              child: Text(
                '[ ${_state.activeFiltersCount} ]',
                style: AppTypography.mono(fontSize: 10, color: AppColors.accentPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const Spacer(),
          const TechCrosses(count: 3, opacity: 0.2),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterSectionHeader(label: context.tr('filter.sort_by')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PillChip(
              label: context.tr('filter.live_sort_provider'),
              isSelected: _state.sortOption == LiveSortOption.defaultProvider,
              onTap: () => setState(() => _state = _state.copyWith(sortOption: LiveSortOption.defaultProvider)),
            ),
            _PillChip(
              label: context.tr('filter.live_sort_number'),
              isSelected: _state.sortOption == LiveSortOption.channelNumber,
              icon: Icons.tag_rounded,
              onTap: () => setState(() => _state = _state.copyWith(sortOption: LiveSortOption.channelNumber)),
            ),
            _PillChip(
              label: context.tr('filter.sort_alpha_asc'),
              isSelected: _state.sortOption == LiveSortOption.alphaAsc,
              onTap: () => setState(() => _state = _state.copyWith(sortOption: LiveSortOption.alphaAsc)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _FilterSectionHeader(label: context.tr('filter.live_filter')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PillChip(
              label: context.tr('filter.live_filter_all'),
              isSelected: _state.filterOption == LiveFilterOption.all,
              onTap: () => setState(() => _state = _state.copyWith(filterOption: LiveFilterOption.all)),
            ),
            _PillChip(
              label: context.tr('filter.live_filter_with_epg'),
              isSelected: _state.filterOption == LiveFilterOption.withEpg,
              icon: Icons.live_tv_rounded,
              onTap: () => setState(() => _state = _state.copyWith(filterOption: LiveFilterOption.withEpg)),
            ),
            _PillChip(
              label: context.tr('filter.quality_4k'),
              isSelected: _state.filterOption == LiveFilterOption.q4k,
              onTap: () => setState(() => _state = _state.copyWith(filterOption: LiveFilterOption.q4k)),
            ),
            _PillChip(
              label: context.tr('filter.quality_fhd'),
              isSelected: _state.filterOption == LiveFilterOption.qFhd,
              onTap: () => setState(() => _state = _state.copyWith(filterOption: LiveFilterOption.qFhd)),
            ),
            _PillChip(
              label: context.tr('filter.quality_hd'),
              isSelected: _state.filterOption == LiveFilterOption.qHd,
              onTap: () => setState(() => _state = _state.copyWith(filterOption: LiveFilterOption.qHd)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.restart_alt_rounded, size: 16, color: AppColors.textMuted),
            label: Text(
              context.tr('filter.clear'),
              style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
            ),
            onPressed: () {
              setState(() => _state = LiveFilterState.initial);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              widget.onApply(_state);
              Navigator.of(context).pop();
            },
            child: Text(
              context.tr('filter.apply'),
              style: AppTypography.button(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveFilterSheet extends StatefulWidget {
  final LiveFilterState initialState;
  final ValueChanged<LiveFilterState> onApply;

  const _LiveFilterSheet({
    required this.initialState,
    required this.onApply,
  });

  @override
  State<_LiveFilterSheet> createState() => _LiveFilterSheetState();
}

class _LiveFilterSheetState extends State<_LiveFilterSheet> {
  late LiveFilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDialog,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.borderHairline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.accentPrimary, size: 18),
                const SizedBox(width: 8),
                Text(
                  context.tr('filter.title'),
                  style: AppTypography.sectionTitle(fontSize: 15),
                ),
                if (_state.hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.accentPrimary),
                    ),
                    child: Text(
                      '[ ${_state.activeFiltersCount} ]',
                      style: AppTypography.mono(fontSize: 10, color: AppColors.accentPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderHairline),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilterSectionHeader(label: context.tr('filter.sort_by')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _PillChip(
                        label: context.tr('filter.live_sort_provider'),
                        isSelected: _state.sortOption == LiveSortOption.defaultProvider,
                        onTap: () => setState(() => _state = _state.copyWith(sortOption: LiveSortOption.defaultProvider)),
                      ),
                      _PillChip(
                        label: context.tr('filter.live_sort_number'),
                        isSelected: _state.sortOption == LiveSortOption.channelNumber,
                        icon: Icons.tag_rounded,
                        onTap: () => setState(() => _state = _state.copyWith(sortOption: LiveSortOption.channelNumber)),
                      ),
                      _PillChip(
                        label: context.tr('filter.sort_alpha_asc'),
                        isSelected: _state.sortOption == LiveSortOption.alphaAsc,
                        onTap: () => setState(() => _state = _state.copyWith(sortOption: LiveSortOption.alphaAsc)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _FilterSectionHeader(label: context.tr('filter.live_filter')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _PillChip(
                        label: context.tr('filter.live_filter_all'),
                        isSelected: _state.filterOption == LiveFilterOption.all,
                        onTap: () => setState(() => _state = _state.copyWith(filterOption: LiveFilterOption.all)),
                      ),
                      _PillChip(
                        label: context.tr('filter.live_filter_with_epg'),
                        isSelected: _state.filterOption == LiveFilterOption.withEpg,
                        icon: Icons.live_tv_rounded,
                        onTap: () => setState(() => _state = _state.copyWith(filterOption: LiveFilterOption.withEpg)),
                      ),
                      _PillChip(
                        label: context.tr('filter.quality_4k'),
                        isSelected: _state.filterOption == LiveFilterOption.q4k,
                        onTap: () => setState(() => _state = _state.copyWith(filterOption: LiveFilterOption.q4k)),
                      ),
                      _PillChip(
                        label: context.tr('filter.quality_fhd'),
                        isSelected: _state.filterOption == LiveFilterOption.qFhd,
                        onTap: () => setState(() => _state = _state.copyWith(filterOption: LiveFilterOption.qFhd)),
                      ),
                      _PillChip(
                        label: context.tr('filter.quality_hd'),
                        isSelected: _state.filterOption == LiveFilterOption.qHd,
                        onTap: () => setState(() => _state = _state.copyWith(filterOption: LiveFilterOption.qHd)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderHairline),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderHairline),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() => _state = LiveFilterState.initial);
                    },
                    child: Text(
                      context.tr('filter.clear'),
                      style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      widget.onApply(_state);
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      context.tr('filter.apply'),
                      style: AppTypography.button(fontSize: 12, color: Colors.white),
                    ),
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

// ---------------------------------------------------------------------------
// SUB-COMPONENTES REUTILIZÁVEIS
// ---------------------------------------------------------------------------

class _FilterSectionHeader extends StatelessWidget {
  final String label;

  const _FilterSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.accentPrimary,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.mono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _PillChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _PillChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  State<_PillChip> createState() => _PillChipState();
}

class _PillChipState extends State<_PillChip> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isFocused ? 1.05 : (_isHovered ? 1.02 : 1.0);

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accentPrimary
                : (_isFocused ? AppColors.surfaceHover : AppColors.surfaceCard),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused
                  ? AppColors.accentCyan
                  : (widget.isSelected ? AppColors.accentPrimary : AppColors.borderHairline),
              width: _isFocused ? 1.8 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.accentCyan.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                  size: 13,
                  color: widget.isSelected
                      ? Colors.white
                      : (_isFocused ? AppColors.accentCyan : AppColors.textMuted),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: AppTypography.mono(
                  fontSize: 11,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected
                      ? Colors.white
                      : (_isFocused ? AppColors.accentCyan : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
