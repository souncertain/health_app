import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const HealthApp());
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diplom Health',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.05),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2FBF3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DB954),
          primary: const Color(0xFF1DB954),
          secondary: const Color(0xFF3165E6),
          surface: Colors.white,
        ),
        fontFamily: 'SF Pro Display',
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedNavIndex = 0;
  int _selectedHistoryRange = 0;
  bool _isFabExpanded = false;

  final List<_BloodPressurePoint> _history7Days = const [
    _BloodPressurePoint('Apr 9', 126, 126),
    _BloodPressurePoint('Apr 10', 135, 135),
    _BloodPressurePoint('Apr 11', 121, 121),
    _BloodPressurePoint('Apr 12', 141, 141),
    _BloodPressurePoint('Apr 13', 118, 118),
    _BloodPressurePoint('Apr 14', 124, 124),
    _BloodPressurePoint('Apr 15', 132, 132),
    _BloodPressurePoint('Apr 16', 119, 119),
  ];

  final List<_BloodPressurePoint> _history30Days = const [
    _BloodPressurePoint('Mar 18', 124, 124),
    _BloodPressurePoint('Mar 22', 128, 128),
    _BloodPressurePoint('Mar 26', 122, 122),
    _BloodPressurePoint('Mar 30', 137, 137),
    _BloodPressurePoint('Apr 3', 120, 120),
    _BloodPressurePoint('Apr 7', 129, 129),
    _BloodPressurePoint('Apr 12', 141, 141),
    _BloodPressurePoint('Apr 16', 119, 119),
  ];

  final List<_RecentReading> _recentReadings = const [
    _RecentReading(
      pressure: '119/77',
      status: 'Normal',
      date: 'Apr 16',
      pulse: '71 bpm',
      accent: Color(0xFFDDF8E5),
      iconColor: Color(0xFF1DB954),
      statusColor: Color(0xFFE4FAEA),
      statusTextColor: Color(0xFF1FA34A),
    ),
    _RecentReading(
      pressure: '132/85',
      status: 'High Stage 1',
      date: 'Apr 15',
      pulse: '76 bpm',
      accent: Color(0xFFFFEFD9),
      iconColor: Color(0xFFF97316),
      statusColor: Color(0xFFFFE4CC),
      statusTextColor: Color(0xFFF97316),
    ),
    _RecentReading(
      pressure: '125/80',
      status: 'High Stage 1',
      date: 'Apr 14',
      pulse: '74 bpm',
      accent: Color(0xFFFFEFD9),
      iconColor: Color(0xFFF97316),
      statusColor: Color(0xFFFFE4CC),
      statusTextColor: Color(0xFFF97316),
    ),
    _RecentReading(
      pressure: '118/76',
      status: 'Normal',
      date: 'Apr 13',
      pulse: '68 bpm',
      accent: Color(0xFFDDF8E5),
      iconColor: Color(0xFF1DB954),
      statusColor: Color(0xFFE4FAEA),
      statusTextColor: Color(0xFF1FA34A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = _selectedHistoryRange == 0 ? _history7Days : _history30Days;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 390;
    final horizontalPadding = isCompact ? 16.0 : 20.0;

    return Scaffold(
      body: SafeArea(
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
                      _buildHeroSection(theme, isCompact, horizontalPadding),
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
                              child: _StatCard(
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
                              child: _StatCard(
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
                              child: _StatCard(
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
                        child: _HistoryCard(
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
                        child: _FitnessSyncCard(
                          onConnect: () {},
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
                          112,
                        ),
                        child: Column(
                          children: _recentReadings
                              .map(
                                (reading) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _RecentReadingCard(
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
            Positioned(
              right: 20,
              bottom: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IgnorePointer(
                    ignoring: !_isFabExpanded,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _isFabExpanded ? 1 : 0,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 180),
                        offset: _isFabExpanded
                            ? Offset.zero
                            : const Offset(0, 0.08),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              _FabActionChip(
                                label: 'Add BP Reading',
                                color: Color(0xFF1DB954),
                              ),
                              SizedBox(height: 14),
                              _FabActionChip(
                                label: 'Add Medication',
                                color: Color(0xFF1595C9),
                              ),
                              SizedBox(height: 14),
                              _FabActionChip(
                                label: 'Log Metric',
                                color: Color(0xFF7C3AED),
                              ),
                              SizedBox(height: 14),
                              _FabActionChip(
                                label: 'Book Appointment',
                                color: Color(0xFFEB8A06),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _isFabExpanded = !_isFabExpanded;
                      });
                    },
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.white,
                    elevation: 14,
                    child: Icon(
                      _isFabExpanded ? Icons.close_rounded : Icons.add_rounded,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _DashboardBottomNavigation(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHeroSection(
    ThemeData theme,
    bool isCompact,
    double horizontalPadding,
  ) {
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
                          child: _ReadingValue(
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
                          child: _ReadingValue(
                            value: '77',
                            unit: 'mmHg',
                            label: 'Diastolic',
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _PulseValue(compact: true),
                  ] else
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _ReadingValue(
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
                          child: _ReadingValue(
                            value: '77',
                            unit: 'mmHg',
                            label: 'Diastolic',
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: _PulseValue(),
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

class _ReadingValue extends StatelessWidget {
  const _ReadingValue({
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

class _PulseValue extends StatelessWidget {
  const _PulseValue({this.compact = false});

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

class _StatCard extends StatelessWidget {
  const _StatCard({
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

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.selectedRange,
    required this.onRangeSelected,
    required this.points,
    this.compact = false,
  });

  final int selectedRange;
  final ValueChanged<int> onRangeSelected;
  final List<_BloodPressurePoint> points;
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
              _RangeChip(
                label: '7d',
                selected: selectedRange == 0,
                onTap: () => onRangeSelected(0),
              ),
              const SizedBox(width: 10),
              _RangeChip(
                label: '30d',
                selected: selectedRange == 1,
                onTap: () => onRangeSelected(1),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              _LegendItem(label: 'Systolic', color: Color(0xFFE53935)),
              SizedBox(width: 18),
              _LegendItem(label: 'Diastolic', color: Color(0xFF3165E6)),
            ],
          ),
          SizedBox(height: compact ? 10 : 12),
          SizedBox(
            height: compact ? 200 : 220,
            child: _BpChart(points: points, compact: compact),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
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

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

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

class _BpChart extends StatelessWidget {
  const _BpChart({required this.points, this.compact = false});

  final List<_BloodPressurePoint> points;
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
                  painter: _BpChartPainter(points: points),
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

class _BpChartPainter extends CustomPainter {
  _BpChartPainter({required this.points});

  final List<_BloodPressurePoint> points;
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
  bool shouldRepaint(covariant _BpChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _FitnessSyncCard extends StatelessWidget {
  const _FitnessSyncCard({required this.onConnect, this.compact = false});

  final VoidCallback onConnect;
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
                    onPressed: onConnect,
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
                  onPressed: onConnect,
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

class _RecentReadingCard extends StatelessWidget {
  const _RecentReadingCard({required this.reading, this.compact = false});

  final _RecentReading reading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
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
              color: reading.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              color: reading.iconColor,
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
                          color: reading.statusColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          reading.status,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: reading.statusTextColor,
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

class _FabActionChip extends StatelessWidget {
  const _FabActionChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBottomNavigation extends StatelessWidget {
  const _DashboardBottomNavigation({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label})>[
      (icon: Icons.favorite_rounded, label: 'Dashboard'),
      (icon: Icons.medication_liquid_rounded, label: 'Meds'),
      (icon: Icons.bar_chart_rounded, label: 'Metrics'),
      (icon: Icons.calendar_month_rounded, label: 'Visits'),
      (icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBFE6C4).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onTap(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFDDF8E5)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            color: isSelected
                                ? const Color(0xFF1AA34C)
                                : const Color(0xFF94A8C7),
                            size: 25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF1AA34C)
                                : const Color(0xFF94A8C7),
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BloodPressurePoint {
  const _BloodPressurePoint(this.label, this.systolic, this.diastolic);

  final String label;
  final int systolic;
  final int diastolic;
}

class _RecentReading {
  const _RecentReading({
    required this.pressure,
    required this.status,
    required this.date,
    required this.pulse,
    required this.accent,
    required this.iconColor,
    required this.statusColor,
    required this.statusTextColor,
  });

  final String pressure;
  final String status;
  final String date;
  final String pulse;
  final Color accent;
  final Color iconColor;
  final Color statusColor;
  final Color statusTextColor;
}
