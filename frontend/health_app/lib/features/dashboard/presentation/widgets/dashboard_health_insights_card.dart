import 'package:flutter/material.dart';

import '../../domain/entities/dashboard_health_insights.dart';
import '../utils/blood_pressure_category_style.dart';

class DashboardHealthInsightsCard extends StatelessWidget {
  const DashboardHealthInsightsCard({
    super.key,
    required this.insight,
    this.compact = false,
  });

  final DashboardBloodPressureInsight insight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = resolveBloodPressureCategoryKeyStyle(insight.latestCategory);

    return _DashboardInsightShell(
      title: 'Анализ давления',
      icon: Icons.monitor_heart_outlined,
      accent: style.accent,
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  insight.hasReadings &&
                          insight.averageSystolic != null &&
                          insight.averageDiastolic != null
                      ? '${insight.averageSystolic}/${insight.averageDiastolic} мм рт. ст.'
                      : 'Недостаточно данных',
                  style: TextStyle(
                    color: const Color(0xFF0B1E4B),
                    fontSize: compact ? 22 : 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: style.softBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  style.label,
                  style: TextStyle(
                    color: style.accent,
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InsightFact(label: 'Тренд', value: insight.trendLabel),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InsightFact(
                  label: 'Вариабельность',
                  value: insight.variabilityLabel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InsightFact(
                  label: 'Норма за 30 дн.',
                  value: insight.normalRangePercent == null
                      ? '—'
                      : '${insight.normalRangePercent}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            insight.summary,
            style: TextStyle(
              color: const Color(0xFF516888),
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardBodyMassInsightCard extends StatelessWidget {
  const DashboardBodyMassInsightCard({
    super.key,
    required this.insight,
    this.compact = false,
  });

  final DashboardBodyMassInsight insight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chipStyle = _BodyMassStyle.fromCategory(insight.category);

    return _DashboardInsightShell(
      title: 'Масса тела и BMI',
      icon: Icons.balance_rounded,
      accent: chipStyle.accent,
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                insight.bmi?.toStringAsFixed(1) ?? '—',
                style: TextStyle(
                  color: const Color(0xFF0B1E4B),
                  fontSize: compact ? 34 : 38,
                  fontWeight: FontWeight.w800,
                  height: 0.95,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'BMI',
                  style: TextStyle(
                    color: const Color(0xFF7C8EA8),
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: chipStyle.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  insight.categoryLabel,
                  style: TextStyle(
                    color: chipStyle.accent,
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InsightFact(
                  label: 'Здоровый вес',
                  value:
                      insight.healthyWeightMinKg == null ||
                          insight.healthyWeightMaxKg == null
                      ? '—'
                      : '${insight.healthyWeightMinKg!.toStringAsFixed(1)}–${insight.healthyWeightMaxKg!.toStringAsFixed(1)} кг',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InsightFact(
                  label: 'Коррекция',
                  value: insight.weightDeltaKg == null
                      ? 'Не нужна'
                      : '${insight.weightDeltaKg!.abs().toStringAsFixed(1)} кг',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            insight.summary,
            style: TextStyle(
              color: const Color(0xFF516888),
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardRiskSignalsCard extends StatelessWidget {
  const DashboardRiskSignalsCard({
    super.key,
    required this.signals,
    this.compact = false,
  });

  final List<DashboardRiskSignal> signals;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _DashboardInsightShell(
      title: 'Сигналы риска',
      icon: Icons.health_and_safety_outlined,
      accent: const Color(0xFF2563EB),
      compact: compact,
      child: Column(
        children: signals
            .map(
              (signal) => Padding(
                padding: EdgeInsets.only(
                  bottom: signal == signals.last ? 0 : 12,
                ),
                child: _RiskSignalTile(signal: signal, compact: compact),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DashboardInsightShell extends StatelessWidget {
  const _DashboardInsightShell({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
    required this.compact,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCAEED0).withValues(alpha: 0.28),
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF0B1E4B),
                  fontSize: compact ? 20 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InsightFact extends StatelessWidget {
  const _InsightFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7C8EA8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0B1E4B),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyMassStyle {
  const _BodyMassStyle({required this.accent, required this.background});

  final Color accent;
  final Color background;

  factory _BodyMassStyle.fromCategory(String category) {
    switch (category) {
      case 'normal':
        return const _BodyMassStyle(
          accent: Color(0xFF1DB954),
          background: Color(0xFFE7FAED),
        );
      case 'underweight':
        return const _BodyMassStyle(
          accent: Color(0xFF2563EB),
          background: Color(0xFFE6F0FF),
        );
      case 'overweight':
        return const _BodyMassStyle(
          accent: Color(0xFFF59E0B),
          background: Color(0xFFFFF3DA),
        );
      case 'obesity':
        return const _BodyMassStyle(
          accent: Color(0xFFEF4444),
          background: Color(0xFFFFE3E3),
        );
      default:
        return const _BodyMassStyle(
          accent: Color(0xFF7C8EA8),
          background: Color(0xFFF0F4F8),
        );
    }
  }
}

class _RiskSignalTile extends StatelessWidget {
  const _RiskSignalTile({required this.signal, required this.compact});

  final DashboardRiskSignal signal;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = _RiskSignalStyle.fromLevel(signal.level);

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        compact ? 14 : 16,
        compact ? 14 : 16,
        compact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: style.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, color: style.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        signal.title,
                        style: TextStyle(
                          color: const Color(0xFF0B1E4B),
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: style.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        style.label,
                        style: TextStyle(
                          color: style.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  signal.description,
                  style: TextStyle(
                    color: const Color(0xFF516888),
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskSignalStyle {
  const _RiskSignalStyle({
    required this.label,
    required this.accent,
    required this.background,
    required this.border,
    required this.icon,
  });

  final String label;
  final Color accent;
  final Color background;
  final Color border;
  final IconData icon;

  factory _RiskSignalStyle.fromLevel(String level) {
    switch (level) {
      case 'high':
        return const _RiskSignalStyle(
          label: 'Высокий',
          accent: Color(0xFFDC2626),
          background: Color(0xFFFFF1F1),
          border: Color(0xFFF8CACA),
          icon: Icons.priority_high_rounded,
        );
      case 'medium':
        return const _RiskSignalStyle(
          label: 'Умеренный',
          accent: Color(0xFFD97706),
          background: Color(0xFFFFF8E8),
          border: Color(0xFFF6DFAC),
          icon: Icons.warning_amber_rounded,
        );
      default:
        return const _RiskSignalStyle(
          label: 'Наблюдать',
          accent: Color(0xFF2563EB),
          background: Color(0xFFF1F6FF),
          border: Color(0xFFD7E6FF),
          icon: Icons.info_outline_rounded,
        );
    }
  }
}
