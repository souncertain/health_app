import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/layout/app_layout_constants.dart';
import '../../data/datasources/health_metrics_local_data_source.dart';
import '../../data/datasources/health_metrics_remote_data_source.dart';
import '../../data/repositories/backend_health_metric_repository.dart';
import '../../domain/entities/health_metric_item.dart';
import '../../domain/repositories/health_metric_repository.dart';
import '../../domain/usecases/delete_health_metric.dart';
import '../../domain/usecases/get_cached_health_metrics.dart';
import '../../domain/usecases/get_health_metrics.dart';
import '../../domain/usecases/save_health_metric.dart';
import '../controllers/metrics_controller.dart';
import '../metrics_visuals.dart';
import '../widgets/custom_metric_sheet.dart';
import '../widgets/log_metric_value_sheet.dart';

class MetricsPage extends StatefulWidget {
  const MetricsPage({super.key, this.repository});

  final HealthMetricRepository? repository;

  @override
  State<MetricsPage> createState() => MetricsPageState();
}

class MetricsPageState extends State<MetricsPage> {
  late final MetricsController _controller;
  String? _expandedMetricId;

  @override
  void initState() {
    super.initState();
    final repository =
        widget.repository ??
        BackendHealthMetricRepository(
          localDataSource: HealthMetricsLocalDataSource(),
          remoteDataSource: HealthMetricsRemoteDataSource(),
        );
    _controller = MetricsController(
      getCachedMetrics: GetCachedHealthMetricsUseCase(repository),
      getMetrics: GetHealthMetricsUseCase(repository),
      saveMetric: SaveHealthMetricUseCase(repository),
      deleteMetric: DeleteHealthMetricUseCase(repository),
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCreateMetricSheet() {
    return showCustomMetricSheet(
      context: context,
      onSubmit: (value) async {
        final createdId = await _controller.createCustomMetric(
          title: value.name,
          unit: value.unit,
          targetMin: value.targetMin,
          targetMax: value.targetMax,
        );
        if (mounted) {
          setState(() {
            _expandedMetricId = createdId;
          });
        }
      },
    );
  }

  Future<void> _openEditMetricSheet(HealthMetricItem metric) {
    return showCustomMetricSheet(
      context: context,
      initialValue: CustomMetricFormValue(
        name: metric.title,
        unit: metric.unit,
        targetMin: metric.targetMin,
        targetMax: metric.targetMax,
      ),
      onSubmit: (value) {
        return _controller.updateMetricDetails(
          metric: metric,
          title: value.name,
          unit: value.unit,
          targetMin: value.targetMin,
          targetMax: value.targetMax,
        );
      },
      onDelete: () async {
        await _controller.deleteMetric(metric);
        if (mounted && _expandedMetricId == metric.id) {
          setState(() {
            _expandedMetricId = null;
          });
        }
      },
    );
  }

  Future<void> _openLogValueSheet(HealthMetricItem metric) {
    return showLogMetricValueSheet(
      context: context,
      metric: metric,
      onSubmit: (value) {
        return _controller.logMetricValue(
          metric: metric,
          value: value.value,
          recordedOn: value.recordedOn,
        );
      },
    );
  }

  Future<void> openQuickLogMetricSheet() async {
    await _controller.initialize();
    final metrics = _controller.metrics;

    if (metrics.isEmpty) {
      return _openCreateMetricSheet();
    }

    if (metrics.length == 1) {
      if (mounted) {
        setState(() {
          _expandedMetricId = metrics.first.id;
        });
      }
      return _openLogValueSheet(metrics.first);
    }

    final selectedMetric = await _showMetricPickerSheet(metrics);
    if (selectedMetric == null || !mounted) {
      return;
    }

    setState(() {
      _expandedMetricId = selectedMetric.id;
    });
    return _openLogValueSheet(selectedMetric);
  }

  void _toggleExpanded(String metricId) {
    setState(() {
      _expandedMetricId = _expandedMetricId == metricId ? null : metricId;
    });
  }

  Future<HealthMetricItem?> _showMetricPickerSheet(
    List<HealthMetricItem> metrics,
  ) {
    return showModalBottomSheet<HealthMetricItem>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.74,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Выберите метрику',
                    style: TextStyle(
                      color: Color(0xFF12203F),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: metrics.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final metric = metrics[index];
                        final visuals = MetricVisualPalette.fromStyle(
                          metric.visualStyle,
                        );
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          tileColor: const Color(0xFFF7FBFF),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: visuals.iconBackground,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              visuals.icon,
                              color: visuals.accentColor,
                            ),
                          ),
                          title: Text(
                            metric.title,
                            style: const TextStyle(
                              color: Color(0xFF12203F),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            metric.unit,
                            style: const TextStyle(
                              color: Color(0xFF8DA2C0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF8FA1BC),
                          ),
                          onTap: () => Navigator.of(context).pop(metric),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final metrics = _controller.metrics;

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MetricsHeader(
                            isCompact: isCompact,
                            horizontalPadding: horizontalPadding,
                            normalCount: _controller.countBySeverity(
                              MetricSeverity.normal,
                            ),
                            monitorCount: _controller.countBySeverity(
                              MetricSeverity.monitor,
                            ),
                            criticalCount: _controller.countBySeverity(
                              MetricSeverity.critical,
                            ),
                          ),
                          if (metrics.isEmpty)
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                26,
                                horizontalPadding,
                                kPageBottomOverlayPadding,
                              ),
                              child: _EmptyMetricsState(
                                onPressed: _openCreateMetricSheet,
                              ),
                            )
                          else ...[
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                26,
                                horizontalPadding,
                                0,
                              ),
                              child: Column(
                                children: metrics
                                    .map(
                                      (metric) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 20,
                                        ),
                                        child: _MetricCard(
                                          metric: metric,
                                          compact: isCompact,
                                          expanded:
                                              _expandedMetricId == metric.id,
                                          latestValue: _controller
                                              .latestValueForMetric(metric),
                                          severity: _controller
                                              .severityForMetric(metric),
                                          trend: _controller.trendForMetric(
                                            metric,
                                          ),
                                          progress: _controller
                                              .progressForMetric(metric),
                                          sparkline: _controller
                                              .sparklineValuesForMetric(metric),
                                          history: _controller.historyForMetric(
                                            metric,
                                          ),
                                          hasRenderableHistory: _controller
                                              .hasRenderableHistory(metric),
                                          onTap: () =>
                                              _toggleExpanded(metric.id),
                                          onLongPress: () =>
                                              _openEditMetricSheet(metric),
                                          onLogValue: () =>
                                              _openLogValueSheet(metric),
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
                                kPageBottomOverlayPadding,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _openCreateMetricSheet,
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
                                    'Добавить свою метрику',
                                    style: TextStyle(
                                      fontSize: isCompact ? 16 : 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (_controller.isLoading && metrics.isEmpty)
                  const Center(child: CircularProgressIndicator()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricsHeader extends StatelessWidget {
  const _MetricsHeader({
    required this.isCompact,
    required this.horizontalPadding,
    required this.normalCount,
    required this.monitorCount,
    required this.criticalCount,
  });

  final bool isCompact;
  final double horizontalPadding;
  final int normalCount;
  final int monitorCount;
  final int criticalCount;

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
                        'Показатели здоровья',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: isCompact ? 15 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ваши показатели',
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
              children: [
                _MetricsStatusChip(
                  label: '$normalCount Норма',
                  background: const Color(0xFFE9FBEF),
                  foreground: const Color(0xFF10A647),
                ),
                _MetricsStatusChip(
                  label: '$monitorCount Контроль',
                  background: const Color(0xFFFFF2C9),
                  foreground: const Color(0xFFE88A0C),
                ),
                _MetricsStatusChip(
                  label: '$criticalCount Критично',
                  background: const Color(0xFFFFE5E6),
                  foreground: const Color(0xFFEF4444),
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
  const _MetricCard({
    required this.metric,
    required this.compact,
    required this.expanded,
    required this.latestValue,
    required this.severity,
    required this.trend,
    required this.progress,
    required this.sparkline,
    required this.history,
    required this.hasRenderableHistory,
    required this.onTap,
    required this.onLongPress,
    required this.onLogValue,
  });

  final HealthMetricItem metric;
  final bool compact;
  final bool expanded;
  final double? latestValue;
  final MetricSeverity severity;
  final MetricTrend trend;
  final double progress;
  final List<double> sparkline;
  final List<MetricHistoryDay> history;
  final bool hasRenderableHistory;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onLogValue;

  @override
  Widget build(BuildContext context) {
    final visuals = MetricVisualPalette.fromStyle(metric.visualStyle);
    final severityPresentation = _MetricSeverityPresentation.fromSeverity(
      severity,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
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
                      color: visuals.iconBackground,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      visuals.icon,
                      color: visuals.accentColor,
                      size: 38,
                    ),
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF0C1C46),
                                  fontSize: compact ? 18 : 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Icon(
                              _trendIcon(trend),
                              color: _trendColor(trend),
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
                                text: latestValue == null
                                    ? '--'
                                    : _formatMetricNumber(latestValue!),
                                style: TextStyle(
                                  color: visuals.accentColor,
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
                            _MetricSeverityBadge(
                              presentation: severityPresentation,
                            ),
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
                          values: sparkline,
                          color: visuals.accentColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.chevron_right_rounded,
                        color: const Color(0xFFA2B3CC),
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
                  'Цель: '
                  '${_formatMetricNumber(metric.targetMin)}-'
                  '${_formatMetricNumber(metric.targetMax)} ${metric.unit}',
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
                  value: progress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE8EEF7),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    visuals.accentColor,
                  ),
                ),
              ),
              if (expanded) ...[
                const SizedBox(height: 22),
                const Divider(height: 1, color: Color(0xFFE8EEF7)),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'История за 7 дней',
                    style: TextStyle(
                      color: const Color(0xFF4F6382),
                      fontSize: compact ? 18 : 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _MetricHistoryChart(
                  history: history,
                  targetMin: metric.targetMin,
                  targetMax: metric.targetMax,
                  color: visuals.accentColor,
                  hasRenderableHistory: hasRenderableHistory,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onLogValue,
                    style: FilledButton.styleFrom(
                      backgroundColor: visuals.iconBackground,
                      foregroundColor: visuals.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Записать значение',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
      case MetricTrend.none:
        return Icons.remove_rounded;
    }
  }

  Color _trendColor(MetricTrend trend) {
    switch (trend) {
      case MetricTrend.down:
        return const Color(0xFF11A648);
      case MetricTrend.up:
        return const Color(0xFFE88A0C);
      case MetricTrend.stable:
      case MetricTrend.none:
        return const Color(0xFF94A8C7);
    }
  }
}

class _MetricSeverityPresentation {
  const _MetricSeverityPresentation({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  factory _MetricSeverityPresentation.fromSeverity(MetricSeverity severity) {
    switch (severity) {
      case MetricSeverity.normal:
        return const _MetricSeverityPresentation(
          label: 'Норма',
          foreground: Color(0xFF10A647),
          background: Color(0xFFE6FBEA),
        );
      case MetricSeverity.monitor:
        return const _MetricSeverityPresentation(
          label: 'Контроль',
          foreground: Color(0xFFE88A0C),
          background: Color(0xFFFFF2C9),
        );
      case MetricSeverity.critical:
        return const _MetricSeverityPresentation(
          label: 'Критично',
          foreground: Color(0xFFEF4444),
          background: Color(0xFFFFE5E6),
        );
      case MetricSeverity.noData:
        return const _MetricSeverityPresentation(
          label: 'Нет данных',
          foreground: Color(0xFF7184A2),
          background: Color(0xFFF1F5FB),
        );
    }
  }
}

class _MetricSeverityBadge extends StatelessWidget {
  const _MetricSeverityBadge({required this.presentation});

  final _MetricSeverityPresentation presentation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: presentation.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        presentation.label,
        style: TextStyle(
          color: presentation.foreground,
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
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y = size.height - (values[index] * size.height);
      if (index == 0) {
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

class _MetricHistoryChart extends StatefulWidget {
  const _MetricHistoryChart({
    required this.history,
    required this.targetMin,
    required this.targetMax,
    required this.color,
    required this.hasRenderableHistory,
  });

  final List<MetricHistoryDay> history;
  final double targetMin;
  final double targetMax;
  final Color color;
  final bool hasRenderableHistory;

  @override
  State<_MetricHistoryChart> createState() => _MetricHistoryChartState();
}

class _MetricHistoryChartState extends State<_MetricHistoryChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final bounds = _HistoryChartBounds.fromHistory(
      history: widget.history,
      targetMin: widget.targetMin,
      targetMax: widget.targetMax,
    );

    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: bounds.yAxisLabels
                        .asMap()
                        .entries
                        .map(
                          (entry) => Expanded(
                            child: Align(
                              alignment: entry.key == 0
                                  ? Alignment.topLeft
                                  : entry.key == bounds.yAxisLabels.length - 1
                                  ? Alignment.bottomLeft
                                  : Alignment.centerLeft,
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                  color: Color(0xFF9AACCA),
                                  fontSize: 11,
                                  height: 1,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final chartPoints = _buildChartPoints(
                        history: widget.history,
                        bounds: bounds,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                      );
                      _ChartPoint? selectedPoint;
                      if (_selectedIndex != null) {
                        for (final point in chartPoints) {
                          if (point.index == _selectedIndex) {
                            selectedPoint = point;
                            break;
                          }
                        }
                      }

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          final tappedIndex = _hitTestPoint(
                            localPosition: details.localPosition,
                            points: chartPoints,
                          );
                          setState(() {
                            _selectedIndex = tappedIndex;
                          });
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CustomPaint(
                              painter: _MetricHistoryChartPainter(
                                history: widget.history,
                                bounds: bounds,
                                color: widget.color,
                                hasRenderableHistory:
                                    widget.hasRenderableHistory,
                                selectedIndex: _selectedIndex,
                              ),
                              child: const SizedBox.expand(),
                            ),
                            if (selectedPoint != null)
                              _HistoryValueBubble(
                                point: selectedPoint,
                                chartWidth: constraints.maxWidth,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const labelWidth = 32.0;
              return SizedBox(
                height: 18,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: List<Widget>.generate(widget.history.length, (index) {
                    final x = widget.history.length == 1
                        ? constraints.maxWidth / 2
                        : constraints.maxWidth * index / (widget.history.length - 1);
                    final left = (x - (labelWidth / 2))
                        .clamp(0.0, constraints.maxWidth - labelWidth)
                        .toDouble();
                    return Positioned(
                      left: left,
                      width: labelWidth,
                      child: Text(
                        _weekdayLabel(widget.history[index].date.weekday),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF9AACCA),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
          if (!widget.hasRenderableHistory) ...[
            const SizedBox(height: 10),
            const Text(
              'Добавьте хотя бы два значения, чтобы увидеть график.',
              style: TextStyle(
                color: Color(0xFF9AACCA),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_ChartPoint> _buildChartPoints({
    required List<MetricHistoryDay> history,
    required _HistoryChartBounds bounds,
    required double width,
    required double height,
  }) {
    if (!widget.hasRenderableHistory) {
      return const [];
    }

    final range = bounds.maxValue - bounds.minValue;
    final points = <_ChartPoint>[];
    for (var index = 0; index < history.length; index++) {
      final value = history[index].value;
      if (value == null) {
        continue;
      }

      final x = history.length == 1
          ? width / 2
          : width * index / (history.length - 1);
      final normalized = (value - bounds.minValue) / range;
      final y = height - (normalized * height);
      points.add(
        _ChartPoint(
          index: index,
          date: history[index].date,
          value: value,
          position: Offset(x, y),
        ),
      );
    }
    return points;
  }

  int? _hitTestPoint({
    required Offset localPosition,
    required List<_ChartPoint> points,
  }) {
    const hitRadius = 18.0;
    for (final point in points) {
      if ((localPosition - point.position).distance <= hitRadius) {
        return point.index;
      }
    }
    return null;
  }
}

class _ChartPoint {
  const _ChartPoint({
    required this.index,
    required this.date,
    required this.value,
    required this.position,
  });

  final int index;
  final DateTime date;
  final double value;
  final Offset position;
}

class _HistoryValueBubble extends StatelessWidget {
  const _HistoryValueBubble({required this.point, required this.chartWidth});

  final _ChartPoint point;
  final double chartWidth;

  @override
  Widget build(BuildContext context) {
    const bubbleWidth = 96.0;
    final left = (point.position.dx - (bubbleWidth / 2))
        .clamp(0.0, chartWidth - bubbleWidth)
        .toDouble();
    final top = math.max(point.position.dy - 54, 0).toDouble();

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: bubbleWidth,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD8F1DE)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFCAE6CF).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          '${_weekdayLabel(point.date.weekday)}: ${_formatMetricNumber(point.value)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF12203F),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HistoryChartBounds {
  const _HistoryChartBounds({
    required this.minValue,
    required this.maxValue,
    required this.yAxisLabels,
  });

  final double minValue;
  final double maxValue;
  final List<String> yAxisLabels;

  factory _HistoryChartBounds.fromHistory({
    required List<MetricHistoryDay> history,
    required double targetMin,
    required double targetMax,
  }) {
    final values = history
        .where((item) => item.value != null)
        .map((item) => item.value!)
        .toList();

    var minValue = values.isEmpty
        ? targetMin
        : math.min(values.reduce(math.min), targetMin);
    var maxValue = values.isEmpty
        ? targetMax
        : math.max(values.reduce(math.max), targetMax);

    if ((maxValue - minValue).abs() < 0.001) {
      minValue -= 1;
      maxValue += 1;
    }

    final padding = math.max((maxValue - minValue) * 0.15, 1.0);
    minValue = math.max(0, minValue - padding);
    maxValue += padding;

    const steps = 4;
    final stepSize = (maxValue - minValue) / steps;
    final labels = List<String>.generate(
      steps + 1,
      (index) => _formatMetricNumber(maxValue - (stepSize * index)),
    );

    return _HistoryChartBounds(
      minValue: minValue,
      maxValue: maxValue,
      yAxisLabels: labels,
    );
  }
}

class _MetricHistoryChartPainter extends CustomPainter {
  const _MetricHistoryChartPainter({
    required this.history,
    required this.bounds,
    required this.color,
    required this.hasRenderableHistory,
    required this.selectedIndex,
  });

  final List<MetricHistoryDay> history;
  final _HistoryChartBounds bounds;
  final Color color;
  final bool hasRenderableHistory;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EEF7)
      ..strokeWidth = 1;

    const gridDivisions = 4;
    for (var index = 0; index <= gridDivisions; index++) {
      final y = size.height * index / gridDivisions;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var index = 0; index < history.length; index++) {
      final x = history.length == 1
          ? size.width / 2
          : size.width * index / (history.length - 1);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    if (!hasRenderableHistory) {
      return;
    }

    final points = <Offset>[];
    final pointIndices = <int>[];
    final range = bounds.maxValue - bounds.minValue;

    for (var index = 0; index < history.length; index++) {
      final value = history[index].value;
      if (value == null) {
        continue;
      }

      final x = history.length == 1
          ? size.width / 2
          : size.width * index / (history.length - 1);
      final normalized = (value - bounds.minValue) / range;
      final y = size.height - (normalized * size.height);
      points.add(Offset(x, y));
      pointIndices.add(index);
    }

    if (points.length < 2) {
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      path.lineTo(points[index].dx, points[index].dy);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()..color = color;
    for (final point in points) {
      canvas.drawCircle(point, 5.5, pointPaint);
    }

    if (selectedIndex != null) {
      final selectedPointPosition = pointIndices.indexOf(selectedIndex!);
      if (selectedPointPosition != -1) {
        final selectedPoint = points[selectedPointPosition];
        final selectionPaint = Paint()
          ..color = const Color(0xFFD6DEE9)
          ..strokeWidth = 1.5;
        canvas.drawLine(
          Offset(selectedPoint.dx, 0),
          Offset(selectedPoint.dx, size.height),
          selectionPaint,
        );

        final selectedPointPaint = Paint()..color = color;
        final selectedOutlinePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(selectedPoint, 7.5, selectedPointPaint);
        canvas.drawCircle(selectedPoint, 7.5, selectedOutlinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MetricHistoryChartPainter oldDelegate) {
    return oldDelegate.history != history ||
        oldDelegate.bounds.minValue != bounds.minValue ||
        oldDelegate.bounds.maxValue != bounds.maxValue ||
        oldDelegate.color != color ||
        oldDelegate.hasRenderableHistory != hasRenderableHistory ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class _EmptyMetricsState extends StatelessWidget {
  const _EmptyMetricsState({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD5EFD9).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.monitor_heart_outlined,
            color: Color(0xFF8B38F6),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Метрик пока нет',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0C1C46),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Создайте свою метрику, чтобы отслеживать нужные показатели здоровья.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6F86A9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B38F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Создать метрику',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Пн';
    case DateTime.tuesday:
      return 'Вт';
    case DateTime.wednesday:
      return 'Ср';
    case DateTime.thursday:
      return 'Чт';
    case DateTime.friday:
      return 'Пт';
    case DateTime.saturday:
      return 'Сб';
    case DateTime.sunday:
      return 'Вс';
  }
  return '';
}

String _formatMetricNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  final singleDecimal = value.toStringAsFixed(1);
  if (double.parse(singleDecimal) == value) {
    return singleDecimal;
  }

  return value.toStringAsFixed(2);
}
