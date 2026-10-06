import 'package:flutter/material.dart';

/// Animação de entrada sutil e elegante no estilo Oriental Brutalismo
/// Realiza um fade-in e slide vertical suave em cascata.
class BrutalistEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDuration;
  final int staggerMs;

  const BrutalistEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDuration = const Duration(milliseconds: 320),
    this.staggerMs = 35,
  });

  @override
  State<BrutalistEntrance> createState() => _BrutalistEntranceState();
}

class _BrutalistEntranceState extends State<BrutalistEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.baseDuration,
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    final delay = Duration(milliseconds: (widget.index * widget.staggerMs).clamp(0, 450));
    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: widget.child,
      ),
    );
  }
}
