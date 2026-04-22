import 'package:flutter/material.dart';

import '../../domain/entities/health_metric_item.dart';

class MetricsPage extends StatelessWidget {
  const MetricsPage({super.key});

  static const List<HealthMetricItem> _metrics = [
    HealthMetricItem(
      title: 'Blood Sugar',
      value: '98',
      unit: 'mg/dL',
      target: 'Target: 70-100 mg/dL',
      progress: 0.93,
      accentColor: Color(0xFFE68614),
      iconBackground: Color(0xFFFFF0BE),
      icon: Icons.opacity_rounded,
      severity: MetricSeverity.normal,
      trend: MetricTrend.down,
      sparkline: [0.70, 0.60, 0.66, 0.52, 0.44, 0.56, 0.50],
    ),
    HealthMetricItem(
      title: 'Hemoglobin',
      value: '13.8',
      unit: 'g/dL',
      target: 'Target: 12-17.5 g/dL',
      progress: 0.33,
      accentColor: Color(0xFFEF2D2D),
      iconBackground: Color(0xFFFFE1E1),
      icon: Icons.circle,
      severity: MetricSeverity.normal,
      trend: MetricTrend.stable,
      sparkline: [0.44, 0.48, 0.46, 0.50, 0.49, 0.52, 0.51],
    ),
    HealthMetricItem(
      title: 'Cholesterol',
      value: '185',
      unit: 'mg/dL',
      target: 'Target: 0-200 mg/dL',
      progress: 0.92,
      accentColor: Color(0xFF7C3AED),
      iconBackground: Color(0xFFEDE8FF),
      icon: Icons.favorite_rounded,
      severity: MetricSeverity.normal,
      trend: MetricTrend.down,
      sparkline: [0.66, 0.62, 0.58, 0.54, 0.53, 0.54, 0.52],
    ),
    HealthMetricItem(
      title: 'BMI',
      value: '23.4',
      unit: 'kg/m2',
      target: 'Target: 18.5-24.9 kg/m2',
      progress: 0.76,
      accentColor: Color(0xFF1595C9),
      iconBackground: Color(0xFFDDF6FF),
      icon: Icons.balance_rounded,
      severity: MetricSeverity.normal,
      trend: MetricTrend.stable,
      sparkline: [0.54, 0.53, 0.52, 0.51, 0.50, 0.51, 0.50],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 390;
    final horizontalPadding = isCompact ? 16.0 : 20.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFFBF2), Color(0xFFF8FFFA)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetricsHeader(
                    isCompact: isCompact,
                    horizontalPadding: horizontalPadding,
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      26,
                      horizontalPadding,
                      0,
                    ),
                    child: Column(
                      children: _metrics
                          .map(
                            (metric) => Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _MetricCard(
                                metric: metric,
                                compact: isCompact,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      148,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B38F6),
                          foregroundColor: Colors.white,
                          elevation: 10,
                          shadowColor: const Color(
                            0xFF8B38F6,
                          ).withValues(alpha: 0.28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isCompact ? 18 : 21,
                          ),
                        ),
                        icon: Icon(
                          Icons.add_rounded,
                          size: isCompact ? 26 : 30,
                        ),
                        label: Text(
                          'Add Custom Metric',
                          style: TextStyle(
                            fontSize: isCompact ? 16 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsHeader extends StatelessWidget {
  const _MetricsHeader({
    required this.isCompact,
    required this.horizontalPadding,
  });

  final bool isCompact;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [Color(0xFF7A34F2), Color(0xFFA73CF6)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          28,
          horizontalPadding,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Metrics',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: isCompact ? 15 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your Numbers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 28 : 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _MetricsStatusChip(
                  label: '3 Normal',
                  background: Color(0xFFE9FBEF),
                  foreground: Color(0xFF10A647),
                ),
                _MetricsStatusChip(
                  label: '1 Monitor',
                  background: Color(0xFFFFF2C9),
                  foreground: Color(0xFFE88A0C),
                ),
                _MetricsStatusChip(
                  label: '0 Critical',
                  background: Color(0xFFFFE5E6),
                  foreground: Color(0xFFEF4444),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsStatusChip extends StatelessWidget {
  const _MetricsStatusChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, required this.compact});

  final HealthMetricItem metric;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 22,
        compact ? 20 : 24,
        compact ? 18 : 22,
        compact ? 20 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD5EFD9).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: metric.iconBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(metric.icon, color: metric.accentColor, size: 38),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            metric.title,
                            style: TextStyle(
                              color: const Color(0xFF0C1C46),
                              fontSize: compact ? 18 : 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          _trendIcon(metric.trend),
                          color: metric.trend == MetricTrend.down
                              ? const Color(0xFF11A648)
                              : const Color(0xFF94A8C7),
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: metric.value,
                            style: TextStyle(
                              color: metric.accentColor,
                              fontSize: compact ? 24 : 28,
                              fontWeight: FontWeight.w800,
                            ),
                            children: [
                              TextSpan(
                                text: ' ${metric.unit}',
                                style: TextStyle(
                                  color: const Color(0xFF8DA2C0),
                                  fontSize: compact ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const _MetricSeverityBadge(label: 'Normal'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  SizedBox(
                    width: 96,
                    height: 32,
                    child: _MetricSparkline(
                      values: metric.sparkline,
                      color: metric.accentColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFA2B3CC),
                    size: 28,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              metric.target,
              style: TextStyle(
                color: const Color(0xFF8DA2C0),
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: metric.progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8EEF7),
              valueColor: AlwaysStoppedAnimation<Color>(metric.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  IconData _trendIcon(MetricTrend trend) {
    switch (trend) {
      case MetricTrend.down:
        return Icons.trending_down_rounded;
      case MetricTrend.stable:
        return Icons.remove_rounded;
      case MetricTrend.up:
        return Icons.trending_up_rounded;
    }
  }
}

class _MetricSeverityBadge extends StatelessWidget {
  const _MetricSeverityBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE6FBEA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF10A647),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricSparkline extends StatelessWidget {
  const _MetricSparkline({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MetricSparklinePainter(values: values, color: color),
    );
  }
}

class _MetricSparklinePainter extends CustomPainter {
  const _MetricSparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MetricSparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
