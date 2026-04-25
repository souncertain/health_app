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
      final seededReadings = _buildSeedReadings();
      await saveAll(seededReadings);
      return seededReadings;
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

  List<BloodPressureReadingModel> _buildSeedReadings() {
    final now = DateTime.now();
    final seeded = <BloodPressureReadingModel>[
      _seededReading(
        id: 'bp-001',
        systolic: 119,
        diastolic: 77,
        pulse: 71,
        recordedAt: DateTime(now.year, now.month, now.day, 9, 30),
      ),
      _seededReading(
        id: 'bp-002',
        systolic: 132,
        diastolic: 85,
        pulse: 76,
        recordedAt: DateTime(now.year, now.month, now.day - 1, 8, 45),
      ),
      _seededReading(
        id: 'bp-003',
        systolic: 125,
        diastolic: 80,
        pulse: 74,
        recordedAt: DateTime(now.year, now.month, now.day - 2, 8, 20),
      ),
      _seededReading(
        id: 'bp-004',
        systolic: 118,
        diastolic: 76,
        pulse: 68,
        recordedAt: DateTime(now.year, now.month, now.day - 3, 9, 10),
      ),
      _seededReading(
        id: 'bp-005',
        systolic: 140,
        diastolic: 91,
        pulse: 82,
        recordedAt: DateTime(now.year, now.month, now.day - 4, 10, 0),
      ),
      _seededReading(
        id: 'bp-006',
        systolic: 121,
        diastolic: 79,
        pulse: 72,
        recordedAt: DateTime(now.year, now.month, now.day - 5, 8, 55),
      ),
      _seededReading(
        id: 'bp-007',
        systolic: 135,
        diastolic: 82,
        pulse: 74,
        recordedAt: DateTime(now.year, now.month, now.day - 6, 9, 15),
      ),
      _seededReading(
        id: 'bp-008',
        systolic: 126,
        diastolic: 77,
        pulse: 70,
        recordedAt: DateTime(now.year, now.month, now.day - 7, 9, 5),
      ),
      _seededReading(
        id: 'bp-009',
        systolic: 129,
        diastolic: 81,
        pulse: 72,
        recordedAt: DateTime(now.year, now.month, now.day - 10, 8, 35),
      ),
      _seededReading(
        id: 'bp-010',
        systolic: 124,
        diastolic: 79,
        pulse: 70,
        recordedAt: DateTime(now.year, now.month, now.day - 14, 9, 25),
      ),
      _seededReading(
        id: 'bp-011',
        systolic: 128,
        diastolic: 80,
        pulse: 73,
        recordedAt: DateTime(now.year, now.month, now.day - 18, 8, 10),
      ),
      _seededReading(
        id: 'bp-012',
        systolic: 123,
        diastolic: 78,
        pulse: 69,
        recordedAt: DateTime(now.year, now.month, now.day - 24, 8, 0),
      ),
    ];

    return seeded;
  }

  BloodPressureReadingModel _seededReading({
    required String id,
    required int systolic,
    required int diastolic,
    required int pulse,
    required DateTime recordedAt,
  }) {
    return BloodPressureReadingModel(
      id: id,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      recordedAt: recordedAt,
      createdAt: recordedAt,
      updatedAt: recordedAt,
    );
  }
}
