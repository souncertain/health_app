import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/blood_pressure_reading.dart';
import '../controllers/dashboard_controller.dart';
import '../utils/dashboard_date_formatter.dart';

class DashboardHistoryCard extends StatefulWidget {
  const DashboardHistoryCard({
    super.key,
    required this.selectedRange,
    required this.onRangeSelected,
    required this.readings,
    this.compact = false,
  });

  final DashboardHistoryRange selectedRange;
  final ValueChanged<DashboardHistoryRange> onRangeSelected;
  final List<BloodPressureReading> readings;
  final bool compact;

  @override
  State<DashboardHistoryCard> createState() => _DashboardHistoryCardState();
}

class _DashboardHistoryCardState extends State<DashboardHistoryCard> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant DashboardHistoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readings.length != oldWidget.readings.length &&
        _selectedIndex != null &&
        _selectedIndex! >= widget.readings.length) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        widget.compact ? 16 : 20,
        widget.compact ? 18 : 22,
        widget.compact ? 16 : 20,
        widget.compact ? 18 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBFE8C7).withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'История давления',
                style: TextStyle(
                  color: const Color(0xFF0B1E4B),
                  fontSize: widget.compact ? 20 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _DashboardRangeChip(
                label: '7d',
                selected:
                    widget.selectedRange == DashboardHistoryRange.sevenDays,
                onTap: () {
                  setState(() {
                    _selectedIndex = null;
                  });
                  widget.onRangeSelected(DashboardHistoryRange.sevenDays);
                },
              ),
              const SizedBox(width: 10),
              _DashboardRangeChip(
                label: '30d',
                selected:
                    widget.selectedRange == DashboardHistoryRange.thirtyDays,
                onTap: () {
                  setState(() {
                    _selectedIndex = null;
                  });
                  widget.onRangeSelected(DashboardHistoryRange.thirtyDays);
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              _DashboardLegendItem(label: 'Верхнее', color: Color(0xFFE53935)),
              SizedBox(width: 18),
              _DashboardLegendItem(label: 'Нижнее', color: Color(0xFF3165E6)),
            ],
          ),
          SizedBox(height: widget.compact ? 10 : 12),
          if (widget.readings.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Измерений пока нет',
                  style: TextStyle(
                    color: Color(0xFF90A4C4),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: widget.compact ? 210 : 228,
              child: _DashboardBpChart(
                readings: widget.readings,
                compact: widget.compact,
                selectedIndex: _selectedIndex,
                onPointSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardRangeChip extends StatelessWidget {
  const _DashboardRangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1DB954) : const Color(0xFFF0FBF1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF1BA34B),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DashboardLegendItem extends StatelessWidget {
  const _DashboardLegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF627AA3),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DashboardBpChart extends StatelessWidget {
  const _DashboardBpChart({
    required this.readings,
    required this.selectedIndex,
    required this.onPointSelected,
    required this.compact,
  });

  final List<BloodPressureReading> readings;
  final int? selectedIndex;
  final ValueChanged<int> onPointSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const yLabels = [160, 135, 110, 85, 60];

    return Row(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 8, right: compact ? 8 : 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: yLabels
                .map(
                  (label) => Text(
                    '$label',
                    style: const TextStyle(
                      color: Color(0xFF9AACC8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final index = _nearestIndex(
                          localDx: details.localPosition.dx,
                          width: constraints.maxWidth,
                          count: readings.length,
                        );
                        onPointSelected(index);
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _DashboardBpChartPainter(
                                readings: readings,
                                selectedIndex: selectedIndex,
                              ),
                            ),
                          ),
                          if (selectedIndex != null)
                            _ChartTooltip(
                              reading: readings[selectedIndex!],
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              selectedIndex: selectedIndex!,
                              count: readings.length,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: compact ? 8 : 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(readings.length, (index) {
                  final labelStep = readings.length <= 7
                      ? 1
                      : (readings.length / 6).ceil();
                  final showLabel =
                      index == readings.length - 1 || index % labelStep == 0;

                  return Expanded(
                    child: Text(
                      showLabel
                          ? formatMonthDay(readings[index].recordedAt)
                          : '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF90A4C4),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _nearestIndex({
    required double localDx,
    required double width,
    required int count,
  }) {
    if (count <= 1) {
      return 0;
    }

    final step = width / (count - 1);
    final index = (localDx / step).round();
    return index.clamp(0, count - 1);
  }
}

class _ChartTooltip extends StatelessWidget {
  const _ChartTooltip({
    required this.reading,
    required this.width,
    required this.height,
    required this.selectedIndex,
    required this.count,
  });

  final BloodPressureReading reading;
  final double width;
  final double height;
  final int selectedIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    final x = _pointDx(selectedIndex, width, count);
    final y = _mapY(reading.systolic.toDouble(), height);
    const bubbleWidth = 104.0;
    const bubbleHeight = 100.0;
    final left = (x - (bubbleWidth / 2)).clamp(0.0, width - bubbleWidth);
    final top = (y - bubbleHeight - 10).clamp(8.0, height - bubbleHeight);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: bubbleWidth,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCAEED0).withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatMonthDay(reading.recordedAt),
                style: const TextStyle(
                  color: Color(0xFF1F7B44),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Верх: ${reading.systolic}',
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Низ: ${reading.diastolic}',
                style: const TextStyle(
                  color: Color(0xFF3165E6),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBpChartPainter extends CustomPainter {
  _DashboardBpChartPainter({
    required this.readings,
    required this.selectedIndex,
  });

  final List<BloodPressureReading> readings;
  final int? selectedIndex;

  static const double minY = 60;
  static const double maxY = 160;
  static const double targetY = 120;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EFFB)
      ..strokeWidth = 1;
    final dottedPaint = Paint()
      ..color = const Color(0xFF1DB954)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final systolicLinePaint = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final diastolicLinePaint = Paint()
      ..color = const Color(0xFF3165E6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final selectionPaint = Paint()
      ..color = const Color(0xFFCFD7E3)
      ..strokeWidth = 1.2;

    final chartHeight = size.height;
    final chartWidth = size.width;
    final horizontalLines = 4;
    final verticalLines = math.max(readings.length - 1, 1);

    for (var index = 0; index <= horizontalLines; index++) {
      final y = chartHeight * index / horizontalLines;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    for (var index = 0; index <= verticalLines; index++) {
      final x = chartWidth * index / verticalLines;
      canvas.drawLine(Offset(x, 0), Offset(x, chartHeight), gridPaint);
    }

    final targetOffset = Offset(0, _mapY(targetY, chartHeight));
    _drawDashedLine(
      canvas,
      dottedPaint,
      targetOffset,
      Offset(chartWidth, targetOffset.dy),
    );

    if (readings.isEmpty) {
      return;
    }

    final systolicPath = Path();
    final diastolicPath = Path();

    for (var index = 0; index < readings.length; index++) {
      final x = _pointDx(index, chartWidth, readings.length);
      final systolicY = _mapY(readings[index].systolic.toDouble(), chartHeight);
      final diastolicY = _mapY(
        readings[index].diastolic.toDouble(),
        chartHeight,
      );

      if (index == 0) {
        systolicPath.moveTo(x, systolicY);
        diastolicPath.moveTo(x, diastolicY);
      } else {
        systolicPath.lineTo(x, systolicY);
        diastolicPath.lineTo(x, diastolicY);
      }
    }

    canvas.drawPath(systolicPath, systolicLinePaint);
    canvas.drawPath(diastolicPath, diastolicLinePaint);

    if (selectedIndex != null) {
      final selectedX = _pointDx(selectedIndex!, chartWidth, readings.length);
      canvas.drawLine(
        Offset(selectedX, 0),
        Offset(selectedX, chartHeight),
        selectionPaint,
      );
    }

    for (var index = 0; index < readings.length; index++) {
      final x = _pointDx(index, chartWidth, readings.length);
      final systolicY = _mapY(readings[index].systolic.toDouble(), chartHeight);
      final diastolicY = _mapY(
        readings[index].diastolic.toDouble(),
        chartHeight,
      );
      final isSelected = index == selectedIndex;

      _drawPoint(
        canvas: canvas,
        offset: Offset(x, systolicY),
        color: const Color(0xFFE53935),
        isSelected: isSelected,
      );
      _drawPoint(
        canvas: canvas,
        offset: Offset(x, diastolicY),
        color: const Color(0xFF3165E6),
        isSelected: isSelected,
      );
    }
  }

  void _drawPoint({
    required Canvas canvas,
    required Offset offset,
    required Color color,
    required bool isSelected,
  }) {
    final fillPaint = Paint()..color = color;
    final radius = isSelected ? 6.5 : 5.0;

    canvas.drawCircle(offset, radius, fillPaint);
    canvas.drawCircle(
      offset,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  double _mapY(double value, double height) {
    final normalized = (value - minY) / (maxY - minY);
    return height - (normalized * height);
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final dashCount = (distance / (dashWidth + dashSpace)).floor();

    for (var index = 0; index < dashCount; index++) {
      final offset = index * (dashWidth + dashSpace);
      final x1 = start.dx + (dx / distance) * offset;
      final y1 = start.dy + (dy / distance) * offset;
      final x2 = start.dx + (dx / distance) * (offset + dashWidth);
      final y2 = start.dy + (dy / distance) * (offset + dashWidth);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardBpChartPainter oldDelegate) {
    return oldDelegate.readings != readings ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

double _pointDx(int index, double width, int count) {
  if (count <= 1) {
    return width / 2;
  }
  return width * index / (count - 1);
}

double _mapY(double value, double height) {
  const minY = 60.0;
  const maxY = 160.0;
  final normalized = (value - minY) / (maxY - minY);
  return height - (normalized * height);
}
