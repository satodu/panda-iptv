import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hanko_badge.dart';
import '../../../core/widgets/tech_crosses.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String streamUrl;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.streamUrl,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;

  bool _showControls = true;
  Timer? _hideTimer;
  Timer? _hudTimer;
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

  @override
  void initState() {
    super.initState();

    // No Android / Mobile: Força orientação horizontal (landscape) e tela cheia imersiva (sem barra de status/topo)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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

    _initAndPlay();
    _startHideTimer();
  }

  Future<void> _initAndPlay() async {
    // Configura propriedades nativas do mpv se disponíveis
    try {
      final platform = _player.platform;
      if (platform is NativePlayer) {
        await platform.setProperty('hwdec', _hwdecMode);
        await platform.setProperty('user-agent', 'IPTVSmartersPro/3.1.5 (Linux; Android 12)');
      }
    } catch (_) {}

    await _player.open(
      Media(
        widget.streamUrl,
        httpHeaders: const {
          'User-Agent': 'IPTVSmartersPro/3.1.5 (Linux; Android 12)',
          'Accept': '*/*',
          'Connection': 'keep-alive',
        },
      ),
    );
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

    _hideTimer?.cancel();
    _hudTimer?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _playSub?.cancel();
    _bufSub?.cancel();
    _volSub?.cancel();
    _errSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedTitle = widget.title.toUpperCase().endsWith('.')
        ? widget.title.toUpperCase()
        : '${widget.title.toUpperCase()}.';

    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.space) {
              _player.playOrPause();
              _showHud(_isPlaying ? 'PAUSADO.' : 'REPRODUZINDO.');
              _startHideTimer();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _player.seek(_position + const Duration(seconds: 10));
              _showHud('+10s');
              _startHideTimer();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _player.seek(_position - const Duration(seconds: 10));
              _showHud('-10s');
              _startHideTimer();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _setVolume(_volume + 5);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _setVolume(_volume - 5);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
              _toggleMute();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
              _toggleHwdec();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
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
                                      if (widget.subtitle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.subtitle!,
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
                                if (!isNarrow) ...[
                                  const TechCrosses(count: 3, opacity: 0.3),
                                  const SizedBox(width: 12),
                                ],
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

                          // Controles Centrais (Seek -10s, Play/Pause, Seek +10s)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                iconSize: 36,
                                color: AppColors.textPrimary,
                                icon: const Icon(Icons.replay_10_rounded),
                                onPressed: () {
                                  _player.seek(_position - const Duration(seconds: 10));
                                  _showHud('-10s');
                                  _startHideTimer();
                                },
                              ),
                              const SizedBox(width: 24),
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accentPrimary,
                                ),
                                child: IconButton(
                                  iconSize: 42,
                                  color: Colors.white,
                                  icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                  onPressed: () {
                                    _player.playOrPause();
                                    _startHideTimer();
                                  },
                                ),
                              ),
                              const SizedBox(width: 24),
                              IconButton(
                                iconSize: 36,
                                color: AppColors.textPrimary,
                                icon: const Icon(Icons.forward_10_rounded),
                                onPressed: () {
                                  _player.seek(_position + const Duration(seconds: 10));
                                  _showHud('+10s');
                                  _startHideTimer();
                                },
                              ),
                            ],
                          ),

                          // Barra Inferior (Seek Bar + Tempos + Controle de Volume)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isNarrow ? 16 : 24,
                              vertical: isNarrow ? 12 : 16,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                                  ),
                                ),

                                // Linha de Status: Duração à esquerda, Controle de Volume à direita
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
