import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final baseColor = isDark
            ? AppColors.shimmerBaseDark
            : AppColors.shimmerBaseLight;
        final highlightColor = isDark
            ? AppColors.shimmerHighlightDark
            : AppColors.shimmerHighlightLight;

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: [0.0, _controller.value, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class MetricCardSkeleton extends StatelessWidget {
  const MetricCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonLoader(width: 32, height: 32, borderRadius: 16),
                SkeletonLoader(width: 12, height: 12, borderRadius: 6),
              ],
            ),
            SizedBox(height: 16),
            SkeletonLoader(width: 100, height: 24, borderRadius: 6),
            SizedBox(height: 8),
            SkeletonLoader(width: 80, height: 14, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}
