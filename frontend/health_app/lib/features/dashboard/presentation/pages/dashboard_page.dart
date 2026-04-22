import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/blood_pressure_point.dart';
import '../../domain/entities/recent_reading.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedHistoryRange = 0;

  final List<BloodPressurePoint> _history7Days = const [
    BloodPressurePoint(label: 'Apr 9', systolic: 126, diastolic: 77),
    BloodPressurePoint(label: 'Apr 10', systolic: 135, diastolic: 82),
    BloodPressurePoint(label: 'Apr 11', systolic: 121, diastolic: 79),
    BloodPressurePoint(label: 'Apr 12', systolic: 141, diastolic: 85),
    BloodPressurePoint(label: 'Apr 13', systolic: 118, diastolic: 76),
    BloodPressurePoint(label: 'Apr 14', systolic: 124, diastolic: 80),
    BloodPressurePoint(label: 'Apr 15', systolic: 132, diastolic: 84),
    BloodPressurePoint(label: 'Apr 16', systolic: 119, diastolic: 77),
  ];

  final List<BloodPressurePoint> _history30Days = const [
    BloodPressurePoint(label: 'Mar 18', systolic: 124, diastolic: 79),
    BloodPressurePoint(label: 'Mar 22', systolic: 128, diastolic: 80),
    BloodPressurePoint(label: 'Mar 26', systolic: 122, diastolic: 78),
    BloodPressurePoint(label: 'Mar 30', systolic: 137, diastolic: 84),
    BloodPressurePoint(label: 'Apr 3', systolic: 120, diastolic: 77),
    BloodPressurePoint(label: 'Apr 7', systolic: 129, diastolic: 82),
    BloodPressurePoint(label: 'Apr 12', systolic: 141, diastolic: 85),
    BloodPressurePoint(label: 'Apr 16', systolic: 119, diastolic: 77),
  ];

  final List<RecentReading> _recentReadings = const [
    RecentReading(
      pressure: '119/77',
      status: ReadingStatus.normal,
      date: 'Apr 16',
      pulse: '71 bpm',
    ),
    RecentReading(
      pressure: '132/85',
      status: ReadingStatus.elevated,
      date: 'Apr 15',
      pulse: '76 bpm',
    ),
    RecentReading(
      pressure: '125/80',
      status: ReadingStatus.elevated,
      date: 'Apr 14',
      pulse: '74 bpm',
    ),
    RecentReading(
      pressure: '118/76',
      status: ReadingStatus.normal,
      date: 'Apr 13',
      pulse: '68 bpm',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = _selectedHistoryRange == 0 ? _history7Days : _history30Days;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 390;
    final horizontalPadding = isCompact ? 16.0 : 20.0;

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFEFFBF2),
                    const Color(0xFFF8FFFA),
                    const Color(0xFFE8F8EC).withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DashboardHeroSection(
                      isCompact: isCompact,
                      horizontalPadding: horizontalPadding,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        24,
                        horizontalPadding,
                        0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DashboardStatCard(
                              icon: Icons.arrow_upward_rounded,
                              iconBackground: const Color(0xFFFFE4EA),
                              iconColor: const Color(0xFFEF4444),
                              value: '127',
                              unit: 'mmHg',
                              label: 'Avg Systolic',
                              compact: isCompact,
                            ),
                          ),
                          SizedBox(width: isCompact ? 10 : 16),
                          Expanded(
                            child: _DashboardStatCard(
                              icon: Icons.arrow_downward_rounded,
                              iconBackground: const Color(0xFFE0ECFF),
                              iconColor: const Color(0xFF2563EB),
                              value: '82',
                              unit: 'mmHg',
                              label: 'Avg Diastolic',
                              compact: isCompact,
                            ),
                          ),
                          SizedBox(width: isCompact ? 10 : 16),
                          Expanded(
                            child: _DashboardStatCard(
                              icon: Icons.favorite_rounded,
                              iconBackground: const Color(0xFFEAE4FF),
                              iconColor: const Color(0xFF7C3AED),
                              value: '74',
                              unit: 'bpm',
                              label: 'Avg Pulse',
                              compact: isCompact,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        24,
                        horizontalPadding,
                        0,
                      ),
                      child: _DashboardHistoryCard(
                        selectedRange: _selectedHistoryRange,
                        onRangeSelected: (index) {
                          setState(() {
                            _selectedHistoryRange = index;
                          });
                        },
                        points: history,
                        compact: isCompact,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        22,
                        horizontalPadding,
                        0,
                      ),
                      child: _DashboardFitnessSyncCard(compact: isCompact),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        22,
                        horizontalPadding,
                        0,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1DB954),
                            foregroundColor: Colors.white,
                            elevation: 10,
                            shadowColor: const Color(
                              0xFF1DB954,
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
                            'Add Measurement',
                            style: TextStyle(
                              fontSize: isCompact ? 16 : 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        26,
                        horizontalPadding,
                        14,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Recent Readings',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0C1C46),
                              fontSize: isCompact ? 22 : 24,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF18A84D),
                              textStyle: TextStyle(
                                fontSize: isCompact ? 16 : 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('View All'),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        148,
                      ),
                      child: Column(
                        children: _recentReadings
                            .map(
                              (reading) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _DashboardRecentReadingCard(
                                  reading: reading,
                                  compact: isCompact,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardHeroSection extends StatelessWidget {
  const _DashboardHeroSection({
    required this.isCompact,
    required this.horizontalPadding,
  });

  final bool isCompact;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF1DB954)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          26,
          horizontalPadding,
          24,
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
                        'Good Morning',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                          fontSize: isCompact ? 20 : 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Alex Johnson',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: isCompact ? 28 : 30,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: isCompact ? 56 : 58,
                  height: isCompact ? 56 : 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 2,
                    ),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2F3A41), Color(0xFF0F171A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: isCompact ? 30 : 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                isCompact ? 16 : 20,
                22,
                isCompact ? 16 : 20,
                22,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        color: Colors.white,
                        size: isCompact ? 26 : 28,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Latest Reading',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 16,
                          vertical: isCompact ? 8 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9FBEF),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.show_chart_rounded,
                              size: 16,
                              color: Color(0xFF18A84D),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Normal',
                              style: TextStyle(
                                color: const Color(0xFF18954B),
                                fontSize: isCompact ? 14 : 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 22 : 28),
                  if (isCompact) ...[
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _DashboardReadingValue(
                            value: '119',
                            unit: 'mmHg',
                            label: 'Systolic',
                            compact: true,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            '/',
                            style: TextStyle(
                              color: Color(0xFFA0EEB4),
                              fontWeight: FontWeight.w400,
                              fontSize: 46,
                              height: 0.8,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _DashboardReadingValue(
                            value: '77',
                            unit: 'mmHg',
                            label: 'Diastolic',
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _DashboardPulseValue(compact: true),
                  ] else
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _DashboardReadingValue(
                            value: '119',
                            unit: 'mmHg',
                            label: 'Systolic',
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            '/',
                            style: TextStyle(
                              color: Color(0xFFA0EEB4),
                              fontWeight: FontWeight.w400,
                              fontSize: 66,
                              height: 0.8,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _DashboardReadingValue(
                            value: '77',
                            unit: 'mmHg',
                            label: 'Diastolic',
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: _DashboardPulseValue(),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: isCompact ? 8 : 10),
                  Text(
                    'Today, Apr 16 - 9:30 AM',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                      fontSize: isCompact ? 15 : null,
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

class _DashboardReadingValue extends StatelessWidget {
  const _DashboardReadingValue({
    required this.value,
    required this.unit,
    required this.label,
    this.compact = false,
  });

  final String value;
  final String unit;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 46 : 62,
                    fontWeight: FontWeight.w800,
                    height: 0.9,
                  ),
                ),
              ),
            ),
            SizedBox(width: compact ? 4 : 8),
            Padding(
              padding: EdgeInsets.only(bottom: compact ? 6 : 8),
              child: Text(
                unit,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: compact ? 14 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DashboardPulseValue extends StatelessWidget {
  const _DashboardPulseValue({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: compact ? 20 : 22,
            ),
            const SizedBox(width: 4),
            Text(
              '71',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 32 : 38,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Text(
          'bpm',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String value;
  final String unit;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 18,
        compact ? 16 : 18,
        compact ? 14 : 18,
        compact ? 18 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBDE7C5).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 38 : 42,
            height: compact ? 38 : 42,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: compact ? 20 : 22),
          ),
          SizedBox(height: compact ? 14 : 18),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF0B1E4B),
              fontSize: compact ? 24 : 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: TextStyle(
              color: const Color(0xFF597197),
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF8EA0BE),
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHistoryCard extends StatelessWidget {
  const _DashboardHistoryCard({
    required this.selectedRange,
    required this.onRangeSelected,
    required this.points,
    this.compact = false,
  });

  final int selectedRange;
  final ValueChanged<int> onRangeSelected;
  final List<BloodPressurePoint> points;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 20,
        compact ? 18 : 22,
        compact ? 16 : 20,
        compact ? 18 : 22,
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
                'BP History',
                style: TextStyle(
                  color: const Color(0xFF0B1E4B),
                  fontSize: compact ? 20 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _DashboardRangeChip(
                label: '7d',
                selected: selectedRange == 0,
                onTap: () => onRangeSelected(0),
              ),
              const SizedBox(width: 10),
              _DashboardRangeChip(
                label: '30d',
                selected: selectedRange == 1,
                onTap: () => onRangeSelected(1),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              _DashboardLegendItem(label: 'Systolic', color: Color(0xFFE53935)),
              SizedBox(width: 18),
              _DashboardLegendItem(
                label: 'Diastolic',
                color: Color(0xFF3165E6),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 12),
          SizedBox(
            height: compact ? 200 : 220,
            child: _DashboardBpChart(points: points, compact: compact),
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
  const _DashboardBpChart({required this.points, this.compact = false});

  final List<BloodPressurePoint> points;
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
                child: CustomPaint(
                  painter: _DashboardBpChartPainter(points: points),
                  size: Size.infinite,
                ),
              ),
              SizedBox(height: compact ? 8 : 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: points
                    .map(
                      (point) => Expanded(
                        child: Text(
                          point.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF90A4C4),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardBpChartPainter extends CustomPainter {
  _DashboardBpChartPainter({required this.points});

  final List<BloodPressurePoint> points;
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
    final linePaint = Paint()
      ..color = const Color(0xFF3165E6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pointFillPaint = Paint()..color = const Color(0xFF3165E6);

    final chartHeight = size.height;
    final chartWidth = size.width;
    final horizontalLines = 4;
    final verticalLines = math.max(points.length - 1, 1);

    for (var i = 0; i <= horizontalLines; i++) {
      final y = chartHeight * i / horizontalLines;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    for (var i = 0; i <= verticalLines; i++) {
      final x = chartWidth * i / verticalLines;
      canvas.drawLine(Offset(x, 0), Offset(x, chartHeight), gridPaint);
    }

    final targetOffset = Offset(0, _mapY(targetY, chartHeight));
    _drawDashedLine(
      canvas,
      dottedPaint,
      targetOffset,
      Offset(chartWidth, targetOffset.dy),
    );

    if (points.isEmpty) {
      return;
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = chartWidth * i / math.max(points.length - 1, 1);
      final y = _mapY(points[i].systolic.toDouble(), chartHeight);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    for (var i = 0; i < points.length; i++) {
      final x = chartWidth * i / math.max(points.length - 1, 1);
      final y = _mapY(points[i].systolic.toDouble(), chartHeight);
      canvas.drawCircle(Offset(x, y), 5.5, pointFillPaint);
      canvas.drawCircle(
        Offset(x, y),
        5.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
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

    for (var i = 0; i < dashCount; i++) {
      final offset = i * (dashWidth + dashSpace);
      final x1 = start.dx + (dx / distance) * offset;
      final y1 = start.dy + (dy / distance) * offset;
      final x2 = start.dx + (dx / distance) * (offset + dashWidth);
      final y2 = start.dy + (dy / distance) * (offset + dashWidth);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardBpChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _DashboardFitnessSyncCard extends StatelessWidget {
  const _DashboardFitnessSyncCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F0FF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFBDD0FF)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3165E6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.wifi_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fitness Tracker Sync',
                            style: TextStyle(
                              color: Color(0xFF20449D),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Connect Apple Health / Google Fit / Garmin',
                            style: TextStyle(
                              color: Color(0xFF3165E6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3165E6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      'Connect',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3165E6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.wifi_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fitness Tracker Sync',
                        style: TextStyle(
                          color: Color(0xFF20449D),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Connect Apple Health / Google Fit / Garmin',
                        style: TextStyle(
                          color: Color(0xFF3165E6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3165E6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'Connect',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DashboardRecentReadingCard extends StatelessWidget {
  const _DashboardRecentReadingCard({
    required this.reading,
    required this.compact,
  });

  final RecentReading reading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = reading.status == ReadingStatus.normal
        ? const Color(0xFFDDF8E5)
        : const Color(0xFFFFEFD9);
    final iconColor = reading.status == ReadingStatus.normal
        ? const Color(0xFF1DB954)
        : const Color(0xFFF97316);
    final statusColor = reading.status == ReadingStatus.normal
        ? const Color(0xFFE4FAEA)
        : const Color(0xFFFFE4CC);
    final statusText = reading.status == ReadingStatus.normal
        ? 'Normal'
        : 'High Stage 1';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 20,
        vertical: compact ? 16 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCAEED0).withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 42 : 46,
            height: compact ? 42 : 46,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              color: iconColor,
              size: compact ? 22 : 24,
            ),
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reading.pressure,
                      style: TextStyle(
                        color: const Color(0xFF0A1947),
                        fontSize: compact ? 20 : 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 10),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          statusText,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: iconColor,
                            fontSize: compact ? 13 : 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${reading.date} - ${reading.pulse}',
                  style: TextStyle(
                    color: const Color(0xFF90A4C4),
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.bolt_outlined, color: Color(0xFF93A7C7), size: 24),
        ],
      ),
    );
  }
}
