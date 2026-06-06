class DashboardHealthInsights {
  const DashboardHealthInsights({
    required this.bloodPressure,
    required this.bodyMass,
    required this.riskSignals,
  });

  final DashboardBloodPressureInsight bloodPressure;
  final DashboardBodyMassInsight bodyMass;
  final List<DashboardRiskSignal> riskSignals;

  factory DashboardHealthInsights.empty() {
    return DashboardHealthInsights(
      bloodPressure: DashboardBloodPressureInsight.empty(),
      bodyMass: DashboardBodyMassInsight.empty(),
      riskSignals: const [],
    );
  }
}

class DashboardBloodPressureInsight {
  const DashboardBloodPressureInsight({
    required this.hasReadings,
    required this.readingsCount,
    required this.measuredDaysLast30Days,
    required this.averageSystolic,
    required this.averageDiastolic,
    required this.averagePulse,
    required this.normalRangePercent,
    required this.latestCategory,
    required this.trend,
    required this.variability,
    required this.summary,
  });

  final bool hasReadings;
  final int readingsCount;
  final int measuredDaysLast30Days;
  final int? averageSystolic;
  final int? averageDiastolic;
  final int? averagePulse;
  final int? normalRangePercent;
  final String latestCategory;
  final String trend;
  final String variability;
  final String summary;

  factory DashboardBloodPressureInsight.empty() {
    return const DashboardBloodPressureInsight(
      hasReadings: false,
      readingsCount: 0,
      measuredDaysLast30Days: 0,
      averageSystolic: null,
      averageDiastolic: null,
      averagePulse: null,
      normalRangePercent: null,
      latestCategory: 'noData',
      trend: 'insufficientData',
      variability: 'insufficientData',
      summary:
          'Добавьте несколько измерений давления, чтобы увидеть средние значения и тренд.',
    );
  }

  String get trendLabel {
    switch (trend) {
      case 'improving':
        return 'Улучшается';
      case 'rising':
        return 'Растет';
      case 'stable':
        return 'Стабильно';
      default:
        return 'Мало данных';
    }
  }

  String get variabilityLabel {
    switch (variability) {
      case 'low':
        return 'Низкая';
      case 'moderate':
        return 'Умеренная';
      case 'high':
        return 'Высокая';
      default:
        return 'Мало данных';
    }
  }
}

class DashboardRiskSignal {
  const DashboardRiskSignal({
    required this.key,
    required this.level,
    required this.title,
    required this.description,
  });

  final String key;
  final String level;
  final String title;
  final String description;
}

class DashboardBodyMassInsight {
  const DashboardBodyMassInsight({
    required this.hasBodyMassData,
    required this.bmi,
    required this.category,
    required this.healthyWeightMinKg,
    required this.healthyWeightMaxKg,
    required this.weightDeltaKg,
    required this.summary,
  });

  final bool hasBodyMassData;
  final double? bmi;
  final String category;
  final double? healthyWeightMinKg;
  final double? healthyWeightMaxKg;
  final double? weightDeltaKg;
  final String summary;

  factory DashboardBodyMassInsight.empty() {
    return const DashboardBodyMassInsight(
      hasBodyMassData: false,
      bmi: null,
      category: 'noData',
      healthyWeightMinKg: null,
      healthyWeightMaxKg: null,
      weightDeltaKg: null,
      summary:
          'Укажите рост и вес в профиле, чтобы приложение рассчитало индекс массы тела.',
    );
  }

  String get categoryLabel {
    switch (category) {
      case 'underweight':
        return 'Дефицит массы';
      case 'normal':
        return 'Норма';
      case 'overweight':
        return 'Избыточная масса';
      case 'obesity':
        return 'Ожирение';
      default:
        return 'Нет данных';
    }
  }
}
