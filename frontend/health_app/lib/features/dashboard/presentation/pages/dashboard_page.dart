import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../../core/layout/app_layout_constants.dart';
import '../../../profile/data/datasources/profile_local_data_source.dart';
import '../../data/datasources/blood_pressure_local_data_source.dart';
import '../../data/repositories/local_blood_pressure_repository.dart';
import '../../domain/entities/blood_pressure_reading.dart';
import '../../domain/repositories/blood_pressure_repository.dart';
import '../../domain/usecases/delete_blood_pressure_reading.dart';
import '../../domain/usecases/get_blood_pressure_readings.dart';
import '../../domain/usecases/save_blood_pressure_reading.dart';
import '../controllers/dashboard_controller.dart';
import '../utils/blood_pressure_category_style.dart';
import '../utils/dashboard_date_formatter.dart';
import '../widgets/blood_pressure_reading_sheet.dart';
import '../widgets/dashboard_history_card.dart';
import '../widgets/dashboard_reading_card.dart';
import 'all_readings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    this.repository,
    this.profileLocalDataSource,
  });

  final BloodPressureRepository? repository;
  final ProfileLocalDataSource? profileLocalDataSource;

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  late final DashboardController _controller;
  late final ProfileLocalDataSource _profileLocalDataSource =
      widget.profileLocalDataSource ?? ProfileLocalDataSource();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  DashboardHistoryRange _selectedHistoryRange = DashboardHistoryRange.sevenDays;
  String _displayName = 'Пользователь';

  @override
  void initState() {
    super.initState();
    final repository =
        widget.repository ??
        LocalBloodPressureRepository(BloodPressureLocalDataSource());
    _controller = DashboardController(
      getReadings: GetBloodPressureReadingsUseCase(repository),
      saveReading: SaveBloodPressureReadingUseCase(repository),
      deleteReading: DeleteBloodPressureReadingUseCase(repository),
    );
    _controller.initialize();
    unawaited(_loadProfileDisplayName());
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.contains(ConnectivityResult.none)) {
        return;
      }

      unawaited(_controller.refresh());
    });
  }

  Future<void> _loadProfileDisplayName() async {
    final profile = await _profileLocalDataSource.getProfile();
    if (!mounted) {
      return;
    }

    final displayName = _resolveDisplayName(profile?.fullName);
    if (displayName == _displayName) {
      return;
    }

    setState(() {
      _displayName = displayName;
    });
  }

  String _resolveDisplayName(String? fullName) {
    final trimmed = (fullName ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Пользователь';
    }

    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Пользователь' : parts.first;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> openCreateReadingSheet() {
    return showBloodPressureReadingSheet(
      context: context,
      onSubmit: (value) {
        return _controller.saveReading(
          systolic: value.systolic,
          diastolic: value.diastolic,
          pulse: value.pulse,
        );
      },
    );
  }

  Future<void> _openEditReadingSheet(BloodPressureReading reading) {
    return showBloodPressureReadingSheet(
      context: context,
      initialReading: reading,
      onSubmit: (value) {
        return _controller.saveReading(
          existingReading: reading,
          systolic: value.systolic,
          diastolic: value.diastolic,
          pulse: value.pulse,
        );
      },
      onDelete: () => _controller.deleteReading(reading),
    );
  }

  Future<void> _openAllReadingsPage() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AllReadingsPage(controller: _controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final latestReading = _controller.latestReading;
        final historyReadings = _controller.readingsForRange(
          _selectedHistoryRange,
        );
        final recentReadings = _controller.recentReadings;
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
                          latestReading: latestReading,
                          displayName: _displayName,
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
                                  value: _controller.averageSystolic,
                                  unit: 'mmHg',
                                  label: 'Ср. верхнее',
                                  compact: isCompact,
                                ),
                              ),
                              SizedBox(width: isCompact ? 10 : 16),
                              Expanded(
                                child: _DashboardStatCard(
                                  icon: Icons.arrow_downward_rounded,
                                  iconBackground: const Color(0xFFE0ECFF),
                                  iconColor: const Color(0xFF2563EB),
                                  value: _controller.averageDiastolic,
                                  unit: 'mmHg',
                                  label: 'Ср. нижнее',
                                  compact: isCompact,
                                ),
                              ),
                              SizedBox(width: isCompact ? 10 : 16),
                              Expanded(
                                child: _DashboardStatCard(
                                  icon: Icons.favorite_rounded,
                                  iconBackground: const Color(0xFFEAE4FF),
                                  iconColor: const Color(0xFF7C3AED),
                                  value: _controller.averagePulse,
                                  unit: 'уд/мин',
                                  label: 'Ср. пульс',
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
                          child: DashboardHistoryCard(
                            selectedRange: _selectedHistoryRange,
                            onRangeSelected: (range) {
                              setState(() {
                                _selectedHistoryRange = range;
                              });
                            },
                            readings: historyReadings,
                            compact: isCompact,
                          ),
                        ),
                        /*   Padding(  // Commented for an only frontend practice, will be added with backend
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            22,
                            horizontalPadding,
                            0,
                          ),
                          child: _DashboardFitnessSyncCard(compact: isCompact),
                        ),
                        */
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
                              onPressed: openCreateReadingSheet,
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
                                'Добавить измерение',
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
                              Expanded(
                                child: Text(
                                  'Последние измерения',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0C1C46),
                                        fontSize: isCompact ? 22 : 24,
                                      ),
                                ),
                              ),
                              SizedBox(width: isCompact ? 8 : 12),
                              TextButton(
                                onPressed: _openAllReadingsPage,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: const Color(0xFF18A84D),
                                  textStyle: TextStyle(
                                    fontSize: isCompact ? 14 : 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Все записи',
                                      style: TextStyle(
                                        fontSize: isCompact ? 14 : 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: isCompact ? 20 : 22,
                                    ),
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
                            kPageBottomOverlayPadding,
                          ),
                          child: recentReadings.isEmpty
                              ? const _EmptyReadingsState()
                              : Column(
                                  children: recentReadings
                                      .map(
                                        (reading) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 14,
                                          ),
                                          child: DashboardReadingCard(
                                            reading: reading,
                                            compact: isCompact,
                                            onTap: () =>
                                                _openEditReadingSheet(reading),
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
              if (_controller.isLoading && _controller.allReadings.isEmpty)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHeroSection extends StatelessWidget {
  const _DashboardHeroSection({
    required this.latestReading,
    required this.displayName,
    required this.isCompact,
    required this.horizontalPadding,
  });

  final BloodPressureReading? latestReading;
  final String displayName;
  final bool isCompact;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latestStyle = resolveBloodPressureCategoryStyle(
      latestReading?.category ?? BloodPressureCategory.normal,
    );

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
                        getTimeBasedGreeting(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                          fontSize: isCompact ? 20 : 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayName,
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
                          'Последнее измерение',
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
                            Icon(
                              Icons.show_chart_rounded,
                              size: 16,
                              color: latestStyle.accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              latestReading == null
                                  ? 'Нет данных'
                                  : latestStyle.label,
                              style: TextStyle(
                                color: latestStyle.accent,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _DashboardReadingValue(
                            value: latestReading?.systolic.toString() ?? '--',
                            unit: 'mmHg',
                            label: 'Верхнее',
                            compact: true,
                          ),
                        ),
                        const Padding(
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
                            value: latestReading?.diastolic.toString() ?? '--',
                            unit: 'mmHg',
                            label: 'Нижнее',
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _DashboardPulseValue(
                      pulse: latestReading?.pulse,
                      compact: true,
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _DashboardReadingValue(
                            value: latestReading?.systolic.toString() ?? '--',
                            unit: 'mmHg',
                            label: 'Верхнее',
                          ),
                        ),
                        const Padding(
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
                            value: latestReading?.diastolic.toString() ?? '--',
                            unit: 'mmHg',
                            label: 'Нижнее',
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: _DashboardPulseValue(
                              pulse: latestReading?.pulse,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 18),
                  Text(
                    latestReading == null
                        ? 'Добавьте первое измерение, чтобы заполнить главную страницу'
                        : 'Сегодня, ${formatMonthDayTime(latestReading!.recordedAt)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: isCompact ? 14 : 15,
                      fontWeight: FontWeight.w600,
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

  String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Доброе утро';
    } else if (hour >= 12 && hour < 18) {
      return 'Добрый день';
    } else if (hour >= 18 && hour < 23) {
      return 'Добрый вечер';
    } else {
      return 'Доброй ночи';
    }
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
    final readingFontSize = compact ? 58.0 : 68.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: compact ? 62 : 74,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: readingFontSize,
                        fontWeight: FontWeight.w800,
                        height: 0.92,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: compact ? 10 : 14, left: 6),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: compact ? 13 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DashboardPulseValue extends StatelessWidget {
  const _DashboardPulseValue({required this.pulse, this.compact = false});

  final int? pulse;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              color: Colors.white.withValues(alpha: 0.86),
              size: compact ? 22 : 26,
            ),
            const SizedBox(width: 4),
            Text(
              pulse?.toString() ?? '--',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 28 : 34,
                fontWeight: FontWeight.w800,
                height: 0.92,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'уд/мин',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.86),
            fontSize: compact ? 14 : 16,
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
    required this.compact,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final int value;
  final String unit;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 18,
        compact ? 14 : 18,
        compact ? 12 : 18,
        compact ? 16 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCAEED0).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 42 : 46,
            height: compact ? 42 : 46,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: compact ? 24 : 26),
          ),
          SizedBox(height: compact ? 16 : 18),
          Text(
            '$value',
            style: TextStyle(
              color: const Color(0xFF102154),
              fontSize: compact ? 24 : 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
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

// ignore: unused_element
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
                            'Синхронизация с трекером',
                            style: TextStyle(
                              color: Color(0xFF20449D),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Подключите Apple Health / Google Fit / Garmin',
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
                      'Подключить',
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
                        'Синхронизация с трекером',
                        style: TextStyle(
                          color: Color(0xFF20449D),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Подключите Apple Health / Google Fit / Garmin',
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
                    'Подключить',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyReadingsState extends StatelessWidget {
  const _EmptyReadingsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
      child: const Text(
        'Здесь появятся сохраненные измерения.',
        style: TextStyle(
          color: Color(0xFF90A4C4),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
