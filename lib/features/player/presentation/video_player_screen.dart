import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../core/storage/favorite_item.dart';
import '../../../core/storage/favorites_service.dart';
import '../../../core/storage/recent_channels_service.dart';
import '../../../core/storage/watch_history_service.dart';
import '../../../core/storage/watched_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hanko_badge.dart';
import '../../../core/widgets/tech_crosses.dart';
import '../models/playlist_item.dart';

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

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with WidgetsBindingObserver {
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

  double _volume = 100.0;
  double _lastVolume = 100.0;
  String _hwdecMode = 'no';

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _playSub;
  StreamSubscription? _bufSub;
  StreamSubscription? _errSub;
  StreamSubscription? _volSub;
  StreamSubscription? _compSub;

  bool get hasNextEpisode =>
      widget.playlist != null && _currentIndex < widget.playlist!.length - 1;
  bool get hasPreviousEpisode =>
      widget.playlist != null && _currentIndex > 0;

  @override
  void initState() {
    super.initState();

    // No Android / Mobile: Força orientação horizontal (landscape) e tela cheia imersiva (sem barra de status/topo)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _currentIndex = widget.initialPlaylistIndex;
    if (widget.playlist != null &&
        widget.playlist!.isNotEmpty &&
        _currentIndex >= 0 &&
        _currentIndex < widget.playlist!.length) {
      final item = widget.playlist![_currentIndex];
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
      _currentMediaType = widget.mediaType;
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

    _controller = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: false,
        hwdec: 'no',
      ),
    );

    _posSub = _player.stream.position.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
          if (pos > Duration.zero) {
            _isBuffering = false;
          }
        });

        // Marca automaticamente como visto se assistiu mais de 90%
        if (_duration.inSeconds > 30 && _currentMediaType != 'live') {
          final ratio = _position.inSeconds / _duration.inSeconds;
          if (ratio >= 0.90 && !_isWatched && _currentMediaId != null) {
            WatchedService.markAsWatched(_currentMediaId!);
            setState(() => _isWatched = true);
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
      if (mounted) setState(() => _duration = dur);
    });

    _playSub = _player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });

    _bufSub = _player.stream.buffering.listen((buffering) {
      if (mounted) {
        setState(() {
          if (_position == Duration.zero) {
            _isBuffering = buffering;
          } else {
            _isBuffering = buffering && !_isPlaying;
          }
        });
      }
    });

    _volSub = _player.stream.volume.listen((vol) {
      if (mounted) setState(() => _volume = vol.clamp(0.0, 100.0));
    });

    _errSub = _player.stream.error.listen((err) {
      debugPrint('[PANDA MPV ERROR] $err');
      if (mounted) {
        setState(() => _errorMessage = 'Erro ao carregar transmissão: $err');
      }
    });

    _compSub = _player.stream.completed.listen((completed) {
      if (completed && mounted) {
        if (_currentMediaId != null && _currentMediaType != 'live') {
          WatchedService.markAsWatched(_currentMediaId!);
          setState(() => _isWatched = true);
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
  Future<void> _initAndPlay({String? streamUrl, int? startPositionMs}) async {
    final url = streamUrl ?? _currentStreamUrl;
    try {
      final platform = _player.platform;
      if (platform is NativePlayer) {
        await platform.setProperty('hwdec', _hwdecMode);
        await platform.setProperty('user-agent', 'IPTVSmartersPro/3.1.5 (Linux; Android 12)');
      }
    } catch (_) {}

    await _player.open(
      Media(
        url,
        httpHeaders: const {
          'User-Agent': 'IPTVSmartersPro/3.1.5 (Linux; Android 12)',
          'Accept': '*/*',
          'Connection': 'keep-alive',
        },
      ),
    );

    final pos = startPositionMs ?? (streamUrl == null ? widget.initialPositionMs : null);
    if (pos != null && pos > 2000) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _player.seek(Duration(milliseconds: pos));
          _showHud('RETOMANDO REPRODUÇÃO.');
        }
      });
    }
  }

  void _playNextEpisode() {
    if (!hasNextEpisode) return;
    _playEpisodeIndex(_currentIndex + 1);
  }

  void _playPreviousEpisode() {
    if (!hasPreviousEpisode) return;
    _playEpisodeIndex(_currentIndex - 1);
  }

  void _playEpisodeIndex(int index) async {
    if (widget.playlist == null || index < 0 || index >= widget.playlist!.length) return;
    _cancelNextCountdown();

    if (_currentMediaId != null) {
      WatchedService.markAsWatched(_currentMediaId!);
    }
    _saveCurrentProgress();

    final nextItem = widget.playlist![index];
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

  void _triggerNextEpisodeCountdown() {
    if (_showNextCountdown || !hasNextEpisode) return;
    setState(() {
      _showNextCountdown = true;
      _countdownSeconds = 6;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        timer.cancel();
        _playNextEpisode();
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  void _cancelNextCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_showNextCountdown && mounted) {
      setState(() => _showNextCountdown = false);
    }
  }

  void _toggleWatched() async {
    if (_currentMediaId == null) return;
    final isNowWatched = await WatchedService.toggleWatched(_currentMediaId!);
    if (mounted) {
      setState(() => _isWatched = isNowWatched);
      _showHud(isNowWatched ? 'MARCADO COMO VISTO.' : 'DESMARCADO COMO VISTO.');
    }
  }

  Future<void> _toggleHwdec() async {
    final nextMode = _hwdecMode == 'no' ? 'auto-copy' : _hwdecMode == 'auto-copy' ? 'auto' : 'no';
    setState(() => _hwdecMode = nextMode);

    try {
      final platform = _player.platform;
      if (platform is NativePlayer) {
        await platform.setProperty('hwdec', nextMode);
      }
    } catch (_) {}

    final label = nextMode == 'no' ? 'SOFTWARE (SEGURO)' : nextMode.toUpperCase();
    _showHud('DECODER: $label');
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _setVolume(double newVol) {
    final clamped = newVol.clamp(0.0, 100.0);
    _player.setVolume(clamped);
    setState(() => _volume = clamped);
    _showHud('VOLUME: ${clamped.toInt()}%');
    _startHideTimer();
  }

  void _toggleMute() {
    if (_volume > 0) {
      _lastVolume = _volume;
      _setVolume(0);
      _showHud('MUTADO.');
    } else {
      _setVolume(_lastVolume > 0 ? _lastVolume : 80);
      _showHud('DESMUTADO.');
    }
  }

  void _showHud(String message) {
    _hudTimer?.cancel();
    setState(() => _hudMessage = message);
    _hudTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _hudMessage = null);
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
    _startHideTimer();
  }

  void _pausePlayback() {
    _saveCurrentProgress();
    _player.pause();
    _showHud('PAUSADO.');
    _startHideTimer();
  }

  void _playPlayback() {
    _player.play();
    _showHud('REPRODUZINDO.');
    _startHideTimer();
  }

  void _seekTo(Duration target) {
    final clampedMs = target.inMilliseconds.clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 0);
    final finalDuration = Duration(milliseconds: clampedMs);
    _player.seek(finalDuration);
    _position = finalDuration;
    _saveCurrentProgress();
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

  @override
  void dispose() {
    // Restaura a barra de status do sistema e todas as orientações permitidas ao sair do player
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

    _cancelNextCountdown();
    WidgetsBinding.instance.removeObserver(this);
    _saveProgressTimer?.cancel();
    _saveCurrentProgress();
    _hideTimer?.cancel();
    _hudTimer?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _playSub?.cancel();
    _bufSub?.cancel();
    _volSub?.cancel();
    _errSub?.cancel();
    _compSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedTitle = _currentTitle.toUpperCase().endsWith('.')
        ? _currentTitle.toUpperCase()
        : '${_currentTitle.toUpperCase()}.';

    final isNarrow = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _saveCurrentProgress();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              final key = event.logicalKey;
              if (key == LogicalKeyboardKey.space ||
                  key == LogicalKeyboardKey.select ||
                  key == LogicalKeyboardKey.enter ||
                  key == LogicalKeyboardKey.numpadEnter ||
                  key == LogicalKeyboardKey.gameButtonA ||
                  key == LogicalKeyboardKey.mediaPlayPause) {
                _togglePlayPause();
                return KeyEventResult.handled;
              } else if (key == LogicalKeyboardKey.mediaPlay) {
                _playPlayback();
                return KeyEventResult.handled;
              } else if (key == LogicalKeyboardKey.mediaPause) {
                _pausePlayback();
                return KeyEventResult.handled;
              } else if (key == LogicalKeyboardKey.arrowRight ||
                  key == LogicalKeyboardKey.mediaFastForward) {
                _seekTo(_position + const Duration(seconds: 10));
                _showHud('+10s');
                return KeyEventResult.handled;
              } else if (key == LogicalKeyboardKey.arrowLeft ||
                  key == LogicalKeyboardKey.mediaRewind) {
                _seekTo(_position - const Duration(seconds: 10));
                _showHud('-10s');
                return KeyEventResult.handled;
              } else if (key == LogicalKeyboardKey.keyN ||
                  key == LogicalKeyboardKey.mediaTrackNext) {
                if (hasNextEpisode) {
                  _playNextEpisode();
                  return KeyEventResult.handled;
                }
              } else if (key == LogicalKeyboardKey.keyP ||
                  key == LogicalKeyboardKey.mediaTrackPrevious) {
                if (hasPreviousEpisode) {
                  _playPreviousEpisode();
                  return KeyEventResult.handled;
                }
              } else if (key == LogicalKeyboardKey.arrowUp) {
                _setVolume(_volume + 5);
                return KeyEventResult.handled;
              } else if (key == LogicalKeyboardKey.arrowDown) {
                _setVolume(_volume - 5);
                return KeyEventResult.handled;
              } else if (key == LogicalKeyboardKey.keyM) {
                _toggleMute();
                return KeyEventResult.handled;
              } else if (key == LogicalKeyboardKey.keyD) {
                _toggleHwdec();
                return KeyEventResult.handled;
              } else if (key == LogicalKeyboardKey.escape ||
                  key == LogicalKeyboardKey.backspace ||
                  key == LogicalKeyboardKey.goBack) {
                _saveCurrentProgress();
                Navigator.of(context).pop();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
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
            onTap: _toggleControls,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                // Renderização do vídeo via MPV
                SizedBox.expand(
                  child: Video(
                    controller: _controller,
                    controls: NoVideoControls,
                    fill: Colors.black,
                    fit: BoxFit.contain,
                  ),
                ),

                // Indicador de buffering
                if (_isBuffering && _errorMessage == null && _position == Duration.zero)
                  const Center(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
                      ),
                    ),
                  ),

                // HUD de Notificação Rápida (Volume, Seek, Play/Pause)
                if (_hudMessage != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentPrimary),
                      ),
                      child: Text(
                        _hudMessage!,
                        style: AppTypography.mono(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentPrimary,
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

                // OSD Minimalista Brutalista com controles completos
                AnimatedOpacity(
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
                          // Top Bar Responsiva
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isNarrow ? 12 : 20,
                              vertical: isNarrow ? 10 : 16,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                                  onPressed: () => Navigator.of(context).pop(),
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
                                      return IconButton(
                                        icon: Icon(
                                          isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                          color: isFav ? AppColors.statusLive : AppColors.textMuted,
                                          size: 22,
                                        ),
                                        tooltip: isFav ? 'Remover dos Favoritos' : 'Favoritar Canal',
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
                                      );
                                    },
                                  )
                                else if (_currentMediaType != 'live')
                                  IconButton(
                                    icon: Icon(
                                      _isWatched ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                      color: _isWatched ? AppColors.statusLive : AppColors.textMuted,
                                      size: 20,
                                    ),
                                    tooltip: _isWatched ? 'Marcado como Visto' : 'Marcar como Visto',
                                    onPressed: _toggleWatched,
                                  ),
                                if (hasNextEpisode) ...[
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: _playNextEpisode,
                                    borderRadius: BorderRadius.circular(6),
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
                                InkWell(
                                  onTap: _toggleHwdec,
                                  borderRadius: BorderRadius.circular(6),
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

                          // Controles Centrais
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (hasPreviousEpisode) ...[
                                IconButton(
                                  iconSize: 34,
                                  color: AppColors.textPrimary,
                                  icon: const Icon(Icons.skip_previous_rounded),
                                  tooltip: _currentMediaType == 'live' ? 'Canal Anterior (P)' : 'Episódio Anterior (P)',
                                  onPressed: _playPreviousEpisode,
                                ),
                                const SizedBox(width: 14),
                              ],
                              if (_currentMediaType != 'live') ...[
                                IconButton(
                                  iconSize: 36,
                                  color: AppColors.textPrimary,
                                  icon: const Icon(Icons.replay_10_rounded),
                                  onPressed: () {
                                    _seekTo(_position - const Duration(seconds: 10));
                                    _showHud('-10s');
                                  },
                                ),
                                const SizedBox(width: 24),
                              ],
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accentPrimary,
                                ),
                                child: IconButton(
                                  iconSize: 42,
                                  color: Colors.white,
                                  icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                  onPressed: _togglePlayPause,
                                ),
                              ),
                              if (_currentMediaType != 'live') ...[
                                const SizedBox(width: 24),
                                IconButton(
                                  iconSize: 36,
                                  color: AppColors.textPrimary,
                                  icon: const Icon(Icons.forward_10_rounded),
                                  onPressed: () {
                                    _seekTo(_position + const Duration(seconds: 10));
                                    _showHud('+10s');
                                  },
                                ),
                              ],
                              if (hasNextEpisode) ...[
                                const SizedBox(width: 14),
                                IconButton(
                                  iconSize: 34,
                                  color: AppColors.accentCyan,
                                  icon: const Icon(Icons.skip_next_rounded),
                                  tooltip: _currentMediaType == 'live' ? 'Próximo Canal (N)' : 'Próximo Episódio (N)',
                                  onPressed: _playNextEpisode,
                                ),
                              ],
                            ],
                          ),

                          // Barra Inferior (Seek Bar / Live Badge + Tempos + Controle de Volume)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isNarrow ? 16 : 24,
                              vertical: isNarrow ? 12 : 16,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_currentMediaType != 'live') ...[
                                  // Barra de Progresso
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AppColors.accentPrimary,
                                      inactiveTrackColor: AppColors.borderHairline,
                                      thumbColor: AppColors.accentPrimary,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                      trackHeight: 3,
                                    ),
                                    child: Slider(
                                      value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                                      max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                                      onChanged: (val) {
                                        _startHideTimer();
                                        _player.seek(Duration(milliseconds: val.toInt()));
                                      },
                                      onChangeEnd: (val) {
                                        _seekTo(Duration(milliseconds: val.toInt()));
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
                                          Text(
                                            '[ TRANSMISSÃO EM DIRETO ]',
                                            style: AppTypography.mono(fontSize: isNarrow ? 10 : 11, color: AppColors.accentCyan),
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

                                    // Controle de Volume Dedicado
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: _volume == 0 ? 'Desmutar (M)' : 'Mutar (M)',
                                          icon: Icon(
                                            _volume == 0
                                                ? Icons.volume_off_rounded
                                                : _volume < 50
                                                    ? Icons.volume_down_rounded
                                                    : Icons.volume_up_rounded,
                                            size: 20,
                                            color: _volume == 0 ? AppColors.statusError : AppColors.textPrimary,
                                          ),
                                          onPressed: _toggleMute,
                                        ),
                                        if (!isNarrow) ...[
                                          SizedBox(
                                            width: 90,
                                            child: SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                activeTrackColor: AppColors.accentPrimary,
                                                inactiveTrackColor: AppColors.surfaceHover,
                                                thumbColor: AppColors.accentPrimary,
                                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
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

                // Prompt flutuante de próximo episódio com contagem regressiva
                if (_showNextCountdown && hasNextEpisode)
                  Positioned(
                    bottom: 96,
                    right: 24,
                    child: _buildNextEpisodeCountdownCard(),
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
    if (!hasNextEpisode) return const SizedBox.shrink();
    final nextItem = widget.playlist![_currentIndex + 1];

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
              InkWell(
                onTap: _cancelNextCountdown,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHover,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
                ),
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
            child: ElevatedButton.icon(
              onPressed: _playNextEpisode,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(
                'ASSISTIR AGORA.',
                style: AppTypography.mono(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
