import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/update_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/brutalist_button.dart';
import '../../../core/widgets/hanko_badge.dart';
import '../../../core/widgets/tech_crosses.dart';
import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _serverController = TextEditingController(text: 'http://');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _updateFocusNode = FocusNode(debugLabel: 'login_update');
  final _serverFocusNode = FocusNode(debugLabel: 'login_server');
  final _usernameFocusNode = FocusNode(debugLabel: 'login_username');
  final _passwordFocusNode = FocusNode(debugLabel: 'login_password');
  final _rememberFocusNode = FocusNode(debugLabel: 'login_remember');
  final _connectFocusNode = FocusNode(debugLabel: 'login_connect');

  bool _obscurePassword = true;
  bool _rememberMe = true;

  UpdateInfo? _updateInfo;
  bool _isCheckingUpdate = false;
  bool _isDownloadingUpdate = false;
  double _downloadProgress = 0.0;
  String _currentAppVersion = '0.0.6';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final info = await context.read<AuthProvider>().getLastSessionInfo();
      if (info != null && mounted) {
        setState(() {
          if (info['server'] != null && info['server']!.isNotEmpty) {
            _serverController.text = info['server']!;
          }
          if (info['username'] != null && info['username']!.isNotEmpty) {
            _usernameController.text = info['username']!;
          }
          if (info['password'] != null && info['password']!.isNotEmpty) {
            _passwordController.text = info['password']!;
          }
          if (info['remember_me'] != null) {
            _rememberMe = info['remember_me'] == 'true';
          }
        });
      }

      try {
        final pkg = await PackageInfo.fromPlatform();
        if (mounted) setState(() => _currentAppVersion = pkg.version);
      } catch (_) {}

      // Foco inicial no primeiro campo (Servidor) para que navegar para baixo vá para Usuário
      if (mounted) {
        _serverFocusNode.requestFocus();
      }

      _checkForUpdates(silent: true);
    });
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();

    _updateFocusNode.dispose();
    _serverFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _rememberFocusNode.dispose();
    _connectFocusNode.dispose();

    super.dispose();
  }

  void _checkForUpdates({bool silent = false}) async {
    if (_isCheckingUpdate || _isDownloadingUpdate) return;
    if (!silent) setState(() => _isCheckingUpdate = true);

    try {
      final info = await UpdateService.checkForUpdate();
      if (mounted) {
        if (info != null && info.hasUpdate) {
          setState(() {
            _updateInfo = info;
            _isCheckingUpdate = false;
          });
          if (!silent) {
            AppToast.info(context, 'NOVA ATUALIZAÇÃO DISPONÍVEL (v${info.latestVersion}).');
          }
        } else {
          setState(() {
            _isCheckingUpdate = false;
          });
          if (!silent) {
            AppToast.success(context, 'O APP JÁ ESTÁ NA VERSÃO MAIS RECENTE (v$_currentAppVersion).');
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
        if (!silent) {
          AppToast.error(context, 'FALHA AO VERIFICAR ATUALIZAÇÕES.');
        }
      }
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
          AppToast.error(context, error);
        }
      },
      onReadyToInstall: () {
        if (mounted) {
          setState(() => _isDownloadingUpdate = false);
          AppToast.success(context, 'INSTALADOR PRONTO // ABRINDO...');
        }
      },
    );
  }

  void _submit() {
    final server = _serverController.text.trim();
    final user = _usernameController.text.trim();
    final pass = _passwordController.text.trim();

    if (server.isEmpty || user.isEmpty || pass.isEmpty) {
      AppToast.error(context, context.tr('auth.empty_fields_error').toUpperCase());
      return;
    }

    context.read<AuthProvider>().login(
          serverUrl: server,
          username: user,
          password: pass,
          rememberMe: _rememberMe,
        );
  }

  /// Diálogo brutalista para inserção de texto na TV/Mobile.
  /// O teclado virtual abre somente aqui, garantindo navegação D-pad 100% livre na tela de login.
  Future<void> _openEditModal({
    required String title,
    required String hintText,
    required TextEditingController controller,
    required IconData prefixIcon,
    required bool isPassword,
    required TextInputType keyboardType,
    VoidCallback? onConfirmed,
  }) async {
    final modalTextController = TextEditingController(text: controller.text);
    modalTextController.selection = TextSelection.fromPosition(
      TextPosition(offset: modalTextController.text.length),
    );
    bool obscureInModal = isPassword;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Dialog(
              backgroundColor: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.accentCyan, width: 2),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabeçalho Brutalista
                      Row(
                        children: [
                          Icon(prefixIcon, color: AppColors.accentCyan, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '[ DIGITAR: ${title.trim().toUpperCase()} ]',
                              style: AppTypography.mono(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const TechCrosses(count: 3, opacity: 0.4),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Campo de Texto onde o teclado do Fire TV / Android opera
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accentPrimary, width: 1.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: TextField(
                          controller: modalTextController,
                          autofocus: true,
                          obscureText: obscureInModal,
                          keyboardType: keyboardType,
                          textInputAction: TextInputAction.done,
                          style: AppTypography.mono(fontSize: 14, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: hintText,
                            hintStyle: AppTypography.mono(
                              fontSize: 12,
                              color: AppColors.textMuted.withValues(alpha: 0.6),
                            ),
                            border: InputBorder.none,
                            suffixIcon: isPassword
                                ? IconButton(
                                    focusNode: FocusNode(skipTraversal: true),
                                    icon: Icon(
                                      obscureInModal
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textMuted,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setModalState(() => obscureInModal = !obscureInModal);
                                    },
                                  )
                                : (modalTextController.text.isNotEmpty
                                    ? IconButton(
                                        focusNode: FocusNode(skipTraversal: true),
                                        icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 16),
                                        onPressed: () {
                                          modalTextController.clear();
                                          setModalState(() {});
                                        },
                                      )
                                    : null),
                          ),
                          onSubmitted: (_) {
                            Navigator.of(dialogCtx).pop(true);
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Ações do Diálogo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            child: Text(
                              'CANCELAR.',
                              style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentCyan,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () => Navigator.of(dialogCtx).pop(true),
                            child: Text(
                              'CONFIRMAR (OK).',
                              style: AppTypography.mono(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        controller.text = modalTextController.text.trim();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          onConfirmed?.call();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 24 : 18,
              vertical: isLandscape ? 12 : 20,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isLandscape ? 880 : 440,
              ),
              child: isLandscape && screenWidth > 680
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _buildBrandingPanel(isLandscape: true),
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          flex: 5,
                          child: _buildFormCard(isLandscape: true),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBrandingPanel(isLandscape: false),
                        const SizedBox(height: 18),
                        _buildFormCard(isLandscape: false),
                        const SizedBox(height: 16),
                        _buildDisclaimerText(isCompact: true),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingPanel({required bool isLandscape}) {
    return Column(
      crossAxisAlignment: isLandscape ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderHairline),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              width: isLandscape ? 64 : 76,
              height: isLandscape ? 64 : 76,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.accentPrimary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const HankoBadge(text: 'XTREAM // V2.0', borderColor: AppColors.accentCyan),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'PANDA IPTV.',
          textAlign: isLandscape ? TextAlign.start : TextAlign.center,
          style: isLandscape ? AppTypography.sectionTitle(fontSize: 22) : AppTypography.displayLarge(),
        ),
        const SizedBox(height: 4),
        Text(
          'SISTEMA DE TRANSMISSÃO E MÍDIA.',
          textAlign: isLandscape ? TextAlign.start : TextAlign.center,
          style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        const TechCrosses(count: 5, spacing: 8),
        if (isLandscape) ...[
          const SizedBox(height: 20),
          _buildDisclaimerText(isCompact: false),
        ],
      ],
    );
  }

  Widget _buildDisclaimerText({required bool isCompact}) {
    return Text(
      '[ AVISO LEGAL: O PANDA IPTV É EXCLUSIVAMENTE UM REPRODUTOR DE MÍDIA. '
      'NÃO HOSPEDA, NÃO FORNECE E NÃO DISTRIBUI NENHUM CONTEÚDO OU LISTA. ]',
      textAlign: isCompact ? TextAlign.center : TextAlign.start,
      style: AppTypography.mono(
        fontSize: 9,
        color: AppColors.textMuted.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _buildFormCard({required bool isLandscape}) {
    final auth = context.watch<AuthProvider>();

    return BentoCard(
      padding: EdgeInsets.symmetric(
        horizontal: 22,
        vertical: isLandscape ? 16 : 22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('auth.title'),
                style: AppTypography.sectionTitle(fontSize: 14),
              ),
              const TechCrosses(count: 3, opacity: 0.3),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Insira as credenciais do seu provedor.',
            style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),

          // 0. Banner de Atualização (SÓ APARECE QUANDO HOUVER UPDATE DISPONÍVEL OU ESTIVER BAIXANDO)
          if (_updateInfo?.hasUpdate == true || _isDownloadingUpdate) ...[
            _buildUpdateBanner(),
            const SizedBox(height: 12),
          ],

          // 1. Campo Servidor
          _buildInputField(
            label: '${context.tr('auth.server')}:',
            controller: _serverController,
            focusNode: _serverFocusNode,
            hintText: 'http://dns-do-provedor.xyz:8080',
            prefixIcon: Icons.dns_outlined,
            keyboardType: TextInputType.url,
            onConfirmedNext: () => _usernameFocusNode.requestFocus(),
          ),
          const SizedBox(height: 10),

          // 2. Campo Usuário
          _buildInputField(
            label: '${context.tr('auth.username')}:',
            controller: _usernameController,
            focusNode: _usernameFocusNode,
            hintText: 'Seu usuário',
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.text,
            onConfirmedNext: () => _passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 10),

          // 3. Campo Senha
          _buildInputField(
            label: '${context.tr('auth.password')}:',
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            keyboardType: TextInputType.visiblePassword,
            onConfirmedNext: () => _connectFocusNode.requestFocus(),
          ),

          if (auth.errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.statusError.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.statusError.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 14, color: AppColors.statusError),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      auth.errorMessage!,
                      style: AppTypography.mono(fontSize: 10, color: AppColors.statusError),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // 4. Lembrar credenciais
          _buildRememberMeCheckbox(),

          const SizedBox(height: 14),

          // 5. Botão Conectar
          BrutalistButton(
            focusNode: _connectFocusNode,
            label: context.tr('auth.login_button'),
            icon: Icons.login_rounded,
            isLoading: auth.status == AuthStatus.authenticating,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  /// Banner de Atualização: Integrado diretamente na coluna de navegação D-pad
  Widget _buildUpdateBanner() {
    if (_isDownloadingUpdate) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border.all(color: AppColors.accentPrimary, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr('auth.downloading_update', args: {'progress': '${(_downloadProgress * 100).toInt()}'}),
                style: AppTypography.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentCyan,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _updateFocusNode,
      builder: (context, _) {
        final isFocused = _updateFocusNode.hasFocus;

        return Focus(
          focusNode: _updateFocusNode,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              final key = event.logicalKey;
              if (key == LogicalKeyboardKey.select ||
                  key == LogicalKeyboardKey.enter ||
                  key == LogicalKeyboardKey.numpadEnter ||
                  key == LogicalKeyboardKey.gameButtonA ||
                  key == LogicalKeyboardKey.space) {
                _startUpdate();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: InkWell(
            onTap: _startUpdate,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isFocused ? AppColors.accentCyan : AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFocused ? Colors.white : AppColors.accentCyan,
                  width: isFocused ? 2.0 : 1.2,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: AppColors.accentCyan.withValues(alpha: 0.5),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.system_update_rounded,
                    size: 16,
                    color: isFocused ? Colors.black : AppColors.accentCyan,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('auth.update_available', args: {'version': _updateInfo!.latestVersion}),
                      style: AppTypography.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isFocused ? Colors.black : AppColors.accentCyan,
                      ),
                    ),
                  ),
                  Text(
                    isFocused ? '[ OK: ATUALIZAR ]' : '[ ATUALIZAR ]',
                    style: AppTypography.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isFocused ? Colors.black : AppColors.accentCyan,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Campo de entrada navegável via D-pad sem disparar o teclado virtual involuntariamente.
  /// O teclado só abre quando o usuário pressionar o botão central (OK/Select) ou clicar.
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onConfirmedNext,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([focusNode, controller]),
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        final hasText = controller.text.isNotEmpty;
        final displayText = hasText
            ? (isPassword && _obscurePassword ? '••••••••' : controller.text)
            : hintText;

        return Focus(
          focusNode: focusNode,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              final key = event.logicalKey;
              // Pressionar o botão do MEIO (OK / Select / Enter / DpadCenter) abre o teclado para digitar
              if (key == LogicalKeyboardKey.select ||
                  key == LogicalKeyboardKey.enter ||
                  key == LogicalKeyboardKey.numpadEnter ||
                  key == LogicalKeyboardKey.gameButtonA ||
                  key == LogicalKeyboardKey.space) {
                _openEditModal(
                  title: label.replaceAll(':', ''),
                  hintText: hintText,
                  controller: controller,
                  prefixIcon: prefixIcon,
                  isPassword: isPassword,
                  keyboardType: keyboardType,
                  onConfirmed: onConfirmedNext,
                );
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: InkWell(
            onTap: () {
              _openEditModal(
                title: label.replaceAll(':', ''),
                hintText: hintText,
                controller: controller,
                prefixIcon: prefixIcon,
                isPassword: isPassword,
                keyboardType: keyboardType,
                onConfirmed: onConfirmedNext,
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: AppTypography.mono(
                        fontSize: 10,
                        fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
                        color: isFocused ? AppColors.accentCyan : AppColors.textPrimary,
                      ),
                    ),
                    if (isFocused)
                      Text(
                        '[ OK: DIGITAR ]',
                        style: AppTypography.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentCyan,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: isFocused ? AppColors.surfaceHover : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFocused ? AppColors.accentCyan : AppColors.borderHairline,
                      width: isFocused ? 2.0 : 1.0,
                    ),
                    boxShadow: isFocused
                        ? [
                            BoxShadow(
                              color: AppColors.accentCyan.withValues(alpha: 0.35),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        prefixIcon,
                        size: 16,
                        color: isFocused ? AppColors.accentCyan : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.mono(
                            fontSize: 12,
                            color: hasText
                                ? AppColors.textPrimary
                                : AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      if (isPassword)
                        IconButton(
                          focusNode: FocusNode(skipTraversal: true),
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: isFocused ? AppColors.accentCyan : AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRememberMeCheckbox() {
    return AnimatedBuilder(
      animation: _rememberFocusNode,
      builder: (context, _) {
        final isFocused = _rememberFocusNode.hasFocus;

        return Focus(
          focusNode: _rememberFocusNode,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              final key = event.logicalKey;
              if (key == LogicalKeyboardKey.select ||
                  key == LogicalKeyboardKey.enter ||
                  key == LogicalKeyboardKey.numpadEnter ||
                  key == LogicalKeyboardKey.space ||
                  key == LogicalKeyboardKey.gameButtonA) {
                setState(() => _rememberMe = !_rememberMe);
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: InkWell(
            onTap: () => setState(() => _rememberMe = !_rememberMe),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: isFocused ? Border.all(color: AppColors.accentCyan, width: 1.5) : null,
                color: isFocused ? AppColors.surfaceHover : Colors.transparent,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Checkbox(
                      focusNode: FocusNode(skipTraversal: true),
                      value: _rememberMe,
                      activeColor: AppColors.accentPrimary,
                      checkColor: Colors.white,
                      side: const BorderSide(color: AppColors.borderHairline, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('auth.remember_me'),
                    style: AppTypography.mono(
                      fontSize: 10,
                      color: isFocused ? AppColors.accentCyan : AppColors.textPrimary,
                    ),
                  ),
                  if (isFocused) ...[
                    const Spacer(),
                    Text(
                      '[ OK: ALTERAR ]',
                      style: AppTypography.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentCyan,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
