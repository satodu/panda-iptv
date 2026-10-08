import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/storage/favorite_item.dart';
import '../../../core/storage/favorites_service.dart';
import '../../../core/storage/recent_channels_service.dart';
import '../../../core/storage/watch_history_service.dart';
import '../../../core/storage/watched_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hanko_badge.dart';
import '../../../core/widgets/hanko_loader.dart';
import '../../../core/widgets/tech_crosses.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../live/models/live_stream_item.dart';
import '../../live/presentation/live_provider.dart';
import '../../series/presentation/series_provider.dart';
import '../models/playlist_item.dart';
import 'live_channel_epg_panel.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String streamUrl;
  final String? mediaId;
  final String? cover;
  final int? initialPositionMs;
  final String mediaType; // 'movie' or 'series'
  final List<PlaylistItem>? playlist;
  final int initialPlaylistIndex;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.streamUrl,
    this.mediaId,
    this.cover,
    this.initialPositionMs,
    this.mediaType = 'movie',
    this.playlist,
    this.initialPlaylistIndex = 0,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final Player _player;
  late final VideoController _controller;

  late int _currentIndex;
  late String _currentTitle;
  late String? _currentSubtitle;
  late String _currentStreamUrl;
  late String? _currentMediaId;
  late String? _currentCover;
  late String _currentMediaType;

  bool _isWatched = false;
  bool _showNextCountdown = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;

  bool _showControls = true;
  Timer? _hideTimer;
  Timer? _hudTimer;
  Timer? _saveProgressTimer;
  String? _hudMessage;

  bool _isPlaying = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = true;
  String? _errorMessage;

  Duration? _pendingResumePosition;
  bool _hasResumed = false;
  bool _isSeekingToResume = false;

  static const String _volumePrefKey = 'panda_player_last_volume';
  static double _lastSavedVolume = 100.0;
  static bool _volumePrefLoaded = false;

  double _volume = 100.0;
  double _lastVolume = 100.0;
  String _hwdecMode = 'no';

  bool _isSilencedForResume = false;
  double _volumeToRestore = 100.0;
  BoxFit _videoFit = BoxFit.contain;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _playSub;
  StreamSubscription? _bufSub;
  StreamSubscription? _errSub;
  StreamSubscription? _volSub;
  StreamSubscription? _compSub;
  bool _isDisposed = false;

  void _safeSetState(VoidCallback fn) {
    if (_isDisposed || !mounted) return;
    try {
      setState(fn);
    } catch (_) {
      // Evita exceção caso o elemento tenha entrado em defunct durante o processamento de microtasks
    }
  }

  final FocusNode _rootFocusNode = FocusNode(debugLabel: 'PlayerRoot');
  final FocusNode _playPauseFocusNode = FocusNode(debugLabel: 'PlayerPlayPause');
  final FocusNode _sliderFocusNode = FocusNode(debugLabel: 'PlayerSlider');

  // Double-tap seeking on touch screens
  int _doubleTapSeekAccumulated = 0;
  bool _showLeftDoubleTap = false;
  bool _showRightDoubleTap = false;
  Timer? _doubleTapTimer;

  // Hold-to-seek (long press fast forward / rewind on TV remote)
  LogicalKeyboardKey? _seekKeyPressed;
  Timer? _holdSeekTimer;
  Timer? _holdSeekTickTimer;
  bool _isHoldingSeek = false;
  int _holdSeekDirection = 0;
  Duration _holdSeekTarget = Duration.zero;
  int _holdSeekElapsedTicks = 0;

  // Menu / Gaveta lateral de seleção de episódios
  bool _showEpisodesPanel = false;
  final ScrollController _episodesScrollController = ScrollController();
  late final AnimationController _episodesPanelController;
  late final Animation<Offset> _episodesSlideAnimation;
  late final Animation<double> _episodesFadeAnimation;

  // Menu / Painel em cascata de canais e guia EPG para Live Stream
  bool _showLiveEpgPanel = false;

  List<PlaylistItem>? _playlist;

  bool get hasNextEpisode =>
      _playlist != null && _currentIndex < _playlist!.length - 1;
  bool get hasPreviousEpisode =>
      _playlist != null && _currentIndex > 0;

  @override
  void initState() {
    super.initState();

    _volume = _lastSavedVolume;
    _lastVolume = _lastSavedVolume > 0 ? _lastSavedVolume : 100.0;

    // No Android / Mobile: Força orientação horizontal (landscape) e tela cheia imersiva (sem barra de status/topo)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Inicialização da animação suave de slide para o menu de episódios
    _episodesPanelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _episodesSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _episodesPanelController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _episodesFadeAnimation = CurvedAnimation(
      parent: _episodesPanelController,
      curve: Curves.easeOut,
    );

    _playlist = widget.playlist;
    final isSeriesMedia = widget.mediaType == 'series' || (widget.mediaId?.startsWith('series_') ?? false);
    if (_playlist == null && isSeriesMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSeriesPlaylistIfNeeded();
      });
    }

    _currentIndex = widget.initialPlaylistIndex;
    if (_playlist != null &&
        _playlist!.isNotEmpty &&
        _currentIndex >= 0 &&
        _currentIndex < _playlist!.length) {
      final item = _playlist![_currentIndex];
      _currentTitle = item.title;
      _currentSubtitle = item.subtitle;
      _currentStreamUrl = item.streamUrl;
      _currentMediaId = item.id;
      _currentCover = item.cover;
      _currentMediaType = item.mediaType;
    } else {
      _currentTitle = widget.title;
      _currentSubtitle = widget.subtitle;
      _currentStreamUrl = widget.streamUrl;
      _currentMediaId = widget.mediaId;
      _currentCover = widget.cover;
      _currentMediaType = (widget.mediaId?.startsWith('series_') ?? false)
          ? 'series'
          : widget.mediaType;
    }

    if (_currentMediaId != null && _currentMediaType != 'live') {
      _isWatched = WatchedService.isWatchedSync(_currentMediaId!);
    }

    if (_currentMediaType == 'live') {
      RecentChannelsService.recordChannelWatched(
        streamId: int.tryParse(_currentMediaId ?? '') ?? 0,
        name: _currentTitle,
        streamIcon: _currentCover,
        categoryName: _currentSubtitle,
        streamUrl: _currentStreamUrl,
      );
    }

    _player = Player(
      configuration: const PlayerConfiguration(
        logLevel: MPVLogLevel.warn,
      ),
    );
    _player.setVolume(_lastSavedVolume);
    _loadSavedVolume();

    _controller = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: false,
        hwdec: 'no',
      ),
    );

    _posSub = _player.stream.position.listen((pos) {
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _position = pos;
          if (pos > Duration.zero) {
            _isBuffering = false;
          }
        });

        _checkAndApplyResume();

        // Marca automaticamente como visto se assistiu mais de 90%
        if (_duration.inSeconds > 30 && _currentMediaType != 'live') {
          final ratio = _position.inSeconds / _duration.inSeconds;
          if (ratio >= 0.90 && !_isWatched && _currentMediaId != null) {
            WatchedService.markAsWatched(_currentMediaId!);
            _safeSetState(() => _isWatched = true);
          }

          // Se faltam <= 15s para o fim e há próximo episódio, aciona contagem regressiva
          if (_duration.inSeconds - _position.inSeconds <= 15 &&
              !_showNextCountdown &&
              hasNextEpisode &&
              _isPlaying) {
            _triggerNextEpisodeCountdown();
          }
        }
      }
    });

    _durSub = _player.stream.duration.listen((dur) {
      if (!_isDisposed && mounted) {
        _safeSetState(() => _duration = dur);
        _checkAndApplyResume();
      }
    });

    _playSub = _player.stream.playing.listen((playing) {
      if (!_isDisposed && mounted) {
        _safeSetState(() => _isPlaying = playing);
      }
    });

    _bufSub = _player.stream.buffering.listen((buffering) {
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          if (_position == Duration.zero) {
            _isBuffering = buffering;
          } else {
            _isBuffering = buffering && !_isPlaying;
          }
        });
      }
    });

    _volSub = _player.stream.volume.listen((vol) {
      if (!_isDisposed && mounted && !_isSilencedForResume) {
        _safeSetState(() => _volume = vol.clamp(0.0, 100.0));
      }
    });

    _errSub = _player.stream.error.listen((err) {
      debugPrint('[PANDA MPV ERROR] $err');
      final errLower = err.toLowerCase();
      // Ignora avisos informativos / não fatais de demuxer e seek do MPV (especialmente em transmissões ao vivo)
      if (errLower.contains('force-seekable') ||
          errLower.contains('cannot seek') ||
          errLower.contains('demuxer-seekable-cache') ||
          errLower.contains('seekable')) {
        return;
      }
      if (!_isDisposed && mounted) {
        if (_isPlaying) {
          return;
        }
        _safeSetState(() => _errorMessage = 'Erro ao carregar transmissão: $err');
      }
    });

    _compSub = _player.stream.completed.listen((completed) {
      if (completed && !_isDisposed && mounted) {
        if (_currentMediaId != null && _currentMediaType != 'live') {
          WatchedService.markAsWatched(_currentMediaId!);
          _safeSetState(() => _isWatched = true);
        }
        if (hasNextEpisode) {
          _triggerNextEpisodeCountdown();
        }
      }
    });

    _initAndPlay();
    _startHideTimer();

    WidgetsBinding.instance.addObserver(this);

    _saveProgressTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _isPlaying) {
        _saveCurrentProgress();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveCurrentProgress();
    }
  }

  void _saveCurrentProgress() {
    if (_currentMediaType == 'live') return;
    // Não salvar enquanto o ponto de retomada ainda estiver pendente de validação
    if (_pendingResumePosition != null && !_hasResumed) return;

    // Pega a posição mais recente do player caso disponível ou do estado _position
    final currentPos = _player.state.position > Duration.zero
        ? _player.state.position
        : _position;
    final currentDur = _player.state.duration > Duration.zero
        ? _player.state.duration
        : _duration;

    final pos = currentPos.inMilliseconds;
    final dur = currentDur.inMilliseconds;
    if (pos > 5000 && dur > 0) {
      WatchHistoryService.saveProgress(
        id: _currentMediaId ?? _currentStreamUrl,
        title: _currentTitle,
        subtitle: _currentSubtitle,
        streamUrl: _currentStreamUrl,
        cover: _currentCover,
        positionMs: pos,
        durationMs: dur,
        type: _currentMediaType,
      );
    }
  }

  Future<void> _checkAndApplyResume() async {
    if (_currentMediaType == 'live') return;
    if (_pendingResumePosition == null || _hasResumed || _isSeekingToResume) return;

    // Aguarda o player reportar duração válida e começar a reproduzir/emitir posição (> 0)
    if (_duration > Duration.zero && _position > Duration.zero) {
      _isSeekingToResume = true;
      final target = _pendingResumePosition!;

      try {
        await _player.seek(target);
        if (!_isDisposed && mounted) {
          _isSilencedForResume = false;
          _player.setVolume(_volumeToRestore);
          _safeSetState(() {
            _volume = _volumeToRestore;
            _hasResumed = true;
            _pendingResumePosition = null;
            _position = target;
            _isBuffering = false;
          });
          _showHud('${context.tr('player.resuming')} [ ${_formatDuration(target)} ]');
        }
      } catch (e) {
        debugPrint('[RESUME SEEK ERROR] $e');
        if (!_isDisposed && mounted) {
          _isSilencedForResume = false;
          _player.setVolume(_volumeToRestore);
          _safeSetState(() {
            _volume = _volumeToRestore;
            _hasResumed = true;
            _pendingResumePosition = null;
          });
        }
      } finally {
        _isSeekingToResume = false;
      }
    }
  }

  Future<void> _initAndPlay({String? streamUrl, int? startPositionMs}) async {
    final pos = _currentMediaType == 'live'
        ? null
        : (startPositionMs ?? (streamUrl == null ? widget.initialPositionMs : null));
    if (pos != null && pos > 3000) {
      _pendingResumePosition = Duration(milliseconds: pos);
      _hasResumed = false;
      _isSeekingToResume = false;
      _volumeToRestore = _volume > 0 ? _volume : (_lastVolume > 0 ? _lastVolume : 100.0);
      _isSilencedForResume = true;
      // Silencia momentaneamente o volume para evitar tocar som do início antes de posicionar no ponto de retomada
      try {
        _player.setVolume(0);
      } catch (_) {}

      // Timeout de segurança: se após 6 segundos não conseguir dar seek, retoma normal para não travar
      Timer(const Duration(seconds: 6), () {
        if (mounted && !_hasResumed) {
          _isSilencedForResume = false;
          _player.setVolume(_volumeToRestore);
          setState(() {
            _volume = _volumeToRestore;
            _hasResumed = true;
            _pendingResumePosition = null;
          });
        }
      });
    } else {
      _isSilencedForResume = false;
      _pendingResumePosition = null;
      _hasResumed = true;
      _isSeekingToResume = false;
    }

    final url = streamUrl ?? _currentStreamUrl;
    try {
      final platform = _player.platform;
      if (!kIsWeb && platform is NativePlayer) {
        final p = platform as dynamic;
        await p.setProperty('hwdec', _hwdecMode);
        await p.setProperty('user-agent', 'IPTVSmartersPro/3.1.5 (Linux; Android 12)');
        await p.setProperty('cache', 'yes');
        await p.setProperty('force-seekable', 'yes');
        if (_currentMediaType == 'live') {
          await p.setProperty('demuxer-seekable-cache', 'no');
        } else {
          await p.setProperty('demuxer-seekable-cache', 'yes');
        }
        await p.setProperty('demuxer-max-bytes', '67108864'); // 64 MB
        await p.setProperty('demuxer-max-back-bytes', '33554432'); // 32 MB
        await p.setProperty('hr-seek', 'yes');
      }
    } catch (_) {}

    await _player.open(
      Media(
        url,
        // NÃO passamos start: aqui para evitar que o demuxer HTTP no Android libmpv aborte o handshake inicial
        httpHeaders: const {
          'User-Agent': 'IPTVSmartersPro/3.1.5 (Linux; Android 12)',
          'Accept': '*/*',
          'Connection': 'keep-alive',
        },
      ),
    );
  }

  void _playNextEpisode() {
    if (!hasNextEpisode) return;
    _playEpisodeIndex(_currentIndex + 1);
  }

  void _playPreviousEpisode() {
    if (!hasPreviousEpisode) return;
    _playEpisodeIndex(_currentIndex - 1);
  }

  void _loadSeriesPlaylistIfNeeded() async {
    if (_playlist != null && _playlist!.isNotEmpty) return;
    final isSeries = _currentMediaType == 'series' ||
        widget.mediaType == 'series' ||
        (_currentMediaId?.startsWith('series_') ?? false) ||
        (widget.mediaId?.startsWith('series_') ?? false);
    if (!isSeries) return;

    int? sId;
    String? epId;

    final mediaIdToUse = _currentMediaId ?? widget.mediaId;
    if (mediaIdToUse != null && mediaIdToUse.startsWith('series_')) {
      final parts = mediaIdToUse.split('_');
      if (parts.length >= 3) {
        sId = int.tryParse(parts[1]);
        epId = parts.sublist(2).join('_');
      }
    }

    try {
      final account = context.read<AuthProvider>().currentAccount;
      if (account == null) return;
      final seriesProv = context.read<SeriesProvider>();

      if (sId == null) {
        final match = seriesProv.seriesList.where(
          (s) => s.name.trim().toLowerCase() == _currentTitle.trim().toLowerCase(),
        ).firstOrNull;
        if (match != null) {
          sId = match.seriesId;
        }
      }
      if (sId == null) return;

      if (epId == null) {
        final reg = RegExp(r'/series/[^/]+/[^/]+/(\d+)\.');
        final m = reg.firstMatch(_currentStreamUrl);
        if (m != null) {
          epId = m.group(1);
        }
      }

      final detail = await seriesProv.loadSeriesDetail(account, sId);
      if (detail == null || detail.episodesBySeason.isEmpty || !mounted) return;

      String? matchedSeason;
      if (epId != null) {
        for (final entry in detail.episodesBySeason.entries) {
          if (entry.value.any((ep) => ep.id.toString().trim() == epId!.trim())) {
            matchedSeason = entry.key;
            break;
          }
        }
      }
      matchedSeason ??= detail.seasonNumbers.isNotEmpty
          ? detail.seasonNumbers.first
          : (detail.episodesBySeason.keys.isNotEmpty ? detail.episodesBySeason.keys.first : '1');

      final episodes = detail.episodesBySeason[matchedSeason] ?? [];
      if (episodes.isEmpty || !mounted) return;

      final generatedPlaylist = episodes.map((ep) {
        final url = seriesProv.buildStreamUrl(account, ep.id, ep.containerExtension);
        return PlaylistItem(
          id: 'series_${sId}_${ep.id}',
          title: _currentTitle,
          subtitle: 'TEMP $matchedSeason // EP ${ep.episodeNum} - ${ep.title}',
          streamUrl: url,
          cover: ep.image ?? detail.cover ?? _currentCover,
          mediaType: 'series',
        );
      }).toList();

      final idx = epId != null
          ? episodes.indexWhere((ep) => ep.id.toString().trim() == epId!.trim())
          : 0;

      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _playlist = generatedPlaylist;
          if (idx >= 0) _currentIndex = idx;
        });
      }
    } catch (_) {
      // Falha silenciosa caso não consiga sincronizar episódios
    }
  }

  void _playEpisodeIndex(int index) async {
    if (_playlist == null || index < 0 || index >= _playlist!.length) return;
    _cancelNextCountdown();

    if (_currentMediaId != null) {
      WatchedService.markAsWatched(_currentMediaId!);
    }
    _saveCurrentProgress();

    final nextItem = _playlist![index];
    setState(() {
      _currentIndex = index;
      _currentTitle = nextItem.title;
      _currentSubtitle = nextItem.subtitle;
      _currentStreamUrl = nextItem.streamUrl;
      _currentMediaId = nextItem.id;
      _currentCover = nextItem.cover;
      _currentMediaType = nextItem.mediaType;
      _isBuffering = true;
      _position = Duration.zero;
      _duration = Duration.zero;
      _isWatched = WatchedService.isWatchedSync(nextItem.id);
    });

    if (nextItem.mediaType == 'live') {
      RecentChannelsService.recordChannelWatched(
        streamId: int.tryParse(nextItem.id) ?? 0,
        name: nextItem.title,
        streamIcon: nextItem.cover,
        categoryName: nextItem.subtitle,
        streamUrl: nextItem.streamUrl,
      );
    }

    _showHud('CARREGANDO: ${nextItem.subtitle ?? nextItem.title}');
    await _initAndPlay(streamUrl: nextItem.streamUrl);
  }

  void _openEpisodesPanel() {
    if (_playlist == null || _playlist!.isEmpty) return;
    setState(() {
      _showEpisodesPanel = true;
      _hideTimer?.cancel();
    });
    _episodesPanelController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_episodesScrollController.hasClients && _currentIndex > 0) {
        final targetOffset = (_currentIndex * 68.0).clamp(
          0.0,
          _episodesScrollController.position.maxScrollExtent,
        );
        _episodesScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _closeEpisodesPanel() {
    if (!_showEpisodesPanel) return;
    _episodesPanelController.reverse().then((_) {
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _showEpisodesPanel = false;
          _startHideTimer();
        });
      }
    });
  }

  void _toggleEpisodesPanel() {
    if (_showEpisodesPanel) {
      _closeEpisodesPanel();
    } else {
      _openEpisodesPanel();
    }
  }

  void _openLiveEpgPanel() {
    _safeSetState(() {
      _showLiveEpgPanel = true;
      _hideTimer?.cancel();
    });
  }

  void _closeLiveEpgPanel() {
    if (!_showLiveEpgPanel) return;
    _safeSetState(() {
      _showLiveEpgPanel = false;
      _startHideTimer();
    });
  }

  void _toggleLiveEpgPanel() {
    if (_showLiveEpgPanel) {
      _closeLiveEpgPanel();
    } else {
      _openLiveEpgPanel();
    }
  }

  void _switchLiveChannel(LiveStreamItem channel) async {
    final authProv = context.read<AuthProvider>();
    final liveProv = context.read<LiveProvider>();
    final account = authProv.currentAccount;
    if (account == null) return;

    final newUrl = liveProv.buildStreamUrl(account, channel.streamId);

    // Registra no histórico de recentes
    RecentChannelsService.recordChannelWatched(
      streamId: channel.streamId,
      name: channel.name,
      streamIcon: channel.streamIcon,
      categoryName: channel.categoryName,
      channelNumber: channel.formattedNumber,
      streamUrl: newUrl,
    );

    // Se temos playlist de canais, atualiza o índice
    if (_playlist != null && _playlist!.isNotEmpty) {
      final foundIdx = _playlist!.indexWhere((item) => item.id == channel.streamId.toString());
      if (foundIdx >= 0) {
        _currentIndex = foundIdx;
      }
    }

    _safeSetState(() {
      _currentTitle = channel.name;
      _currentSubtitle = channel.categoryName ?? '${channel.formattedNumber} // AO VIVO';
      _currentStreamUrl = newUrl;
      _currentMediaId = channel.streamId.toString();
      _currentCover = channel.streamIcon;
      _currentMediaType = 'live';
      _isBuffering = true;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    _showHud('SINTONIZANDO: ${channel.formattedNumber} - ${channel.name.toUpperCase()}');
    await _initAndPlay(streamUrl: newUrl);
  }

  void _triggerNextEpisodeCountdown() {
    if (_showNextCountdown || !hasNextEpisode) return;
    _safeSetState(() {
      _showNextCountdown = true;
      _countdownSeconds = 6;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        timer.cancel();
        _playNextEpisode();
      } else {
        _safeSetState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  void _cancelNextCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_showNextCountdown && !_isDisposed && mounted) {
      _safeSetState(() => _showNextCountdown = false);
    }
  }

  void _toggleWatched() async {
    if (_currentMediaId == null) return;
    final isNowWatched = await WatchedService.toggleWatched(_currentMediaId!);
    if (!_isDisposed && mounted) {
      _safeSetState(() => _isWatched = isNowWatched);
      _showHud(isNowWatched ? 'MARCADO COMO VISTO.' : 'DESMARCADO COMO VISTO.');
    }
  }

  Future<void> _toggleHwdec() async {
    final nextMode = _hwdecMode == 'no' ? 'auto-copy' : _hwdecMode == 'auto-copy' ? 'auto' : 'no';
    setState(() => _hwdecMode = nextMode);

    try {
      final platform = _player.platform;
      if (!kIsWeb && platform is NativePlayer) {
        await (platform as dynamic).setProperty('hwdec', nextMode);
      }
    } catch (_) {}

    final label = nextMode == 'no' ? 'SOFTWARE (SEGURO)' : nextMode.toUpperCase();
    _showHud('DECODER: $label');
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!_isDisposed && mounted && _isPlaying) {
        _safeSetState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    _safeSetState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed && mounted && _showControls) {
          _playPauseFocusNode.requestFocus();
        }
      });
    }
  }

  void _revealControls() {
    if (!_showControls) {
      _safeSetState(() => _showControls = true);
    }
    _startHideTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted && _showControls) {
        _playPauseFocusNode.requestFocus();
      }
    });
  }

  void _onDoubleTapDown(TapDownDetails details) {
    final width = MediaQuery.of(context).size.width;
    final x = details.globalPosition.dx;
    if (x < width * 0.4) {
      _handleDoubleTapSeek(isForward: false);
    } else if (x > width * 0.6) {
      _handleDoubleTapSeek(isForward: true);
    } else {
      _togglePlayPause();
    }
  }

  void _handleDoubleTapSeek({required bool isForward}) {
    if (_currentMediaType == 'live') return;
    _doubleTapTimer?.cancel();
    final delta = isForward ? 10 : -10;
    if (isForward && _doubleTapSeekAccumulated < 0) {
      _doubleTapSeekAccumulated = 0;
    } else if (!isForward && _doubleTapSeekAccumulated > 0) {
      _doubleTapSeekAccumulated = 0;
    }
    _doubleTapSeekAccumulated += delta;

    _safeSetState(() {
      _showLeftDoubleTap = !isForward;
      _showRightDoubleTap = isForward;
    });

    final targetMs = (_position.inMilliseconds + (delta * 1000))
        .clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 0);
    final target = Duration(milliseconds: targetMs);
    _seekTo(target);

    _doubleTapTimer = Timer(const Duration(milliseconds: 650), () {
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _showLeftDoubleTap = false;
          _showRightDoubleTap = false;
          _doubleTapSeekAccumulated = 0;
        });
      }
    });
  }

  void _startHoldSeek(bool isForward) {
    if (_currentMediaType == 'live') return;
    _holdSeekTimer?.cancel();
    _holdSeekTickTimer?.cancel();
    _isHoldingSeek = false;
    _holdSeekDirection = isForward ? 1 : -1;
    _holdSeekTarget = _position;
    _holdSeekElapsedTicks = 0;

    _holdSeekTimer = Timer(const Duration(milliseconds: 320), () {
      if (_isDisposed || !mounted) return;
      _isHoldingSeek = true;
      _holdSeekTickTimer = Timer.periodic(const Duration(milliseconds: 140), (timer) {
        if (_isDisposed || !mounted) {
          timer.cancel();
          return;
        }
        _holdSeekElapsedTicks++;
        final stepSeconds = _holdSeekElapsedTicks < 6
            ? 15
            : _holdSeekElapsedTicks < 15
                ? 35
                : 70;

        final newTargetMs = (_holdSeekTarget.inMilliseconds + (_holdSeekDirection * stepSeconds * 1000))
            .clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 0);
        _holdSeekTarget = Duration(milliseconds: newTargetMs);

        _safeSetState(() {
          _position = _holdSeekTarget;
        });

        final icon = _holdSeekDirection > 0 ? '⏩' : '⏪';
        final speed = _holdSeekElapsedTicks < 6 ? '1x' : _holdSeekElapsedTicks < 15 ? '2x' : '4x';
        _showHud('$icon AVANÇO RÁPIDO ($speed) [ ${_formatDuration(_holdSeekTarget)} ]');
      });
    });
  }

  void _finishHoldSeek() {
    _holdSeekTimer?.cancel();
    _holdSeekTimer = null;

    if (_isHoldingSeek) {
      _holdSeekTickTimer?.cancel();
      _holdSeekTickTimer = null;
      _isHoldingSeek = false;
      _seekTo(_holdSeekTarget);
      _showHud('${_holdSeekDirection > 0 ? "⏩" : "⏪"} [ ${_formatDuration(_holdSeekTarget)} ]');
    } else {
      final deltaSeconds = _holdSeekDirection > 0 ? 10 : -10;
      final newPosMs = (_position.inMilliseconds + (deltaSeconds * 1000))
          .clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 0);
      final newPos = Duration(milliseconds: newPosMs);
      _seekTo(newPos);
      _showHud('${_holdSeekDirection > 0 ? "+10s" : "-10s"} [ ${_formatDuration(newPos)} ]');
    }
  }

  KeyEventResult _handleRootKeyEvent(FocusNode node, KeyEvent event) {
    _startHideTimer();

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final key = event.logicalKey;

      if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.backspace) {
        if (_showLiveEpgPanel) {
          _closeLiveEpgPanel();
          return KeyEventResult.handled;
        }
        if (_showEpisodesPanel) {
          _closeEpisodesPanel();
          return KeyEventResult.handled;
        }
        if (_showControls) {
          _safeSetState(() => _showControls = false);
          return KeyEventResult.handled;
        } else {
          _stopPlaybackAndPop();
          return KeyEventResult.handled;
        }
      }

      if (key == LogicalKeyboardKey.keyG || key == LogicalKeyboardKey.keyC) {
        if (_currentMediaType == 'live') {
          _toggleLiveEpgPanel();
          return KeyEventResult.handled;
        }
      }

      if (key == LogicalKeyboardKey.keyE) {
        if (_playlist != null && _playlist!.length > 1 && _currentMediaType == 'series') {
          _toggleEpisodesPanel();
          return KeyEventResult.handled;
        }
      }

      if (!_showControls) {
        if (_currentMediaType == 'live' &&
            (key == LogicalKeyboardKey.arrowLeft ||
             key == LogicalKeyboardKey.arrowRight)) {
          _openLiveEpgPanel();
          return KeyEventResult.handled;
        }

        if (key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.gameButtonA ||
            key == LogicalKeyboardKey.mediaPlayPause) {
          _revealControls();
          return KeyEventResult.handled;
        }
      }

      if (key == LogicalKeyboardKey.mediaPlay) {
        _playPlayback();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.mediaPause) {
        _pausePlayback();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.keyA || key == LogicalKeyboardKey.keyF) {
        _toggleVideoFit();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.keyD) {
        _toggleHwdec();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.keyM) {
        _toggleMute();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.keyN || key == LogicalKeyboardKey.mediaTrackNext) {
        if (hasNextEpisode) {
          _playNextEpisode();
          return KeyEventResult.handled;
        }
      } else if (key == LogicalKeyboardKey.keyP || key == LogicalKeyboardKey.mediaTrackPrevious) {
        if (hasPreviousEpisode) {
          _playPreviousEpisode();
          return KeyEventResult.handled;
        }
      }

      final isSeekKey = key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.mediaFastForward ||
          key == LogicalKeyboardKey.mediaRewind;

      if (isSeekKey) {
        if (_currentMediaType == 'live') {
          return KeyEventResult.ignored;
        }
        final isMediaSeek = key == LogicalKeyboardKey.mediaFastForward || key == LogicalKeyboardKey.mediaRewind;
        final isNavigatingButtons = _showControls && !_sliderFocusNode.hasFocus && !isMediaSeek;

        if (!isNavigatingButtons) {
          if (event is KeyDownEvent && _seekKeyPressed != key) {
            _seekKeyPressed = key;
            final isForward = key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.mediaFastForward;
            _startHoldSeek(isForward);
          }
          return KeyEventResult.handled;
        }
      }
    } else if (event is KeyUpEvent) {
      if (_seekKeyPressed == event.logicalKey) {
        _finishHoldSeek();
        _seekKeyPressed = null;
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  Future<void> _loadSavedVolume() async {
    if (!_volumePrefLoaded) {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble(_volumePrefKey);
      if (saved != null) {
        _lastSavedVolume = saved.clamp(0.0, 100.0);
      }
      _volumePrefLoaded = true;
    }
    if (mounted) {
      _player.setVolume(_lastSavedVolume);
      setState(() {
        _volume = _lastSavedVolume;
        if (_lastSavedVolume > 0) _lastVolume = _lastSavedVolume;
      });
    }
  }

  void _toggleVideoFit() {
    setState(() {
      if (_videoFit == BoxFit.contain) {
        _videoFit = BoxFit.cover;
        _showHud('TELA: EXPANDIDO / ZOOM (SEM BORDAS)');
      } else if (_videoFit == BoxFit.cover) {
        _videoFit = BoxFit.fill;
        _showHud('TELA: ESTICADO TOTAL');
      } else {
        _videoFit = BoxFit.contain;
        _showHud('TELA: ORIGINAL (16:9)');
      }
      _showControls = true;
    });
    _startHideTimer();
  }

  void _setVolume(double newVol) {
    final clamped = newVol.clamp(0.0, 100.0);
    _player.setVolume(clamped);
    setState(() {
      _volume = clamped;
      _showControls = true;
    });
    if (clamped > 0) {
      _lastVolume = clamped;
      _lastSavedVolume = clamped;
      SharedPreferences.getInstance().then((prefs) => prefs.setDouble(_volumePrefKey, clamped));
    }
    _showHud('VOLUME: ${clamped.toInt()}%');
    _startHideTimer();
  }

  void _toggleMute() {
    if (_volume > 0) {
      _lastVolume = _volume;
      _player.setVolume(0);
      setState(() {
        _volume = 0;
        _showControls = true;
      });
      _showHud(context.tr('player.muted'));
    } else {
      final restore = _lastVolume > 0 ? _lastVolume : 80.0;
      _setVolume(restore);
      _showHud(context.tr('player.unmuted'));
    }
  }

  void _showHud(String message) {
    _hudTimer?.cancel();
    _safeSetState(() => _hudMessage = message);
    _hudTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!_isDisposed && mounted) {
        _safeSetState(() => _hudMessage = null);
      }
    });
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _saveCurrentProgress();
      _player.pause();
      _showHud('PAUSADO.');
    } else {
      _player.play();
      _showHud('REPRODUZINDO.');
    }
    setState(() => _showControls = true);
    _startHideTimer();
  }

  void _pausePlayback() {
    _saveCurrentProgress();
    _player.pause();
    _showHud('PAUSADO.');
    setState(() => _showControls = true);
    _startHideTimer();
  }

  void _playPlayback() {
    _player.play();
    _showHud('REPRODUZINDO.');
    setState(() => _showControls = true);
    _startHideTimer();
  }

  void _seekTo(Duration target) {
    if (_currentMediaType == 'live') return;
    final clampedMs = target.inMilliseconds.clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 0);
    final finalDuration = Duration(milliseconds: clampedMs);
    _player.seek(finalDuration);
    _position = finalDuration;
    _saveCurrentProgress();
    setState(() => _showControls = true);
    _startHideTimer();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _stopPlaybackAndPop() {
    _saveCurrentProgress();
    try {
      _player.pause();
      _player.stop();
    } catch (_) {}
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _isDisposed = true;

    // 1. Interrompe e descarta a reprodução de áudio e vídeo imediatamente
    try {
      _player.pause();
      _player.stop();
      _player.dispose();
    } catch (e) {
      debugPrint('[PLAYER DISPOSE ERROR] $e');
    }

    // 2. Cancela imediatamente todas as assinaturas de streams para evitar microtasks residuais
    try {
      _posSub?.cancel();
      _durSub?.cancel();
      _playSub?.cancel();
      _bufSub?.cancel();
      _volSub?.cancel();
      _errSub?.cancel();
      _compSub?.cancel();
    } catch (_) {}
    _posSub = null;
    _durSub = null;
    _playSub = null;
    _bufSub = null;
    _volSub = null;
    _errSub = null;
    _compSub = null;

    // 3. Cancela timers e salva o progresso final
    try {
      _cancelNextCountdown();
      _doubleTapTimer?.cancel();
      _holdSeekTimer?.cancel();
      _holdSeekTickTimer?.cancel();
      _saveProgressTimer?.cancel();
      _saveCurrentProgress();
      _hideTimer?.cancel();
      _hudTimer?.cancel();
    } catch (_) {}

    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}

    // 4. Para animações ativas antes do descarte para evitar exceção de ticker ativo
    try {
      _episodesPanelController.stop();
      _episodesPanelController.dispose();
    } catch (_) {}

    try {
      _episodesScrollController.dispose();
    } catch (_) {}

    try {
      _rootFocusNode.dispose();
      _playPauseFocusNode.dispose();
      _sliderFocusNode.dispose();
    } catch (_) {}

    // 5. Restaura a barra de status do sistema e todas as orientações permitidas ao sair do player
    try {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (_) {}

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedTitle = _currentTitle.toUpperCase().endsWith('.')
        ? _currentTitle.toUpperCase()
        : '${_currentTitle.toUpperCase()}.';

    final isNarrow = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: !_showEpisodesPanel && !_showLiveEpgPanel,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_showLiveEpgPanel) {
            _closeLiveEpgPanel();
            return;
          }
          if (_showEpisodesPanel) {
            _closeEpisodesPanel();
            return;
          }
        }
        _saveCurrentProgress();
        try {
          _player.pause();
          _player.stop();
        } catch (_) {}
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _rootFocusNode,
          autofocus: true,
          onKeyEvent: _handleRootKeyEvent,
          child: Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                if (pointerSignal.scrollDelta.dy < 0) {
                  _setVolume(_volume + 5);
                } else if (pointerSignal.scrollDelta.dy > 0) {
                  _setVolume(_volume - 5);
                }
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              onDoubleTapDown: _onDoubleTapDown,
              onDoubleTap: () {},
              child: Stack(
              children: [
                // Renderização do vídeo via MPV
                SizedBox.expand(
                  child: Video(
                    controller: _controller,
                    controls: NoVideoControls,
                    fill: Colors.black,
                    fit: _videoFit,
                  ),
                ),

                // Tela de Carregamento Inicial com Capa (Oriental Brutalism)
                if (_errorMessage == null && (_position == Duration.zero || !_hasResumed))
                  Positioned.fill(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Fundo com capa escurecida
                        if (_currentCover != null && _currentCover!.trim().isNotEmpty) ...[
                          CachedNetworkImage(
                            imageUrl: _currentCover!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const SizedBox(),
                          ),
                          Container(
                            color: Colors.black.withValues(alpha: 0.82),
                          ),
                        ] else
                          Container(
                            color: AppColors.canvas,
                          ),

                        // Overlay central com poster e indicador de carregamento
                        Center(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_currentCover != null && _currentCover!.trim().isNotEmpty) ...[
                                    Container(
                                      width: isNarrow ? 100 : 130,
                                      height: isNarrow ? 145 : 190,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.accentPrimary.withValues(alpha: 0.7),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.85),
                                            blurRadius: 24,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(7),
                                        child: CachedNetworkImage(
                                          imageUrl: _currentCover!,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                            color: AppColors.surfaceCard,
                                            child: const Center(
                                              child: HankoLoader.mini(
                                                miniSize: 24,
                                                primaryColor: AppColors.accentPrimary,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (_, __, ___) => Container(
                                            color: AppColors.surfaceCard,
                                            child: const Icon(
                                              Icons.movie_outlined,
                                              color: AppColors.textDisabled,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  HankoLoader(
                                    label: _pendingResumePosition != null && !_hasResumed
                                        ? '${context.tr('player.resuming')} [ ${_formatDuration(_pendingResumePosition!)} ]'
                                        : context.tr('player.loading_label'),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    formattedTitle,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  if (_currentSubtitle != null && _currentSubtitle!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentSubtitle!.trim().toUpperCase(),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    _pendingResumePosition != null
                                        ? '${context.tr('player.resuming')} [ ${_formatDuration(_pendingResumePosition!)} ]'
                                        : context.tr('player.loading_stream'),
                                    style: const TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 10,
                                      color: AppColors.accentPrimary,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Indicador de buffering no meio do vídeo (após primeiro frame)
                if (_isBuffering && _errorMessage == null && _position > Duration.zero)
                  const Center(
                    child: HankoLoader(
                      label: 'BUFFERING.',
                      isCompact: true,
                    ),
                  ),

                // HUD de Notificação Rápida (Volume, Seek, Play/Pause, Retomada)
                // Posicionado no topo central para não cobrir o botão central de Play/Pause
                if (_hudMessage != null)
                  Positioned(
                    top: isNarrow ? 68 : 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accentPrimary, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            _hudMessage!,
                            style: AppTypography.mono(
                              fontSize: isNarrow ? 13 : 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Mensagem de Erro
                if (_errorMessage != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        border: Border.all(color: AppColors.statusError),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.statusError, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'FALHA NA REPRODUÇÃO.',
                            style: AppTypography.titleMedium(color: AppColors.statusError),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                                _isBuffering = true;
                              });
                              _initAndPlay();
                            },
                            child: Text('TENTAR NOVAMENTE.', style: AppTypography.button()),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Indicador visual de Double-Tap Seek Esquerdo (-10s)
                if (_showLeftDoubleTap)
                  Positioned(
                    left: 28,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accentPrimary, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fast_rewind_rounded, color: AppColors.accentPrimary, size: 24),
                              const SizedBox(height: 3),
                              Text(
                                '-${_doubleTapSeekAccumulated.abs()}s',
                                style: const TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Indicador visual de Double-Tap Seek Direito (+10s)
                if (_showRightDoubleTap)
                  Positioned(
                    right: 28,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accentPrimary, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fast_forward_rounded, color: AppColors.accentPrimary, size: 24),
                              const SizedBox(height: 3),
                              Text(
                                '+${_doubleTapSeekAccumulated.abs()}s',
                                style: const TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // OSD Minimalista Brutalista com controles completos e suporte nativo a TV D-Pad
                ExcludeFocus(
                  excluding: !_showControls,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xCC000000),
                              Colors.transparent,
                              Colors.transparent,
                              Color(0xEE000000),
                            ],
                            stops: [0.0, 0.25, 0.7, 1.0],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Bar Responsiva com Navegação D-pad
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isNarrow ? 12 : 20,
                                vertical: isNarrow ? 10 : 16,
                              ),
                              child: Row(
                                children: [
                                  _PlayerFocusButton(
                                    tooltip: 'Voltar',
                                    onFocused: _startHideTimer,
                                    onPressed: _stopPlaybackAndPop,
                                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          formattedTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.titleMedium(
                                            color: AppColors.textPrimary,
                                            fontSize: isNarrow ? 13 : 15,
                                          ),
                                        ),
                                        if (_currentSubtitle != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            _currentSubtitle!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.mono(
                                              fontSize: isNarrow ? 9 : 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (_currentMediaType == 'live' && _currentMediaId != null)
                                    ValueListenableBuilder<List<FavoriteItem>>(
                                      valueListenable: FavoritesService.favoritesNotifier,
                                      builder: (context, _, __) {
                                        final favId = 'live_$_currentMediaId';
                                        final isFav = FavoritesService.isFavoriteSync(favId);
                                        return _PlayerFocusButton(
                                          tooltip: isFav ? 'Remover dos Favoritos' : 'Favoritar Canal',
                                          onFocused: _startHideTimer,
                                          onPressed: () async {
                                            final favItem = FavoriteItem(
                                              id: favId,
                                              title: _currentTitle,
                                              type: 'live',
                                              cover: _currentCover,
                                              genre: _currentSubtitle,
                                              streamUrl: _currentStreamUrl,
                                              addedAt: DateTime.now(),
                                            );
                                            final nowFav = await FavoritesService.toggleFavorite(favItem);
                                            _showHud(nowFav ? 'FAVORITADO ★' : 'DESFAVORITADO ☆');
                                          },
                                          child: Icon(
                                            isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                            color: isFav ? AppColors.statusLive : AppColors.textMuted,
                                            size: 22,
                                          ),
                                        );
                                      },
                                    )
                                  else if (_currentMediaType != 'live')
                                    _PlayerFocusButton(
                                      tooltip: _isWatched ? 'Marcado como Visto' : 'Marcar como Visto',
                                      onFocused: _startHideTimer,
                                      onPressed: _toggleWatched,
                                      child: Icon(
                                        _isWatched ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                        color: _isWatched ? AppColors.statusLive : AppColors.textMuted,
                                        size: 20,
                                      ),
                                    ),
                                  if (_currentMediaType == 'live') ...[
                                    const SizedBox(width: 6),
                                    _PlayerFocusButton(
                                      tooltip: context.tr('player.live_channels_tooltip'),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      onFocused: _startHideTimer,
                                      onPressed: _toggleLiveEpgPanel,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.live_tv_rounded,
                                            color: AppColors.accentPrimary,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          HankoBadge(
                                            text: context.tr('player.live_channels'),
                                            borderColor: AppColors.accentPrimary,
                                            textColor: AppColors.accentPrimary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (_playlist != null && _playlist!.length > 1 && _currentMediaType == 'series') ...[
                                    const SizedBox(width: 6),
                                    _PlayerFocusButton(
                                      tooltip: context.tr('player.episodes_tooltip'),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      onFocused: _startHideTimer,
                                      onPressed: _toggleEpisodesPanel,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.video_collection_outlined,
                                            color: AppColors.accentPrimary,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          HankoBadge(
                                            text: '${context.tr('player.episodes_menu')} [ ${_currentIndex + 1}/${_playlist!.length} ]',
                                            borderColor: AppColors.accentPrimary,
                                            textColor: AppColors.accentPrimary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (hasNextEpisode) ...[
                                    const SizedBox(width: 6),
                                    _PlayerFocusButton(
                                      tooltip: _currentMediaType == 'live' ? 'Próximo Canal' : 'Próximo Episódio',
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      onFocused: _startHideTimer,
                                      onPressed: _playNextEpisode,
                                      child: HankoBadge(
                                        text: _currentMediaType == 'live' ? 'PRÓXIMO CANAL >' : 'PRÓXIMO >',
                                        borderColor: AppColors.accentCyan,
                                        textColor: AppColors.accentCyan,
                                      ),
                                    ),
                                  ],
                                  if (!isNarrow) ...[
                                    const SizedBox(width: 8),
                                    const TechCrosses(count: 3, opacity: 0.3),
                                    const SizedBox(width: 12),
                                  ] else
                                    const SizedBox(width: 8),
                                  _PlayerFocusButton(
                                    tooltip: 'Decodificador de Vídeo',
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    onFocused: _startHideTimer,
                                    onPressed: _toggleHwdec,
                                    child: HankoBadge(
                                      text: isNarrow
                                          ? (_hwdecMode == 'no' ? 'SW' : 'HW')
                                          : (_hwdecMode == 'no'
                                              ? 'SW DECODER [SEGURO]'
                                              : _hwdecMode == 'auto-copy'
                                                  ? 'HW: AUTO-COPY'
                                                  : 'HW: DIRETO'),
                                      borderColor: _hwdecMode == 'no' ? AppColors.accentCyan : AppColors.accentPrimary,
                                      textColor: _hwdecMode == 'no' ? AppColors.accentCyan : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Controles Centrais com Foco TV
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (hasPreviousEpisode) ...[
                                  _PlayerFocusButton(
                                    tooltip: _currentMediaType == 'live' ? 'Canal Anterior (P)' : 'Episódio Anterior (P)',
                                    onFocused: _startHideTimer,
                                    onPressed: _playPreviousEpisode,
                                    child: const Icon(Icons.skip_previous_rounded, size: 34, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(width: 14),
                                ],
                                if (_currentMediaType != 'live') ...[
                                  _PlayerFocusButton(
                                    tooltip: 'Retroceder 10s',
                                    onFocused: _startHideTimer,
                                    onPressed: () {
                                      _seekTo(_position - const Duration(seconds: 10));
                                      _showHud('-10s');
                                    },
                                    child: const Icon(Icons.replay_10_rounded, size: 36, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(width: 20),
                                ],
                                _PlayerFocusButton(
                                  autofocus: true,
                                  focusNode: _playPauseFocusNode,
                                  padding: const EdgeInsets.all(4),
                                  borderRadius: BorderRadius.circular(32),
                                  onFocused: _startHideTimer,
                                  onPressed: _togglePlayPause,
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.accentPrimary,
                                    ),
                                    child: Icon(
                                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      size: 36,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (_currentMediaType != 'live') ...[
                                  const SizedBox(width: 20),
                                  _PlayerFocusButton(
                                    tooltip: 'Avançar 10s',
                                    onFocused: _startHideTimer,
                                    onPressed: () {
                                      _seekTo(_position + const Duration(seconds: 10));
                                      _showHud('+10s');
                                    },
                                    child: const Icon(Icons.forward_10_rounded, size: 36, color: AppColors.textPrimary),
                                  ),
                                ],
                                if (hasNextEpisode) ...[
                                  const SizedBox(width: 14),
                                  _PlayerFocusButton(
                                    tooltip: _currentMediaType == 'live' ? 'Próximo Canal (N)' : 'Próximo Episódio (N)',
                                    onFocused: _startHideTimer,
                                    onPressed: _playNextEpisode,
                                    child: const Icon(Icons.skip_next_rounded, size: 34, color: AppColors.accentCyan),
                                  ),
                                ],
                              ],
                            ),

                            // Barra Inferior (Seek Bar / Live Badge + Tempos + Controle de Volume e Tela)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isNarrow ? 16 : 24,
                                vertical: isNarrow ? 12 : 16,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_currentMediaType != 'live') ...[
                                    // Barra de Progresso Focável no D-pad (Esquerda/Direita avança)
                                    Focus(
                                      focusNode: _sliderFocusNode,
                                      onKeyEvent: (node, event) {
                                        if (event is KeyDownEvent || event is KeyRepeatEvent) {
                                          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                            final newPos = _position > const Duration(seconds: 10)
                                                ? _position - const Duration(seconds: 10)
                                                : Duration.zero;
                                            _seekTo(newPos);
                                            _showHud('-10s [ ${_formatDuration(newPos)} ]');
                                            return KeyEventResult.handled;
                                          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                            final newPos = _position + const Duration(seconds: 10);
                                            _seekTo(newPos);
                                            _showHud('+10s [ ${_formatDuration(newPos)} ]');
                                            return KeyEventResult.handled;
                                          }
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: Builder(
                                        builder: (context) {
                                          final isSliderFocused = Focus.of(context).hasFocus;
                                          return AnimatedContainer(
                                            duration: const Duration(milliseconds: 140),
                                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSliderFocused ? AppColors.accentPrimary : Colors.transparent,
                                                width: 1.5,
                                              ),
                                              color: isSliderFocused
                                                  ? AppColors.accentPrimary.withValues(alpha: 0.12)
                                                  : Colors.transparent,
                                            ),
                                            child: SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                activeTrackColor: AppColors.accentPrimary,
                                                inactiveTrackColor: AppColors.borderHairline,
                                                thumbColor: isSliderFocused ? AppColors.accentCyan : AppColors.accentPrimary,
                                                thumbShape: RoundSliderThumbShape(enabledThumbRadius: isSliderFocused ? 7 : 5),
                                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                                trackHeight: 3,
                                              ),
                                              child: Slider(
                                                value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                                                max: _duration.inMilliseconds.toDouble() > 0
                                                    ? _duration.inMilliseconds.toDouble()
                                                    : 1.0,
                                                onChanged: (val) {
                                                  _startHideTimer();
                                                  _player.seek(Duration(milliseconds: val.toInt()));
                                                },
                                                onChangeEnd: (val) {
                                                  _seekTo(Duration(milliseconds: val.toInt()));
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],

                                  // Linha de Status: Duração / Ao Vivo à esquerda, Controle de Volume à direita
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (_currentMediaType == 'live') ...[
                                        Row(
                                          children: [
                                            const HankoBadge(
                                              text: '● AO VIVO',
                                              borderColor: AppColors.statusLive,
                                              textColor: AppColors.statusLive,
                                            ),
                                            const SizedBox(width: 10),
                                            _PlayerFocusButton(
                                              tooltip: context.tr('player.live_channels_tooltip'),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              onFocused: _startHideTimer,
                                              onPressed: _toggleLiveEpgPanel,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.live_tv_rounded,
                                                    size: 14,
                                                    color: AppColors.accentCyan,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '[ GUIA DE CANAIS // EPG ]',
                                                    style: AppTypography.mono(fontSize: isNarrow ? 10 : 11, color: AppColors.accentCyan),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        // Tempos
                                        Row(
                                          children: [
                                            Text(
                                              _formatDuration(_position),
                                              style: AppTypography.mono(fontSize: isNarrow ? 11 : 12, color: AppColors.textPrimary),
                                            ),
                                            Text(
                                              ' / ${_formatDuration(_duration)}',
                                              style: AppTypography.mono(fontSize: isNarrow ? 11 : 12, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      ],

                                      // Controle de Volume Dedicado e Ajuste de Tela
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _PlayerFocusButton(
                                            tooltip: _volume == 0 ? 'Desmutar (M)' : 'Mutar (M)',
                                            onFocused: _startHideTimer,
                                            onPressed: _toggleMute,
                                            child: Icon(
                                              _volume == 0
                                                  ? Icons.volume_off_rounded
                                                  : _volume < 50
                                                      ? Icons.volume_down_rounded
                                                      : Icons.volume_up_rounded,
                                              size: 20,
                                              color: _volume == 0 ? AppColors.statusError : AppColors.textPrimary,
                                            ),
                                          ),
                                          if (!isNarrow) ...[
                                            SizedBox(
                                              width: 85,
                                              child: SliderTheme(
                                                data: SliderTheme.of(context).copyWith(
                                                  activeTrackColor: AppColors.accentPrimary,
                                                  inactiveTrackColor: AppColors.surfaceHover,
                                                  thumbColor: AppColors.accentPrimary,
                                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                                                  trackHeight: 2,
                                                ),
                                                child: Slider(
                                                  value: _volume,
                                                  min: 0.0,
                                                  max: 100.0,
                                                  onChanged: (val) {
                                                    _setVolume(val);
                                                  },
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            '${_volume.toInt()}%',
                                            style: AppTypography.mono(fontSize: isNarrow ? 10 : 11, color: AppColors.textMuted),
                                          ),
                                          const SizedBox(width: 8),
                                          // Botão de Ajuste de Tela (Eliminar Bordas Laterais / Notch)
                                          _PlayerFocusButton(
                                            tooltip: 'Ajuste de Tela (A): Original / Zoom / Esticado',
                                            onFocused: _startHideTimer,
                                            onPressed: _toggleVideoFit,
                                            child: Icon(
                                              _videoFit == BoxFit.cover
                                                  ? Icons.fullscreen_rounded
                                                  : (_videoFit == BoxFit.fill
                                                      ? Icons.fit_screen_rounded
                                                      : Icons.aspect_ratio_rounded),
                                              size: 20,
                                              color: _videoFit != BoxFit.contain ? AppColors.accentCyan : AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
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
                  ),
                ),

                // Prompt flutuante de próximo episódio com contagem regressiva
                if (_showNextCountdown && hasNextEpisode)
                  Positioned(
                    bottom: 96,
                    right: 24,
                    child: _buildNextEpisodeCountdownCard(),
                  ),

                // Gaveta Lateral / Menu de Troca de Episódios
                if (_showEpisodesPanel && _playlist != null && _playlist!.isNotEmpty)
                  Positioned.fill(
                    child: _buildEpisodesPanel(context, isNarrow),
                  ),

                // Painel Multi-Coluna em Cascata de Canais e Guia EPG (Live Stream)
                if (_showLiveEpgPanel && _currentMediaType == 'live')
                  Positioned.fill(
                    child: LiveChannelEpgPanel(
                      currentStreamId: _currentMediaId,
                      onChannelSelected: _switchLiveChannel,
                      onClose: _closeLiveEpgPanel,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildNextEpisodeCountdownCard() {
    if (!hasNextEpisode || _playlist == null) return const SizedBox.shrink();
    final nextItem = _playlist![_currentIndex + 1];

    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentPrimary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.accentPrimary.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              HankoBadge(
                text: 'PRÓXIMO EM ${_countdownSeconds}S',
                borderColor: AppColors.accentCyan,
                textColor: AppColors.accentCyan,
              ),
              _PlayerFocusButton(
                tooltip: 'Fechar',
                padding: const EdgeInsets.all(4),
                borderRadius: BorderRadius.circular(12),
                onPressed: _cancelNextCountdown,
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            nextItem.subtitle ?? nextItem.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium(fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: _PlayerFocusButton(
              autofocus: true,
              borderRadius: BorderRadius.circular(8),
              onPressed: _playNextEpisode,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'ASSISTIR AGORA.',
                    style: AppTypography.mono(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesPanel(BuildContext context, bool isNarrow) {
    if (_playlist == null || _playlist!.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        // Backdrop escurecido interativo para fechar ao tocar fora
        FadeTransition(
          opacity: _episodesFadeAnimation,
          child: GestureDetector(
            onTap: _closeEpisodesPanel,
            child: Container(
              color: Colors.black.withValues(alpha: 0.68),
            ),
          ),
        ),

        // Gaveta Lateral Deslizante à Direita (Bento / Oriental Brutalism)
        Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: _episodesSlideAnimation,
            child: Container(
              width: isNarrow ? MediaQuery.of(context).size.width * 0.88 : 380,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                border: const Border(
                  left: BorderSide(color: AppColors.accentPrimary, width: 1.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.85),
                    blurRadius: 28,
                    offset: const Offset(-6, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // Top Bar da Gaveta de Episódios
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceCard,
                      border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.video_collection_outlined,
                          color: AppColors.accentPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.tr('player.episodes_menu'),
                                style: AppTypography.titleMedium(fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '[ ${_playlist!.length} EPISÓDIOS // SELEÇÃO ]',
                                style: AppTypography.mono(fontSize: 10, color: AppColors.accentCyan),
                              ),
                            ],
                          ),
                        ),
                        _PlayerFocusButton(
                          tooltip: 'Fechar (ESC)',
                          padding: const EdgeInsets.all(4),
                          onPressed: _closeEpisodesPanel,
                          child: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 20),
                        ),
                      ],
                    ),
                  ),

                  // Lista de Episódios com rolagem automática para o atual
                  Expanded(
                    child: ListView.separated(
                      controller: _episodesScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      itemCount: _playlist!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ep = _playlist![index];
                        final isCurrent = index == _currentIndex;
                        final isWatched = WatchedService.isWatchedSync(ep.id);

                        return _PlayerFocusButton(
                          autofocus: isCurrent,
                          borderRadius: BorderRadius.circular(8),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            _playEpisodeIndex(index);
                            _closeEpisodesPanel();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isCurrent ? AppColors.surfaceHover : AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrent ? AppColors.accentPrimary : AppColors.borderHairline,
                                width: isCurrent ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Thumbnail do Episódio
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 76,
                                    height: 48,
                                    color: AppColors.canvas,
                                    child: ep.cover != null && ep.cover!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: ep.cover!,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              color: AppColors.surfaceCard,
                                              child: const Center(
                                                child: HankoLoader.mini(
                                                  miniSize: 18,
                                                  primaryColor: AppColors.accentPrimary,
                                                ),
                                              ),
                                            ),
                                            errorWidget: (_, __, ___) => Container(
                                              color: AppColors.surfaceCard,
                                              child: const Center(
                                                child: Icon(Icons.movie_outlined, size: 20, color: AppColors.textDisabled),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: AppColors.surfaceCard,
                                            child: const Center(
                                              child: Icon(Icons.movie_outlined, size: 20, color: AppColors.textDisabled),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Informações do Episódio
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          if (isCurrent) ...[
                                            HankoBadge(
                                              text: context.tr('player.now_playing'),
                                              borderColor: AppColors.accentPrimary,
                                              textColor: AppColors.accentPrimary,
                                            ),
                                            const SizedBox(width: 6),
                                          ] else if (isWatched) ...[
                                            const Icon(Icons.check_circle_rounded, color: AppColors.statusLive, size: 14),
                                            const SizedBox(width: 4),
                                          ],
                                          Expanded(
                                            child: Text(
                                              ep.subtitle ?? 'EPISÓDIO ${index + 1}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.mono(
                                                fontSize: 10,
                                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                                color: isCurrent ? AppColors.accentPrimary : AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        ep.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                          color: isCurrent ? AppColors.textPrimary : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 6),
                                Icon(
                                  isCurrent ? Icons.play_arrow_rounded : Icons.play_arrow_outlined,
                                  color: isCurrent ? AppColors.accentPrimary : AppColors.textDisabled,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
}

/// Botão de controle de mídia otimizado para navegação via D-pad em Android TV / Fire Stick.
class _PlayerFocusButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool autofocus;
  final FocusNode? focusNode;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onFocused;

  const _PlayerFocusButton({
    required this.child,
    required this.onPressed,
    this.tooltip,
    this.autofocus = false,
    this.focusNode,
    this.padding = const EdgeInsets.all(8),
    this.borderRadius,
    this.onFocused,
  });

  @override
  State<_PlayerFocusButton> createState() => _PlayerFocusButtonState();
}

class _PlayerFocusButtonState extends State<_PlayerFocusButton> {
  late final FocusNode _node;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _node.hasFocus);
      if (_node.hasFocus && widget.onFocused != null) {
        widget.onFocused!();
      }
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(8);
    const borderColor = AppColors.accentPrimary;

    Widget button = Focus(
      focusNode: _node,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.gameButtonA) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: br,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: br,
            border: Border.all(
              color: _isFocused ? borderColor : Colors.transparent,
              width: 2,
            ),
            color: _isFocused
                ? borderColor.withValues(alpha: 0.28)
                : Colors.transparent,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.45),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
