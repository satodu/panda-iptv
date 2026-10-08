import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/fuzzy_search_util.dart';
import '../../../core/widgets/hanko_badge.dart';
import '../../../core/widgets/hanko_loader.dart';
import '../../../core/widgets/tech_crosses.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../live/models/live_epg_item.dart';
import '../../live/models/live_stream_item.dart';
import '../../live/presentation/live_provider.dart';

/// Painel multi-coluna em cascata para TV Ao Vivo:
/// Coluna 1: Categorias do Provedor
/// Coluna 2: Lista de Canais (com busca rápida)
/// Coluna 3: Guia de Programação EPG em tempo real (No Ar + Próximos)
class LiveChannelEpgPanel extends StatefulWidget {
  final String? currentStreamId;
  final ValueChanged<LiveStreamItem> onChannelSelected;
  final VoidCallback onClose;

  const LiveChannelEpgPanel({
    super.key,
    required this.currentStreamId,
    required this.onChannelSelected,
    required this.onClose,
  });

  @override
  State<LiveChannelEpgPanel> createState() => _LiveChannelEpgPanelState();
}

class _LiveChannelEpgPanelState extends State<LiveChannelEpgPanel> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'LiveEpgSearch');
  final ScrollController _channelsScrollController = ScrollController();

  String? _selectedCategoryId; // 'all' ou ID de categoria
  LiveStreamItem? _previewChannel; // Canal selecionado para exibir no EPG

  // Índices para navegação via D-pad em telas compactas (drilldown)
  int _mobileStep = 1; // 0 = Categorias, 1 = Canais, 2 = EPG

  List<LiveEpgItem>? _currentEpg;
  bool _isLoadingEpg = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = 'all';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLiveProviderData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _channelsScrollController.dispose();
    super.dispose();
  }

  void _initLiveProviderData() async {
    final authProv = context.read<AuthProvider>();
    final liveProv = context.read<LiveProvider>();
    final account = authProv.currentAccount;

    if (account == null) return;

    if (!liveProv.isInitialized || liveProv.categories.isEmpty) {
      await liveProv.init(account);
    }

    // Inicializa o canal preview com o canal atualmente em reprodução (se houver)
    if (widget.currentStreamId != null && mounted) {
      final channels = liveProv.getChannelsForCategory('all');
      final currentMatch = channels.where(
        (c) => c.streamId.toString() == widget.currentStreamId,
      );
      if (currentMatch.isNotEmpty) {
        _setPreviewChannel(currentMatch.first);
        final matchIdx = channels.indexWhere((c) => c.streamId.toString() == widget.currentStreamId);
        if (matchIdx > 0 && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_channelsScrollController.hasClients) {
              _channelsScrollController.jumpTo(
                (matchIdx * 56.0).clamp(0.0, _channelsScrollController.position.maxScrollExtent),
              );
            }
          });
        }
      } else if (channels.isNotEmpty) {
        _setPreviewChannel(channels.first);
      }
    } else if (liveProv.filteredChannels.isNotEmpty && mounted) {
      _setPreviewChannel(liveProv.filteredChannels.first);
    }
  }

  void _setPreviewChannel(LiveStreamItem channel) {
    setState(() {
      _previewChannel = channel;
      _currentEpg = null;
      _isLoadingEpg = true;
    });

    final authProv = context.read<AuthProvider>();
    final liveProv = context.read<LiveProvider>();
    final account = authProv.currentAccount;

    if (account == null) {
      setState(() => _isLoadingEpg = false);
      return;
    }

    liveProv.loadChannelEpg(account, channel.streamId).then((epg) {
      if (mounted && _previewChannel?.streamId == channel.streamId) {
        setState(() {
          _currentEpg = epg;
          _isLoadingEpg = false;
        });
      }
    }).catchError((_) {
      if (mounted && _previewChannel?.streamId == channel.streamId) {
        setState(() {
          _currentEpg = [];
          _isLoadingEpg = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final live = context.watch<LiveProvider>();
    final isDesktopOrTv = MediaQuery.of(context).size.width >= 820;

    return FocusScope(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            if (!isDesktopOrTv && _mobileStep > 0) {
              setState(() => _mobileStep--);
              return KeyEventResult.handled;
            }
            widget.onClose();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        color: AppColors.canvas.withValues(alpha: 0.94),
        child: SafeArea(
          child: Column(
            children: [
              // Cabeçalho Principal do Painel
              _buildTopHeader(context, isDesktopOrTv),

              // Corpo do Painel: 3 Colunas em Cascata (Desktop/TV) ou Drilldown (Mobile)
              Expanded(
                child: isDesktopOrTv
                    ? _buildThreeColumnCascade(context, live)
                    : _buildMobileDrilldown(context, live),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isDesktopOrTv) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          bottom: BorderSide(color: AppColors.borderHairline),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.live_tv_rounded, color: AppColors.accentPrimary, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('player.live_channels'),
                style: AppTypography.titleMedium(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                '[ TRANSMISSÃO AO VIVO // GUIA DE CANAIS ]',
                style: AppTypography.mono(fontSize: 10, color: AppColors.accentCyan),
              ),
            ],
          ),
          const Spacer(),
          const TechCrosses(count: 3),
          const SizedBox(width: 12),
          ExcludeFocus(
            child: IconButton(
              tooltip: 'Fechar Guia (ESC)',
              icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 22),
              onPressed: widget.onClose,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceHover,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ).copyWith(
                side: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.focused)) {
                    return const BorderSide(color: AppColors.accentCyan, width: 2.0);
                  }
                  return const BorderSide(color: Colors.transparent);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MODO DESKTOP / TV: 3 COLUNAS EM CASCATA LADO A LADO
  // =========================================================================
  Widget _buildThreeColumnCascade(BuildContext context, LiveProvider live) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Coluna 1: Categorias do Provedor (~240px)
        SizedBox(
          width: 250,
          child: _buildCategoriesColumn(context, live),
        ),

        const VerticalDivider(width: 1, thickness: 1, color: AppColors.borderHairline),

        // Coluna 2: Lista de Canais (~340px)
        SizedBox(
          width: 350,
          child: _buildChannelsColumn(context, live),
        ),

        const VerticalDivider(width: 1, thickness: 1, color: AppColors.borderHairline),

        // Coluna 3: Guia EPG do Canal Selecionado (Flexível)
        Expanded(
          child: _buildEpgColumn(context),
        ),
      ],
    );
  }

  // =========================================================================
  // MODO MOBILE: DRILLDOWN
  // =========================================================================
  Widget _buildMobileDrilldown(BuildContext context, LiveProvider live) {
    return Column(
      children: [
        // Sub-navegador de etapas no mobile
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.surfaceCard,
          child: Row(
            children: [
              if (_mobileStep > 0)
                TextButton.icon(
                  onPressed: () => setState(() => _mobileStep--),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.accentCyan),
                  label: Text(
                    _mobileStep == 2
                        ? context.tr('player.live_channels')
                        : context.tr('player.categories'),
                    style: AppTypography.mono(fontSize: 11, color: AppColors.accentCyan),
                  ),
                ),
              const Spacer(),
              HankoBadge(
                text: _mobileStep == 0
                    ? context.tr('player.categories')
                    : _mobileStep == 1
                        ? context.tr('live.channels_count')
                        : 'EPG',
                borderColor: AppColors.accentPrimary,
                textColor: AppColors.accentPrimary,
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _mobileStep == 0
                ? _buildCategoriesColumn(context, live, isMobile: true)
                : _mobileStep == 1
                    ? _buildChannelsColumn(context, live, isMobile: true)
                    : _buildEpgColumn(context, isMobile: true),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // COLUNA 1: CATEGORIAS DO PROVEDOR
  // =========================================================================
  Widget _buildCategoriesColumn(BuildContext context, LiveProvider live, {bool isMobile = false}) {
    final categories = live.categories;

    return Container(
      color: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header da Coluna
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceCard,
              border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
            ),
            child: Row(
              children: [
                const Icon(Icons.category_outlined, size: 16, color: AppColors.accentPrimary),
                const SizedBox(width: 8),
                Text(
                  context.tr('player.categories'),
                  style: AppTypography.titleMedium(fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '[ ${categories.length + 1} ]',
                  style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // Lista de Categorias
          Expanded(
            child: live.isLoadingCategories
                ? const Center(child: HankoLoader.mini(miniSize: 24))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    itemCount: categories.length + 1, // +1 para "TODOS OS CANAIS"
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final catId = isAll ? 'all' : categories[index - 1].categoryId;
                      final catName = isAll
                          ? context.tr('player.all_channels')
                          : categories[index - 1].categoryName;
                      final isSelected = _selectedCategoryId == catId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _CategoryTile(
                          title: catName,
                          isSelected: isSelected,
                          isAll: isAll,
                          onSelect: () => _onCategoryPicked(catId, live, isMobile: isMobile),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _onCategoryPicked(String catId, LiveProvider live, {bool isMobile = false}) {
    setState(() {
      _selectedCategoryId = catId;
      if (isMobile) _mobileStep = 1;
    });

    final authProv = context.read<AuthProvider>();
    final account = authProv.currentAccount;
    if (account != null) {
      live.selectCategory(account, catId);
    }
  }

  // =========================================================================
  // COLUNA 2: LISTA DE CANAIS (COM BUSCA RÁPIDA)
  // =========================================================================
  Widget _buildChannelsColumn(BuildContext context, LiveProvider live, {bool isMobile = false}) {
    // Obtém canais da categoria ativa
    final rawChannels = _selectedCategoryId == null || _selectedCategoryId == 'all'
        ? live.filteredChannels
        : live.getChannelsForCategory(_selectedCategoryId!);

    // Aplica busca local difusa caso haja termo digitado
    final query = _searchController.text.trim();
    final channels = query.isNotEmpty
        ? FuzzySearchUtil.search<LiveStreamItem>(
            query: query,
            items: rawChannels,
            titleSelector: (c) => c.name,
          )
        : rawChannels;

    return Container(
      color: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de Busca Brutalista Rápida
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceCard,
              border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (_) => setState(() {}),
              style: AppTypography.mono(fontSize: 12, color: AppColors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                hintText: context.tr('player.search_channels'),
                hintStyle: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
                prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 14, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.canvas,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

          // Contagem de canais
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppColors.surfaceHover,
            child: Row(
              children: [
                Text(
                  '${channels.length} ${context.tr('live.channels_count')}',
                  style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted),
                ),
                const Spacer(),
                Text(
                  '[ OK // SINTONIZAR ]',
                  style: AppTypography.mono(fontSize: 9, color: AppColors.accentCyan),
                ),
              ],
            ),
          ),

          // Lista de Canais
          Expanded(
            child: live.isLoadingChannels
                ? const Center(child: HankoLoader.mini(miniSize: 28))
                : channels.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            context.tr('live.empty'),
                            textAlign: TextAlign.center,
                            style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _channelsScrollController,
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        itemCount: channels.length,
                        itemBuilder: (context, index) {
                          final channel = channels[index];
                          final isCurrentlyPlaying =
                              widget.currentStreamId == channel.streamId.toString();
                          final isPreviewing =
                              _previewChannel?.streamId == channel.streamId;
                          final matchIdx = channels.indexWhere((c) => c.streamId.toString() == widget.currentStreamId);
                          final shouldAutofocus = isCurrentlyPlaying || (matchIdx < 0 && index == 0);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _LiveChannelTile(
                              channel: channel,
                              isCurrentlyPlaying: isCurrentlyPlaying,
                              isPreviewing: isPreviewing,
                              autofocus: shouldAutofocus,
                              onTune: () => _tuneChannel(channel),
                              onPreview: () {
                                _setPreviewChannel(channel);
                                if (isMobile) {
                                  setState(() => _mobileStep = 2);
                                }
                              },
                              onBackToCategories: isMobile
                                  ? () => setState(() => _mobileStep = 0)
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _tuneChannel(LiveStreamItem channel) {
    widget.onChannelSelected(channel);
  }

  // =========================================================================
  // COLUNA 3: GUIA EPG DO CANAL SELECIONADO
  // =========================================================================
  Widget _buildEpgColumn(BuildContext context, {bool isMobile = false}) {
    final channel = _previewChannel;

    if (channel == null) {
      return Container(
        color: AppColors.surfaceCard,
        child: Center(
          child: Text(
            context.tr('live.empty'),
            style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      );
    }

    final isCurrentlyPlaying = widget.currentStreamId == channel.streamId.toString();

    return Container(
      color: AppColors.surfaceCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com dados do Canal
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.canvas,
              border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
            ),
            child: Row(
              children: [
                // Logo Grande
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.5)),
                  ),
                  child: channel.streamIcon != null && channel.streamIcon!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: channel.streamIcon!,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.live_tv_rounded,
                            size: 24,
                            color: AppColors.textMuted,
                          ),
                        )
                      : const Icon(Icons.live_tv_rounded, size: 24, color: AppColors.textMuted),
                ),
                const SizedBox(width: 14),

                // Títulos e Tags
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            channel.formattedNumber,
                            style: AppTypography.mono(
                              fontSize: 11,
                              color: AppColors.accentCyan,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          HankoBadge(
                            text: channel.resolutionTag,
                            borderColor: AppColors.accentPrimary,
                            textColor: AppColors.accentPrimary,
                          ),
                          if (isCurrentlyPlaying) ...[
                            const SizedBox(width: 6),
                            const HankoBadge(
                              text: 'NO AR',
                              borderColor: AppColors.statusLive,
                              textColor: AppColors.statusLive,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium(fontSize: 15),
                      ),
                    ],
                  ),
                ),

                // Botão de Sintonizar se não for o canal em reprodução
                if (!isCurrentlyPlaying)
                  ElevatedButton.icon(
                    onPressed: () => _tuneChannel(channel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ).copyWith(
                      side: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.focused)) {
                          return const BorderSide(color: AppColors.accentCyan, width: 2.0);
                        }
                        return null;
                      }),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(
                      'SINTONIZAR.',
                      style: AppTypography.mono(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),

          // Título da Seção EPG
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceHover,
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.accentCyan),
                const SizedBox(width: 6),
                Text(
                  context.tr('player.channel_epg'),
                  style: AppTypography.mono(fontSize: 11, color: AppColors.textPrimary),
                ),
                const Spacer(),
                const TechCrosses(count: 2),
              ],
            ),
          ),

          // Conteúdo do Guia EPG
          Expanded(
            child: _isLoadingEpg
                ? const Center(child: HankoLoader.mini(miniSize: 28))
                : _currentEpg == null || _currentEpg!.isEmpty
                    ? _buildNoEpgNotice(context)
                    : _buildEpgScheduleList(context, _currentEpg!),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEpgNotice(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('player.no_epg'),
              style: AppTypography.titleMedium(fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('player.no_epg_desc'),
              textAlign: TextAlign.center,
              style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpgScheduleList(BuildContext context, List<LiveEpgItem> items) {
    // Separa programa no ar dos futuros
    LiveEpgItem? currentProgram;
    final upcomingPrograms = <LiveEpgItem>[];

    for (final item in items) {
      if (item.isNow && currentProgram == null) {
        currentProgram = item;
      } else {
        upcomingPrograms.add(item);
      }
    }

    // Se nenhum item foi detectado como isNow, o primeiro pode ser o atual
    if (currentProgram == null && items.isNotEmpty) {
      currentProgram = items.first;
      upcomingPrograms.removeAt(0);
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Programa Atual (NO AR)
        if (currentProgram != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentPrimary, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPrimary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const HankoBadge(
                      text: 'NO AR AGORA',
                      borderColor: AppColors.statusLive,
                      textColor: AppColors.statusLive,
                    ),
                    const Spacer(),
                    Text(
                      currentProgram.timeFormatted,
                      style: AppTypography.mono(
                        fontSize: 11,
                        color: AppColors.accentCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currentProgram.title.toUpperCase(),
                  style: AppTypography.titleMedium(fontSize: 15, color: Colors.white),
                ),
                if (currentProgram.description != null &&
                    currentProgram.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    currentProgram.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 10),
                // Barra de Progresso do Programa
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: currentProgram.progress,
                    minHeight: 4,
                    backgroundColor: AppColors.borderHairline,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(currentProgram.progress * 100).toInt()}% DECORRIDO',
                      style: AppTypography.mono(fontSize: 9, color: AppColors.textMuted),
                    ),
                    if (currentProgram.remainingMinutes > 0)
                      Text(
                        'RESTAM ${currentProgram.remainingMinutes} MIN',
                        style: AppTypography.mono(fontSize: 9, color: AppColors.accentCyan),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Próximos Programas
        if (upcomingPrograms.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              context.tr('player.up_next'),
              style: AppTypography.mono(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...upcomingPrograms.map((epg) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHover,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      epg.timeFormatted,
                      style: AppTypography.mono(
                        fontSize: 10,
                        color: AppColors.accentCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          epg.title,
                          style: AppTypography.body(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (epg.description != null && epg.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            epg.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final String title;
  final bool isSelected;
  final bool isAll;
  final VoidCallback onSelect;

  const _CategoryTile({
    required this.title,
    required this.isSelected,
    required this.isAll,
    required this.onSelect,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (f) {
        setState(() => _isFocused = f);
        if (f) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 150),
          );
        }
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onSelect(),
        ),
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: InkWell(
        canRequestFocus: false,
        onTap: widget.onSelect,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isFocused
                ? AppColors.surfaceHover
                : (widget.isSelected
                    ? AppColors.accentPrimary.withValues(alpha: 0.16)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused
                  ? AppColors.accentCyan
                  : (widget.isSelected ? AppColors.accentPrimary : Colors.transparent),
              width: _isFocused ? 1.6 : 1.2,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.accentCyan.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.isAll ? Icons.grid_view_rounded : Icons.folder_open_rounded,
                size: 16,
                color: _isFocused
                    ? AppColors.accentCyan
                    : (widget.isSelected ? AppColors.accentPrimary : AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    color: _isFocused || widget.isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 12,
                  ).copyWith(
                    fontWeight: _isFocused || widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (_isFocused || widget.isSelected)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: _isFocused ? AppColors.accentCyan : AppColors.accentPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveChannelTile extends StatefulWidget {
  final LiveStreamItem channel;
  final bool isCurrentlyPlaying;
  final bool isPreviewing;
  final bool autofocus;
  final VoidCallback onTune;
  final VoidCallback onPreview;
  final VoidCallback? onBackToCategories;

  const _LiveChannelTile({
    required this.channel,
    required this.isCurrentlyPlaying,
    required this.isPreviewing,
    this.autofocus = false,
    required this.onTune,
    required this.onPreview,
    this.onBackToCategories,
  });

  @override
  State<_LiveChannelTile> createState() => _LiveChannelTileState();
}

class _LiveChannelTileState extends State<_LiveChannelTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: widget.autofocus,
      onFocusChange: (f) {
        setState(() => _isFocused = f);
        if (f) {
          widget.onPreview();
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 150),
          );
        }
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onTune(),
        ),
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft && widget.onBackToCategories != null) {
              widget.onBackToCategories!();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: InkWell(
          canRequestFocus: false,
          onTap: () {
            widget.onPreview();
            widget.onTune();
          },
          onDoubleTap: widget.onTune,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _isFocused
                  ? AppColors.surfaceHover
                  : (widget.isPreviewing
                      ? AppColors.surfaceHover.withValues(alpha: 0.5)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isFocused
                    ? AppColors.accentCyan
                    : (widget.isCurrentlyPlaying
                        ? AppColors.statusLive
                        : (widget.isPreviewing
                            ? AppColors.accentPrimary
                            : Colors.transparent)),
                width: _isFocused ? 1.6 : (widget.isCurrentlyPlaying ? 1.5 : 1.0),
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
              children: [
                // Logo do canal ou Fallback
                Container(
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isFocused
                          ? AppColors.accentCyan.withValues(alpha: 0.5)
                          : AppColors.borderHairline,
                    ),
                  ),
                  child: widget.channel.streamIcon != null &&
                          widget.channel.streamIcon!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.channel.streamIcon!,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.live_tv_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        )
                      : const Icon(
                          Icons.live_tv_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                ),
                const SizedBox(width: 10),

                // Informações do canal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.channel.formattedNumber,
                            style: AppTypography.mono(
                              fontSize: 10,
                              color: AppColors.accentCyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (widget.isCurrentlyPlaying)
                            const HankoBadge(
                              text: 'NO AR',
                              borderColor: AppColors.statusLive,
                              textColor: AppColors.statusLive,
                            ),
                          if (widget.channel.hasEpg) ...[
                            const SizedBox(width: 4),
                            Text(
                              '[ EPG ]',
                              style: AppTypography.mono(
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          color: widget.isCurrentlyPlaying
                              ? AppColors.statusLive
                              : (_isFocused ? Colors.white : AppColors.textPrimary),
                          fontSize: 12,
                        ).copyWith(
                          fontWeight: _isFocused ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botão lateral para abrir EPG (não concorre no foco de travessia do D-pad)
                Focus(
                  canRequestFocus: false,
                  descendantsAreFocusable: false,
                  child: IconButton(
                    tooltip: 'Ver Programação (EPG)',
                    icon: const Icon(
                      Icons.event_note_rounded,
                      size: 18,
                      color: AppColors.accentCyan,
                    ),
                    onPressed: widget.onPreview,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
