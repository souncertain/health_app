import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/blood_pressure_reading_model.dart';

class BloodPressureLocalDataSource {
  BloodPressureLocalDataSource();

  static const _storageKey = 'dashboard.blood_pressure_readings';

  Future<List<BloodPressureReadingModel>> getReadings() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) =>
              BloodPressureReadingModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveAll(List<BloodPressureReadingModel> readings) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      readings.map((reading) => reading.toJson()).toList(),
    );
    await preferences.setString(_storageKey, encoded);
  }
}
