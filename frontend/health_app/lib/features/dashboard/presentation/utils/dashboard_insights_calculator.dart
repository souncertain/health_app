import '../../../profile/domain/entities/user_profile.dart';
import '../../domain/entities/blood_pressure_reading.dart';
import '../../domain/entities/dashboard_health_insights.dart';

class DashboardInsightsCalculator {
  const DashboardInsightsCalculator._();

  static DashboardHealthInsights fromLocalData({
    required UserProfile? profile,
    required List<BloodPressureReading> readings,
  }) {
    return DashboardHealthInsights(
      bloodPressure: _bloodPressureInsight(profile, readings),
      bodyMass: _bodyMassInsight(profile),
      riskSignals: _riskSignals(profile, readings),
    );
  }

  static DashboardBloodPressureInsight _bloodPressureInsight(
    UserProfile? profile,
    List<BloodPressureReading> readings,
  ) {
    if (readings.isEmpty) {
      return DashboardBloodPressureInsight.empty();
    }

    final ordered = List<BloodPressureReading>.from(readings)
      ..sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    final now = DateTime.now();
    final last30Days = ordered
        .where(
          (reading) => reading.recordedAt.isAfter(
            now.subtract(const Duration(days: 30)),
          ),
        )
        .toList();
    final last7Days = ordered
        .where(
          (reading) =>
              reading.recordedAt.isAfter(now.subtract(const Duration(days: 7))),
        )
        .toList();
    final previous7Days = ordered
        .where(
          (reading) =>
              reading.recordedAt.isBefore(
                now.subtract(const Duration(days: 7)),
              ) &&
              reading.recordedAt.isAfter(
                now.subtract(const Duration(days: 14)),
              ),
        )
        .toList();
    final averageWindow = last7Days.isNotEmpty ? last7Days : ordered;
    final age = profile?.displayAge;
    final requiresPediatricAssessment = age != null && age < 13;
    final trend = _resolveTrend(averageWindow, previous7Days);
    final variability = _resolveVariability(ordered.take(10).toList());

    return DashboardBloodPressureInsight(
      hasReadings: true,
      readingsCount: ordered.length,
      measuredDaysLast30Days: last30Days
          .map(
            (reading) => DateTime(
              reading.recordedAt.year,
              reading.recordedAt.month,
              reading.recordedAt.day,
            ),
          )
          .toSet()
          .length,
      averageSystolic: _averageOf(averageWindow.map((item) => item.systolic)),
      averageDiastolic: _averageOf(averageWindow.map((item) => item.diastolic)),
      averagePulse: _averageOf(averageWindow.map((item) => item.pulse)),
      normalRangePercent: requiresPediatricAssessment
          ? null
          : last30Days.isEmpty
          ? 0
          : ((last30Days
                            .where(
                              (item) =>
                                  item.category == BloodPressureCategory.normal,
                            )
                            .length *
                        100) /
                    last30Days.length)
                .round(),
      latestCategory: requiresPediatricAssessment
          ? 'requiresPediatricAssessment'
          : _categoryKey(ordered.first.category),
      trend: trend,
      variability: variability,
      summary: _bloodPressureSummary(
        age,
        ordered.first.category,
        trend,
        variability,
      ),
    );
  }

  static DashboardBodyMassInsight _bodyMassInsight(UserProfile? profile) {
    final bmi = profile?.bmi;
    final heightCm = profile?.heightCm;
    final weightKg = profile?.weightKg;

    if (bmi == null || heightCm == null || heightCm == 0 || weightKg == null) {
      return DashboardBodyMassInsight.empty();
    }

    final heightMeters = heightCm / 100;
    final minHealthyWeight = 18.5 * heightMeters * heightMeters;
    final maxHealthyWeight = 24.9 * heightMeters * heightMeters;
    final category = _resolveBmiCategory(bmi);

    double? weightDeltaKg;
    if (bmi < 18.5) {
      weightDeltaKg = double.parse(
        (minHealthyWeight - weightKg).toStringAsFixed(1),
      );
    } else if (bmi > 24.9) {
      weightDeltaKg = double.parse(
        (maxHealthyWeight - weightKg).toStringAsFixed(1),
      );
    }

    return DashboardBodyMassInsight(
      hasBodyMassData: true,
      bmi: double.parse(bmi.toStringAsFixed(1)),
      category: category,
      healthyWeightMinKg: double.parse(minHealthyWeight.toStringAsFixed(1)),
      healthyWeightMaxKg: double.parse(maxHealthyWeight.toStringAsFixed(1)),
      weightDeltaKg: weightDeltaKg,
      summary: _bodyMassSummary(category, weightDeltaKg),
    );
  }

  static String _categoryKey(BloodPressureCategory category) {
    switch (category) {
      case BloodPressureCategory.normal:
        return 'normal';
      case BloodPressureCategory.elevated:
        return 'elevated';
      case BloodPressureCategory.highStage1:
        return 'highStage1';
      case BloodPressureCategory.highStage2:
        return 'highStage2';
      case BloodPressureCategory.hypertensiveCrisis:
        return 'hypertensiveCrisis';
    }
  }

  static int _averageOf(Iterable<int> values) {
    final list = values.toList();
    if (list.isEmpty) {
      return 0;
    }
    final sum = list.fold<int>(0, (acc, item) => acc + item);
    return (sum / list.length).round();
  }

  static String _resolveTrend(
    List<BloodPressureReading> recent,
    List<BloodPressureReading> previous,
  ) {
    if (recent.length < 2 || previous.length < 2) {
      return 'insufficientData';
    }

    final recentSystolic =
        recent.map((item) => item.systolic).reduce((a, b) => a + b) /
        recent.length;
    final recentDiastolic =
        recent.map((item) => item.diastolic).reduce((a, b) => a + b) /
        recent.length;
    final previousSystolic =
        previous.map((item) => item.systolic).reduce((a, b) => a + b) /
        previous.length;
    final previousDiastolic =
        previous.map((item) => item.diastolic).reduce((a, b) => a + b) /
        previous.length;

    if (recentSystolic <= previousSystolic - 5 &&
        recentDiastolic <= previousDiastolic - 3) {
      return 'improving';
    }
    if (recentSystolic >= previousSystolic + 5 ||
        recentDiastolic >= previousDiastolic + 3) {
      return 'rising';
    }
    return 'stable';
  }

  static String _resolveVariability(List<BloodPressureReading> readings) {
    if (readings.length < 3) {
      return 'insufficientData';
    }

    final average =
        readings.map((item) => item.systolic).reduce((a, b) => a + b) /
        readings.length;
    final variance =
        readings
            .map(
              (item) => (item.systolic - average) * (item.systolic - average),
            )
            .reduce((a, b) => a + b) /
        readings.length;
    final deviation = variance >= 0 ? variance.sqrt() : 0.0;

    if (deviation < 8) {
      return 'low';
    }
    if (deviation < 15) {
      return 'moderate';
    }
    return 'high';
  }

  static String _bloodPressureSummary(
    int? age,
    BloodPressureCategory category,
    String trend,
    String variability,
  ) {
    if (age != null && age < 13) {
      return 'Для детей младше 13 лет оценка давления зависит от возраста, пола и роста. Приложение показывает динамику измерений, а клиническую интерпретацию лучше сверять с педиатрическими таблицами.';
    }

    final categoryText = switch (category) {
      BloodPressureCategory.normal =>
        'Последнее измерение находится в нормальном диапазоне.',
      BloodPressureCategory.elevated =>
        'Давление выше оптимального уровня и требует наблюдения.',
      BloodPressureCategory.highStage1 =>
        'Показатели соответствуют гипертензии 1 стадии.',
      BloodPressureCategory.highStage2 =>
        'Показатели соответствуют гипертензии 2 стадии.',
      BloodPressureCategory.hypertensiveCrisis =>
        'Показатели находятся в критически высоком диапазоне.',
    };
    final trendText = switch (trend) {
      'improving' =>
        'Средние значения улучшаются по сравнению с предыдущей неделей.',
      'rising' => 'Средние значения растут и требуют дополнительного контроля.',
      'stable' => 'Динамика за последние недели остаётся стабильной.',
      _ => 'Для оценки тренда нужно больше регулярных измерений.',
    };
    final variabilityText = switch (variability) {
      'low' => 'Колебания давления небольшие.',
      'moderate' => 'Колебания давления умеренные.',
      'high' => 'Колебания давления выражены сильнее обычного.',
      _ => '',
    };

    return [
      categoryText,
      trendText,
      variabilityText,
    ].where((item) => item.isNotEmpty).join(' ');
  }

  static String _resolveBmiCategory(double bmi) {
    if (bmi < 18.5) {
      return 'underweight';
    }
    if (bmi < 25) {
      return 'normal';
    }
    if (bmi < 30) {
      return 'overweight';
    }
    return 'obesity';
  }

  static String _bodyMassSummary(String category, double? weightDeltaKg) {
    switch (category) {
      case 'underweight':
        return weightDeltaKg == null
            ? 'Масса тела ниже рекомендуемого диапазона.'
            : 'Масса тела ниже рекомендуемого диапазона. До нижней границы комфортного диапазона не хватает около ${weightDeltaKg.toStringAsFixed(1)} кг.';
      case 'normal':
        return 'Масса тела находится в рекомендуемом диапазоне по индексу массы тела.';
      case 'overweight':
        return weightDeltaKg == null
            ? 'Есть избыток массы тела.'
            : 'Есть избыток массы тела. Для возврата к верхней границе рекомендуемого диапазона нужно снизить примерно ${weightDeltaKg.abs().toStringAsFixed(1)} кг.';
      case 'obesity':
        return weightDeltaKg == null
            ? 'Индекс массы тела соответствует ожирению.'
            : 'Индекс массы тела соответствует ожирению. Для возврата к верхней границе рекомендуемого диапазона нужно снизить примерно ${weightDeltaKg.abs().toStringAsFixed(1)} кг.';
      default:
        return 'Укажите рост и вес в профиле, чтобы приложение рассчитало индекс массы тела.';
    }
  }

  static List<DashboardRiskSignal> _riskSignals(
    UserProfile? profile,
    List<BloodPressureReading> readings,
  ) {
    final signals = <DashboardRiskSignal>[];
    final ordered = List<BloodPressureReading>.from(readings)
      ..sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    final latest = ordered.isEmpty ? null : ordered.first;
    final age = profile?.displayAge;
    final bmi = profile?.bmi;
    final hasAdultBloodPressureAssessment = age == null || age >= 13;
    final recentPulseWindow = ordered.take(7).toList();
    final averagePulse = recentPulseWindow.isEmpty
        ? null
        : recentPulseWindow.map((item) => item.pulse).reduce((a, b) => a + b) /
              recentPulseWindow.length;

    if (latest != null && hasAdultBloodPressureAssessment) {
      switch (latest.category) {
        case BloodPressureCategory.highStage2:
        case BloodPressureCategory.hypertensiveCrisis:
          signals.add(
            const DashboardRiskSignal(
              key: 'bloodPressureHighRisk',
              level: 'high',
              title: 'Высокий риск осложнений из-за давления',
              description:
                  'Последние измерения соответствуют выраженно повышенному давлению. Это увеличивает риск инсульта, болезней сердца и поражения почек.',
            ),
          );
          break;
        case BloodPressureCategory.highStage1:
        case BloodPressureCategory.elevated:
          signals.add(
            const DashboardRiskSignal(
              key: 'bloodPressureAttention',
              level: 'medium',
              title: 'Давление требует наблюдения',
              description:
                  'Показатели давления выше оптимального диапазона. При повторяющихся значениях стоит продолжать контроль и обсудить ситуацию с врачом.',
            ),
          );
          break;
        case BloodPressureCategory.normal:
          break;
      }
    }

    if (averagePulse != null) {
      if (averagePulse > 100) {
        signals.add(
          const DashboardRiskSignal(
            key: 'pulseHigh',
            level: 'medium',
            title: 'Пульс выше нормы покоя',
            description:
                'Средний пульс по недавним измерениям превышает 100 ударов в минуту. Это повод внимательнее наблюдать за самочувствием и повторными измерениями.',
          ),
        );
      } else if (averagePulse < 60) {
        signals.add(
          const DashboardRiskSignal(
            key: 'pulseLow',
            level: 'low',
            title: 'Пульс ниже типичного диапазона',
            description:
                'Средний пульс по недавним измерениям ниже 60 ударов в минуту. Для части людей это может быть вариантом нормы, но при симптомах стоит оценить показатель отдельно.',
          ),
        );
      }
    }

    if (bmi != null) {
      if (bmi >= 30) {
        signals.add(
          const DashboardRiskSignal(
            key: 'obesityRisk',
            level: 'high',
            title: 'Выраженный кардиометаболический риск по массе тела',
            description:
                'Индекс массы тела соответствует ожирению. Это связано с более высоким риском гипертонии, диабета 2 типа и сердечно-сосудистых заболеваний.',
          ),
        );
      } else if (bmi >= 25) {
        signals.add(
          const DashboardRiskSignal(
            key: 'overweightRisk',
            level: 'medium',
            title: 'Повышенный риск из-за избыточной массы',
            description:
                'Избыточная масса тела повышает вероятность роста давления и метаболических нарушений. Полезно наблюдать за весом в динамике.',
          ),
        );
      }
    }

    if (age != null && age >= 45 && bmi != null && bmi >= 25) {
      signals.add(
        DashboardRiskSignal(
          key: 'diabetesRisk',
          level: bmi >= 30 ? 'high' : 'medium',
          title: 'Сигнал риска предиабета и диабета 2 типа',
          description:
              'Возраст старше 45 лет в сочетании с избыточной массой тела считается важным фактором риска нарушений углеводного обмена.',
        ),
      );
    }

    if (age != null &&
        age >= 45 &&
        bmi != null &&
        bmi >= 25 &&
        latest != null &&
        hasAdultBloodPressureAssessment &&
        latest.category != BloodPressureCategory.normal) {
      signals.add(
        DashboardRiskSignal(
          key: 'cardiometabolicRisk',
          level: bmi >= 30 || latest.category != BloodPressureCategory.elevated
              ? 'high'
              : 'medium',
          title: 'Кардиометаболический риск повышен',
          description:
              'Сочетание возраста, повышенного давления и избыточной массы тела связано с более высоким риском сердечно-сосудистых и обменных нарушений.',
        ),
      );
    }

    final uniqueSignals = <String, DashboardRiskSignal>{};
    for (final signal in signals) {
      uniqueSignals[signal.key] = signal;
    }
    return uniqueSignals.values.toList();
  }
}

extension on num {
  double sqrt() {
    var x = toDouble();
    if (x <= 0) {
      return 0;
    }

    var guess = x;
    for (var i = 0; i < 8; i++) {
      guess = 0.5 * (guess + x / guess);
    }
    return guess;
  }
}
