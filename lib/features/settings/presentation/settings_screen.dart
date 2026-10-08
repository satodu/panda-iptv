import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/brutalist_button.dart';
import '../../../core/widgets/hanko_badge.dart';
import '../../../core/widgets/tech_crosses.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../vod/presentation/vod_provider.dart';
import '../../series/presentation/series_provider.dart';
import '../../live/presentation/live_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _githubUrl = 'https://github.com/satodu/panda-iptv';
  static const String _pixKey = 'sato.du@gmail.com';
  static const String _kofiUrl = 'https://ko-fi.com/retro_panda';

  String _formatExpDate(String expDate) {
    if (expDate.isEmpty) return 'ILIMITADO';
    final timestamp = int.tryParse(expDate);
    if (timestamp != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return expDate;
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final copiedMsg = context.tr('settings.copied_url');
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        await Clipboard.setData(ClipboardData(text: url));
        if (context.mounted) {
          AppToast.info(context, copiedMsg);
        }
      }
    } catch (_) {
      if (context.mounted) {
        await Clipboard.setData(ClipboardData(text: url));
        if (context.mounted) {
          AppToast.info(context, copiedMsg);
        }
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String successMessage) {
    Clipboard.setData(ClipboardData(text: text));
    AppToast.success(context, successMessage);
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentAccount?.userInfo;
    final server = auth.currentAccount?.serverInfo;
    final localeProvider = context.watch<LocaleProvider>();
    final currentLang = localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          context.tr('settings.title'),
                          style: AppTypography.titleMedium(
                            color: AppColors.textPrimary,
                            fontSize: isNarrow ? 15 : 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                        HankoBadge(
                          text: context.tr('settings.badge'),
                          borderColor: AppColors.accentPrimary,
                          textColor: AppColors.accentPrimary,
                        ),
                      ],
                    ),
                  ),
                  if (!isNarrow) ...[
                    const TechCrosses(count: 3, opacity: 0.3),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),

            const Divider(color: AppColors.borderHairline, height: 1),

            // Conteúdo de Configurações
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 16 : 24,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. SEÇÃO DE SERVIDOR & CONEXÃO
                        Text(
                          context.tr('settings.server_section'),
                          style: AppTypography.sectionTitle(fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        BentoCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.dns_rounded, size: 20, color: AppColors.accentCyan),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.tr('settings.current_server'),
                                        style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                  const HankoBadge(
                                    text: 'ONLINE',
                                    borderColor: AppColors.statusLive,
                                    textColor: AppColors.statusLive,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                auth.currentAccount?.serverUrl ?? server?.url ?? 'http://127.0.0.1:8080',
                                style: AppTypography.mono(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (isNarrow) ...[
                                Row(
                                  children: [
                                    Text(
                                      '${context.tr('settings.connected_as')}: ',
                                      style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                    Expanded(
                                      child: Text(
                                        user?.username ?? 'root',
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.mono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accentPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (user?.expDate != null && user!.expDate.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '// ${context.tr('settings.expires')}: ',
                                        style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                      Text(
                                        _formatExpDate(user.expDate),
                                        style: AppTypography.mono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accentCyan,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ] else ...[
                                Row(
                                  children: [
                                    Text(
                                      '${context.tr('settings.connected_as')}: ',
                                      style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                    Text(
                                      user?.username ?? 'root',
                                      style: AppTypography.mono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accentPrimary,
                                      ),
                                    ),
                                    if (user?.expDate != null && user!.expDate.isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        '// ${context.tr('settings.expires')}: ${_formatExpDate(user.expDate)}',
                                        style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              BrutalistButton(
                                label: context.tr('settings.change_server'),
                                isSecondary: true,
                                icon: Icons.sync_alt_rounded,
                                onPressed: () {
                                  context.read<VodProvider>().clear();
                                  context.read<SeriesProvider>().clear();
                                  context.read<LiveProvider>().clear();
                                  auth.logout();
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // 2. SEÇÃO DE IDIOMA DO SISTEMA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('settings.language_section'),
                              style: AppTypography.sectionTitle(fontSize: 14),
                            ),
                            HankoBadge(
                              text: context.tr('settings.language_badge'),
                              borderColor: AppColors.borderHairline,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 600;
                            return GridView.count(
                              crossAxisCount: isMobile ? 1 : 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: isMobile ? 3.8 : 2.2,
                              children: [
                                _buildLanguageCard(
                                  context: context,
                                  flag: '🇧🇷',
                                  label: context.tr('settings.lang_pt'),
                                  code: 'pt',
                                  isActive: currentLang == 'pt',
                                  onTap: () => localeProvider.setPortuguese(),
                                ),
                                _buildLanguageCard(
                                  context: context,
                                  flag: '🇺🇸',
                                  label: context.tr('settings.lang_en'),
                                  code: 'en',
                                  isActive: currentLang == 'en',
                                  onTap: () => localeProvider.setEnglish(),
                                ),
                                _buildLanguageCard(
                                  context: context,
                                  flag: '🇪🇸',
                                  label: context.tr('settings.lang_es'),
                                  code: 'es',
                                  isActive: currentLang == 'es',
                                  onTap: () => localeProvider.setSpanish(),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 28),

                        // 3. SEÇÃO SOBRE O PROJETO (ABOUT)
                        Text(
                          context.tr('settings.about_section'),
                          style: AppTypography.sectionTitle(fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        BentoCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.tr('settings.app_name'),
                                          style: AppTypography.titleMedium(
                                            color: AppColors.textPrimary,
                                            fontSize: 17,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ORIENTAL BRUTALIST MINIMALIST IPTV',
                                          style: AppTypography.mono(fontSize: 10, color: AppColors.accentCyan),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const HankoBadge(
                                    text: 'v0.0.2',
                                    borderColor: AppColors.accentPrimary,
                                    textColor: AppColors.accentPrimary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.canvas,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderHairline),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.code_rounded, size: 18, color: AppColors.textMuted),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _githubUrl,
                                        style: AppTypography.mono(fontSize: 12, color: AppColors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Copiar link',
                                      icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textMuted),
                                      onPressed: () => _copyToClipboard(
                                        context,
                                        _githubUrl,
                                        context.tr('settings.copied_url'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: BrutalistButton(
                                  label: context.tr('settings.github_label'),
                                  isSecondary: true,
                                  icon: Icons.open_in_new_rounded,
                                  onPressed: () => _openUrl(context, _githubUrl),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // 4. SEÇÃO DE DOAÇÃO & APOIO
                        Text(
                          context.tr('settings.donation_section'),
                          style: AppTypography.sectionTitle(fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        BentoCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusLive.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.statusLive.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: const Icon(Icons.favorite_rounded, size: 20, color: AppColors.statusLive),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'APOIE O DESENVOLVIMENTO.',
                                          style: AppTypography.titleMedium(fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          context.tr('settings.donation_subtitle'),
                                          style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.canvas,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderHairline),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.pix_rounded, size: 20, color: AppColors.accentCyan),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'CHAVE PIX (E-MAIL):',
                                            style: AppTypography.mono(fontSize: 9, color: AppColors.textMuted),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _pixKey,
                                            style: AppTypography.mono(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Copiar Chave PIX',
                                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.accentPrimary),
                                      onPressed: () => _copyToClipboard(
                                        context,
                                        _pixKey,
                                        context.tr('settings.pix_copied'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  SizedBox(
                                    width: isNarrow ? double.infinity : 220,
                                    child: BrutalistButton(
                                      label: context.tr('settings.donation_pix'),
                                      icon: Icons.copy_rounded,
                                      onPressed: () => _copyToClipboard(
                                        context,
                                        _pixKey,
                                        context.tr('settings.pix_copied'),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isNarrow ? double.infinity : 220,
                                    child: BrutalistButton(
                                      label: context.tr('settings.donation_kofi'),
                                      isSecondary: true,
                                      icon: Icons.coffee_rounded,
                                      onPressed: () => _openUrl(context, _kofiUrl),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isNarrow ? double.infinity : 220,
                                    child: BrutalistButton(
                                      label: context.tr('settings.donation_github'),
                                      isSecondary: true,
                                      icon: Icons.volunteer_activism_rounded,
                                      onPressed: () => _openUrl(context, _githubUrl),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Rodapé
                        Center(
                          child: Column(
                            children: [
                              const TechCrosses(count: 5, opacity: 0.25),
                              const SizedBox(height: 8),
                              Text(
                                'PANDA IPTV // MIT LICENSE // COPYRIGHT 2026',
                                style: AppTypography.mono(fontSize: 10, color: AppColors.textDisabled),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required String flag,
    required String label,
    required String code,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return BentoCard(
      isSelected: isActive,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.mono(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                      Text(
                        code.toUpperCase(),
                        style: AppTypography.mono(
                          fontSize: 9,
                          color: isActive ? AppColors.accentCyan : AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 6),
            HankoBadge(
              text: context.tr('settings.active_tag'),
              borderColor: AppColors.accentPrimary,
              textColor: AppColors.accentPrimary,
            ),
          ],
        ],
      ),
    );
  }
}
