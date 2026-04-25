import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/health_metric_item.dart';
import '../models/health_metric_model.dart';

class HealthMetricsLocalDataSource {
  HealthMetricsLocalDataSource();

  static const _storageKey = 'metrics.health_metrics';

  Future<List<HealthMetricModel>> getMetrics() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      final seededMetrics = _buildSeedMetrics();
      await saveAll(seededMetrics);
      return seededMetrics;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => HealthMetricModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<HealthMetricModel> metrics) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      metrics.map((metric) => metric.toJson()).toList(),
    );
    await preferences.setString(_storageKey, encoded);
  }

  List<HealthMetricModel> _buildSeedMetrics() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    return [
      _seedMetric(
        id: 'metric-001',
        title: 'Blood Sugar',
        unit: 'mg/dL',
        targetMin: 70,
        targetMax: 100,
        visualStyle: MetricVisualStyle.amberDrop,
        values: [94, 96, 95, 99, 97, 100, 98],
        referenceDate: normalizedToday,
      ),
      _seedMetric(
        id: 'metric-002',
        title: 'Hemoglobin',
        unit: 'g/dL',
        targetMin: 12,
        targetMax: 17.5,
        visualStyle: MetricVisualStyle.redCircle,
        values: [13.3, 13.4, 13.3, 13.6, 13.5, 13.7, 13.8],
        referenceDate: normalizedToday,
      ),
      _seedMetric(
        id: 'metric-003',
        title: 'Cholesterol',
        unit: 'mg/dL',
        targetMin: 0,
        targetMax: 200,
        visualStyle: MetricVisualStyle.violetHeart,
        values: [191, 188, 186, 184, 183, 185, 185],
        referenceDate: normalizedToday,
      ),
      _seedMetric(
        id: 'metric-004',
        title: 'BMI',
        unit: 'kg/m2',
        targetMin: 18.5,
        targetMax: 24.9,
        visualStyle: MetricVisualStyle.cyanBalance,
        values: [23.8, 23.7, 23.6, 23.5, 23.5, 23.4, 23.4],
        referenceDate: normalizedToday,
      ),
    ];
  }

  HealthMetricModel _seedMetric({
    required String id,
    required String title,
    required String unit,
    required double targetMin,
    required double targetMax,
    required MetricVisualStyle visualStyle,
    required List<double> values,
    required DateTime referenceDate,
  }) {
    final records = List<MetricRecord>.generate(values.length, (index) {
      final date = referenceDate.subtract(
        Duration(days: values.length - index - 1),
      );
      return MetricRecord(
        id: '$id-rec-$index',
        value: values[index],
        recordedOn: date,
        createdAt: date,
        updatedAt: date,
      );
    });

    return HealthMetricModel(
      id: id,
      title: title,
      unit: unit,
      targetMin: targetMin,
      targetMax: targetMax,
      visualStyle: visualStyle,
      records: records,
      createdAt: referenceDate.subtract(const Duration(days: 30)),
      updatedAt: referenceDate,
      isCustom: false,
    );
  }
}
