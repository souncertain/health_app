import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/health_metric_model.dart';

class HealthMetricsLocalDataSource {
  HealthMetricsLocalDataSource();

  static const _storageKey = 'metrics.health_metrics';
  static const _storageVersionKey = 'metrics.health_metrics.version';
  static const _currentStorageVersion = 2;
  List<HealthMetricModel>? _cachedMetrics;
  bool _hasLoadedCache = false;

  Future<List<HealthMetricModel>> getMetrics() async {
    if (_hasLoadedCache) {
      return List<HealthMetricModel>.from(_cachedMetrics ?? const []);
    }

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      _cachedMetrics = const [];
      _hasLoadedCache = true;
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final storedVersion = preferences.getInt(_storageVersionKey) ?? 1;
    final normalizedDecoded = storedVersion < _currentStorageVersion
        ? _migrateStoredMetrics(decoded)
        : decoded
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();

    final metrics = normalizedDecoded.map(HealthMetricModel.fromJson).toList();

    if (storedVersion < _currentStorageVersion) {
      await saveAll(metrics);
    }

    _cachedMetrics = List<HealthMetricModel>.from(metrics);
    _hasLoadedCache = true;
    return List<HealthMetricModel>.from(metrics);
  }

  Future<void> saveAll(List<HealthMetricModel> metrics) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      metrics.map((metric) => metric.toJson()).toList(),
    );
    await preferences.setString(_storageKey, encoded);
    await preferences.setInt(_storageVersionKey, _currentStorageVersion);
    _cachedMetrics = List<HealthMetricModel>.from(metrics);
    _hasLoadedCache = true;
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
    await preferences.remove(_storageVersionKey);
    _cachedMetrics = null;
    _hasLoadedCache = true;
  }

  List<Map<String, dynamic>> _migrateStoredMetrics(List<dynamic> decoded) {
    return decoded.map((item) {
      final json = Map<String, dynamic>.from(item as Map);
      final id = json['id'] as String? ?? '';
      final title = json['title'] as String? ?? '';

      switch (id) {
        case 'metric-001':
          if (title == 'Blood Sugar') {
            json['title'] = 'РЎР°С…Р°СЂ РІ РєСЂРѕРІРё';
          }
          break;
        case 'metric-002':
          if (title == 'Hemoglobin') {
            json['title'] = 'Р“РµРјРѕРіР»РѕР±РёРЅ';
          }
          break;
        case 'metric-003':
          if (title == 'Cholesterol') {
            json['title'] = 'РҐРѕР»РµСЃС‚РµСЂРёРЅ';
          }
          break;
        case 'metric-004':
          if (title == 'BMI') {
            json['title'] = 'РРњРў';
          }
          break;
      }

      return json;
    }).toList();
  }
}
