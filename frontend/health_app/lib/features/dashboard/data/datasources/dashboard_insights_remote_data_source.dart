import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/dashboard_health_insights.dart';

class DashboardInsightsRemoteDataSource {
  DashboardInsightsRemoteDataSource({AuthenticatedApiClient? apiClient})
    : _apiClient = apiClient ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _apiClient;

  Future<DashboardHealthInsights> getInsights() async {
    final json = await _apiClient.getJson('/api/profile/me/insights');
    final map = json as Map<String, dynamic>;
    return DashboardHealthInsights(
      bloodPressure: _bloodPressureFromJson(
        map['bloodPressure'] as Map<String, dynamic>? ?? const {},
      ),
      bodyMass: _bodyMassFromJson(
        map['bodyMass'] as Map<String, dynamic>? ?? const {},
      ),
      riskSignals: ((map['riskSignals'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_riskSignalFromJson)
          .toList(),
    );
  }

  DashboardBloodPressureInsight _bloodPressureFromJson(
    Map<String, dynamic> json,
  ) {
    return DashboardBloodPressureInsight(
      hasReadings: json['hasReadings'] as bool? ?? false,
      readingsCount: (json['readingsCount'] as num?)?.toInt() ?? 0,
      measuredDaysLast30Days:
          (json['measuredDaysLast30Days'] as num?)?.toInt() ?? 0,
      averageSystolic: (json['averageSystolic'] as num?)?.toInt(),
      averageDiastolic: (json['averageDiastolic'] as num?)?.toInt(),
      averagePulse: (json['averagePulse'] as num?)?.toInt(),
      normalRangePercent: (json['normalRangePercent'] as num?)?.toInt(),
      latestCategory: json['latestCategory'] as String? ?? 'noData',
      trend: json['trend'] as String? ?? 'insufficientData',
      variability: json['variability'] as String? ?? 'insufficientData',
      summary: json['summary'] as String? ?? '',
    );
  }

  DashboardBodyMassInsight _bodyMassFromJson(Map<String, dynamic> json) {
    return DashboardBodyMassInsight(
      hasBodyMassData: json['hasBodyMassData'] as bool? ?? false,
      bmi: (json['bmi'] as num?)?.toDouble(),
      category: json['category'] as String? ?? 'noData',
      healthyWeightMinKg: (json['healthyWeightMinKg'] as num?)?.toDouble(),
      healthyWeightMaxKg: (json['healthyWeightMaxKg'] as num?)?.toDouble(),
      weightDeltaKg: (json['weightDeltaKg'] as num?)?.toDouble(),
      summary: json['summary'] as String? ?? '',
    );
  }

  DashboardRiskSignal _riskSignalFromJson(Map<String, dynamic> json) {
    return DashboardRiskSignal(
      key: json['key'] as String? ?? '',
      level: json['level'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
