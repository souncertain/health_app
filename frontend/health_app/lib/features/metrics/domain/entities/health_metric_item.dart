import 'package:flutter/material.dart';

enum MetricSeverity { normal, monitor, critical }

enum MetricTrend { down, stable, up }

class HealthMetricItem {
  const HealthMetricItem({
    required this.title,
    required this.value,
    required this.unit,
    required this.target,
    required this.progress,
    required this.accentColor,
    required this.iconBackground,
    required this.icon,
    required this.severity,
    required this.trend,
    required this.sparkline,
  });

  final String title;
  final String value;
  final String unit;
  final String target;
  final double progress;
  final Color accentColor;
  final Color iconBackground;
  final IconData icon;
  final MetricSeverity severity;
  final MetricTrend trend;
  final List<double> sparkline;
}
