import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Componente de Skeleton Shimmer no estilo Oriental Brutalismo Minimalista.
/// Fornece placeholders animados que ocupam exatamente o mesmo layout e dimensões
/// dos cards reais para prevenir layout shifts durante o carregamento.
class BrutalistSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const BrutalistSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 10.0,
    this.margin,
  });

  /// Constrói um card de filme no formato exato dos cards de VOD (poster + títulos)
  static Widget movieCard({
    double width = 125,
    double height = 220,
    double borderRadius = 10,
  }) {
    return _MovieCardSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  /// Constrói uma lista horizontal de cards de filme skeleton exatamente com o mesmo
  /// espaçamento e altura do carrossel de filmes relacionados.
  static Widget horizontalCarousel({
    int count = 6,
    double itemWidth = 125,
    double height = 220,
    EdgeInsetsGeometry? padding,
  }) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => movieCard(width: itemWidth, height: height),
      ),
    );
  }

  @override
  State<BrutalistSkeleton> createState() => _BrutalistSkeletonState();
}

class _BrutalistSkeletonState extends State<BrutalistSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final color = Color.lerp(
          AppColors.surfaceCard,
          AppColors.surfaceHover,
          _animation.value,
        );

        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: AppColors.borderHairline,
              width: 1,
            ),
          ),
        );
      },
    );
  }
}

class _MovieCardSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _MovieCardSkeleton({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_MovieCardSkeleton> createState() => _MovieCardSkeletonState();
}

class _MovieCardSkeletonState extends State<_MovieCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final baseColor = Color.lerp(
          AppColors.surfaceCard,
          AppColors.surfaceHover,
          _animation.value,
        )!;

        final highlightColor = Color.lerp(
          AppColors.surfaceHover,
          const Color(0xFF242E38),
          _animation.value,
        )!;

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: AppColors.borderHairline,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Área do Poster
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: highlightColor.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(widget.borderRadius - 1),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: highlightColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
              // Área dos Textos / Metadados
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: widget.width * 0.75,
                      decoration: BoxDecoration(
                        color: highlightColor.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 8,
                      width: widget.width * 0.45,
                      decoration: BoxDecoration(
                        color: highlightColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
