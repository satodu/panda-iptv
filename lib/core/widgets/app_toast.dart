import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'tech_crosses.dart';

enum ToastType {
  info,
  success,
  error,
  favorite,
}

/// Toast Flutuante no estilo Oriental Brutalismo
/// Substitui o SnackBar convencional que sobe como bottom sheet.
class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);

    Color borderColor;
    Color iconColor;
    IconData defaultIcon;

    switch (type) {
      case ToastType.success:
        borderColor = AppColors.statusLive;
        iconColor = AppColors.statusLive;
        defaultIcon = Icons.check_circle_outline_rounded;
        break;
      case ToastType.error:
        borderColor = AppColors.statusError;
        iconColor = AppColors.statusError;
        defaultIcon = Icons.error_outline_rounded;
        break;
      case ToastType.favorite:
        borderColor = AppColors.accentCyan;
        iconColor = AppColors.accentCyan;
        defaultIcon = Icons.star_rounded;
        break;
      case ToastType.info:
        borderColor = AppColors.accentPrimary;
        iconColor = AppColors.accentPrimary;
        defaultIcon = Icons.info_outline_rounded;
        break;
    }

    final formattedMessage = AppTypography.formatTitle(message);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: formattedMessage,
        icon: icon ?? defaultIcon,
        borderColor: borderColor,
        iconColor: iconColor,
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }

  static void info(BuildContext context, String message) {
    show(context, message, type: ToastType.info);
  }

  static void success(BuildContext context, String message) {
    show(context, message, type: ToastType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message, type: ToastType.error);
  }

  static void favorite(BuildContext context, String message) {
    show(context, message, type: ToastType.favorite);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color borderColor;
  final Color iconColor;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.icon,
    required this.borderColor,
    required this.iconColor,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 16.0;

    return Positioned(
      top: topPadding,
      left: 20,
      right: 20,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: widget.borderColor.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 20, color: widget.iconColor),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: AppTypography.titleMedium(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const TechCrosses(count: 3, opacity: 0.25, spacing: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
