import 'package:flutter/material.dart';

/// A reusable card widget that paints a gradient background.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.gradient,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(24),
    this.shadows,
  });

  final LinearGradient gradient;
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}
