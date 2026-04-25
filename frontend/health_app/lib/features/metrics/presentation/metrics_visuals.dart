import 'package:flutter/material.dart';

import '../domain/entities/health_metric_item.dart';

class MetricVisualPalette {
  const MetricVisualPalette({
    required this.accentColor,
    required this.iconBackground,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final Color accentColor;
  final Color iconBackground;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;

  static MetricVisualPalette fromStyle(MetricVisualStyle style) {
    switch (style) {
      case MetricVisualStyle.amberDrop:
        return const MetricVisualPalette(
          accentColor: Color(0xFFE68614),
          iconBackground: Color(0xFFFFF0BE),
          icon: Icons.opacity_rounded,
          gradientStart: Color(0xFFFFC56D),
          gradientEnd: Color(0xFFE68614),
        );
      case MetricVisualStyle.redCircle:
        return const MetricVisualPalette(
          accentColor: Color(0xFFEF2D2D),
          iconBackground: Color(0xFFFFE1E1),
          icon: Icons.circle,
          gradientStart: Color(0xFFFF7C7C),
          gradientEnd: Color(0xFFEF2D2D),
        );
      case MetricVisualStyle.violetHeart:
        return const MetricVisualPalette(
          accentColor: Color(0xFF7C3AED),
          iconBackground: Color(0xFFEDE8FF),
          icon: Icons.favorite_rounded,
          gradientStart: Color(0xFFA78BFA),
          gradientEnd: Color(0xFF7C3AED),
        );
      case MetricVisualStyle.cyanBalance:
        return const MetricVisualPalette(
          accentColor: Color(0xFF1595C9),
          iconBackground: Color(0xFFDDF6FF),
          icon: Icons.balance_rounded,
          gradientStart: Color(0xFF6ED0F5),
          gradientEnd: Color(0xFF1595C9),
        );
      case MetricVisualStyle.emeraldPulse:
        return const MetricVisualPalette(
          accentColor: Color(0xFF11A648),
          iconBackground: Color(0xFFE7FAEE),
          icon: Icons.favorite_border_rounded,
          gradientStart: Color(0xFF5EDD90),
          gradientEnd: Color(0xFF11A648),
        );
      case MetricVisualStyle.coralSun:
        return const MetricVisualPalette(
          accentColor: Color(0xFFF97316),
          iconBackground: Color(0xFFFFE6D5),
          icon: Icons.wb_sunny_outlined,
          gradientStart: Color(0xFFFDA85F),
          gradientEnd: Color(0xFFF97316),
        );
    }
  }
}
