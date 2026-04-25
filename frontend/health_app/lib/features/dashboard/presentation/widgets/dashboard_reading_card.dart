import 'package:flutter/material.dart';

import '../../domain/entities/blood_pressure_reading.dart';
import '../utils/blood_pressure_category_style.dart';
import '../utils/dashboard_date_formatter.dart';

class DashboardReadingCard extends StatelessWidget {
  const DashboardReadingCard({
    super.key,
    required this.reading,
    required this.onTap,
    this.compact = false,
    this.detailed = false,
  });

  final BloodPressureReading reading;
  final VoidCallback onTap;
  final bool compact;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final style = resolveBloodPressureCategoryStyle(reading.category);
    final subtitle = detailed
        ? '${formatMonthDayYear(reading.recordedAt)} - '
              '${formatTimeOfDay(reading.recordedAt)} - ${reading.pulse} bpm'
        : '${formatMonthDay(reading.recordedAt)} - ${reading.pulse} bpm';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
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
                  color: style.iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  style.icon,
                  color: style.accent,
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
                          reading.pressureLabel,
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
                              color: style.softBackground,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              style.label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: style.accent,
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
                      subtitle,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF93A7C7),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
