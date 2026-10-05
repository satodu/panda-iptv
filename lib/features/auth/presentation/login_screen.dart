import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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
  bool _obscurePassword = true;
  bool _rememberMe = true;

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
    });
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final server = _serverController.text.trim();
    final user = _usernameController.text.trim();
    final pass = _passwordController.text.trim();

    if (server.isEmpty || user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.statusError,
          content: Text('Preencha servidor, usuário e senha.'),
        ),
      );
      return;
    }

    context.read<AuthProvider>().login(
          serverUrl: server,
          username: user,
          password: pass,
          rememberMe: _rememberMe,
        );
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
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isLandscape ? 920 : 460,
              ),
              child: isLandscape && screenWidth > 720
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _buildBrandingPanel()),
                        const SizedBox(width: 32),
                        Expanded(child: _buildFormCard()),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBrandingPanel(isCompact: true),
                        const SizedBox(height: 24),
                        _buildFormCard(),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingPanel({bool isCompact = false}) {
    return Column(
      crossAxisAlignment: isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderHairline),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              width: isCompact ? 72 : 96,
              height: isCompact ? 72 : 96,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.accentPrimary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const HankoBadge(text: 'XTREAM // V2.0', borderColor: AppColors.accentCyan),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'PANDA IPTV.',
          textAlign: isCompact ? TextAlign.center : TextAlign.start,
          style: AppTypography.displayLarge(),
        ),
        const SizedBox(height: 8),
        Text(
          'SISTEMA DE TRANSMISSÃO E MÍDIA.',
          textAlign: isCompact ? TextAlign.center : TextAlign.start,
          style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        const TechCrosses(count: 6, spacing: 10),
        if (!isCompact) ...[
          const SizedBox(height: 32),
          Text(
            'パンダ // 放送メディア',
            style: AppTypography.orientalAccent(fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildFormCard() {
    final auth = context.watch<AuthProvider>();

    return BentoCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AUTENTICAÇÃO.',
                style: AppTypography.sectionTitle(),
              ),
              const TechCrosses(count: 3, opacity: 0.3),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Insira as credenciais do seu provedor.',
            style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          // Campo: Servidor
          Text('SERVIDOR / PORTA:', style: AppTypography.mono(fontSize: 11)),
          const SizedBox(height: 6),
          TextField(
            controller: _serverController,
            style: AppTypography.mono(fontSize: 13, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'http://dns-do-provedor.xyz:8080',
              prefixIcon: Icon(Icons.dns_outlined, size: 18, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),

          // Campo: Usuário
          Text('USUÁRIO:', style: AppTypography.mono(fontSize: 11)),
          const SizedBox(height: 6),
          TextField(
            controller: _usernameController,
            style: AppTypography.mono(fontSize: 13, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Seu usuário',
              prefixIcon: Icon(Icons.person_outline, size: 18, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),

          // Campo: Senha
          Text('SENHA:', style: AppTypography.mono(fontSize: 11)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: AppTypography.mono(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),

          if (auth.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusError.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.statusError.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.statusError),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      auth.errorMessage!,
                      style: AppTypography.mono(fontSize: 11, color: AppColors.statusError),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Lembrar credenciais
          InkWell(
            onTap: () => setState(() => _rememberMe = !_rememberMe),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.accentPrimary,
                      checkColor: Colors.white,
                      side: const BorderSide(color: AppColors.borderHairline, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'LEMBRAR DADOS DE ACESSO.',
                    style: AppTypography.mono(fontSize: 11, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          BrutalistButton(
            label: 'CONECTAR AO SERVIDOR.',
            icon: Icons.login_rounded,
            isLoading: auth.status == AuthStatus.authenticating,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
