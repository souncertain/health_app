import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/medication.dart';
import '../models/medication_model.dart';

class MedicationLocalDataSource {
  MedicationLocalDataSource();

  static const _storageKey = 'meds.medications';
  static const _storageVersionKey = 'meds.medications.version';
  static const _currentStorageVersion = 3;
  static const _legacySeedIds = {'med-001', 'med-002', 'med-003', 'med-004'};

  Future<List<MedicationModel>> getMedications() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      final seeded = _buildSeedMedications();
      await saveAll(seeded);
      return seeded;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final storedVersion = preferences.getInt(_storageVersionKey) ?? 1;
    final normalizedDecoded = storedVersion < _currentStorageVersion
        ? _migrateStoredMedications(decoded, storedVersion)
        : decoded
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();

    final medications = normalizedDecoded
        .map(MedicationModel.fromJson)
        .toList();

    if (storedVersion < _currentStorageVersion) {
      await saveAll(medications);
    }

    return medications;
  }

  Future<void> saveAll(List<MedicationModel> medications) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      medications.map((medication) => medication.toJson()).toList(),
    );
    await preferences.setString(_storageKey, encoded);
    await preferences.setInt(_storageVersionKey, _currentStorageVersion);
  }

  List<Map<String, dynamic>> _migrateStoredMedications(
    List<dynamic> decoded,
    int storedVersion,
  ) {
    return decoded.map((item) {
      final json = Map<String, dynamic>.from(item as Map);
      final id = json['id'] as String? ?? '';
      if (!_legacySeedIds.contains(id)) {
        return json;
      }

      if (storedVersion < 2) {
        final scheduledWeekdays =
            (json['scheduledWeekdays'] as List<dynamic>? ?? const <dynamic>[])
                .map((value) => value as int)
                .toList();
        final existingStatuses = Map<String, dynamic>.from(
          json['dayStatuses'] as Map<String, dynamic>? ?? const {},
        );

        json['dayStatuses'] = {
          for (final weekday in scheduledWeekdays)
            '$weekday':
                existingStatuses['$weekday'] == MedicationDayStatus.missed.name
                ? MedicationDayStatus.missed.name
                : MedicationDayStatus.pending.name,
        };
      }

      if (storedVersion < 3) {
        final currentName = json['name'] as String? ?? '';
        switch (id) {
          case 'med-001':
            if (currentName == 'Lisinopril') {
              json['name'] = 'Лизиноприл';
            }
            if (json['dosage'] == '10mg') {
              json['dosage'] = '10 мг';
            }
            break;
          case 'med-002':
            if (currentName == 'Metformin') {
              json['name'] = 'Метформин';
            }
            if (json['dosage'] == '500mg') {
              json['dosage'] = '500 мг';
            }
            break;
          case 'med-003':
            if (currentName == 'Atorvastatin') {
              json['name'] = 'Аторвастатин';
            }
            if (json['dosage'] == '20mg') {
              json['dosage'] = '20 мг';
            }
            break;
          case 'med-004':
            if (currentName == 'Aspirin') {
              json['name'] = 'Аспирин';
            }
            if (json['dosage'] == '100mg') {
              json['dosage'] = '100 мг';
            }
            break;
        }
      }

      return json;
    }).toList();
  }

  List<MedicationModel> _buildSeedMedications() {
    final now = DateTime.now();
    final weekdays = List<int>.generate(7, (index) => index + 1);
    final pendingStatuses = {
      for (final weekday in weekdays) weekday: MedicationDayStatus.pending,
    };

    return [
      MedicationModel(
        id: 'med-001',
        name: 'Лизиноприл',
        dosage: '10 мг',
        frequency: MedicationFrequency.onceDaily,
        timesInMinutes: const [8 * 60],
        notificationsEnabled: true,
        form: MedicationForm.capsule,
        scheduledWeekdays: weekdays,
        dayStatuses: Map<int, MedicationDayStatus>.from(pendingStatuses),
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      MedicationModel(
        id: 'med-002',
        name: 'Метформин',
        dosage: '500 мг',
        frequency: MedicationFrequency.twiceDaily,
        timesInMinutes: const [8 * 60, 20 * 60],
        notificationsEnabled: true,
        form: MedicationForm.syringe,
        scheduledWeekdays: weekdays,
        dayStatuses: Map<int, MedicationDayStatus>.from(pendingStatuses),
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      ),
      MedicationModel(
        id: 'med-003',
        name: 'Аторвастатин',
        dosage: '20 мг',
        frequency: MedicationFrequency.onceDaily,
        timesInMinutes: const [22 * 60],
        notificationsEnabled: false,
        form: MedicationForm.circle,
        scheduledWeekdays: weekdays,
        dayStatuses: Map<int, MedicationDayStatus>.from(pendingStatuses),
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      MedicationModel(
        id: 'med-004',
        name: 'Аспирин',
        dosage: '100 мг',
        frequency: MedicationFrequency.onceDaily,
        timesInMinutes: const [7 * 60],
        notificationsEnabled: true,
        form: MedicationForm.tablet,
        scheduledWeekdays: weekdays,
        dayStatuses: Map<int, MedicationDayStatus>.from(pendingStatuses),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
