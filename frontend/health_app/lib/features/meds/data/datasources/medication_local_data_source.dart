import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/medication.dart';
import '../models/medication_model.dart';

class MedicationLocalDataSource {
  MedicationLocalDataSource();

  static const _storageKey = 'meds.medications';
  static const _storageVersionKey = 'meds.medications.version';
  static const _currentStorageVersion = 4;
  static const _legacySeedIds = {'med-001', 'med-002', 'med-003', 'med-004'};
  List<MedicationModel>? _cachedMedications;
  bool _hasLoadedCache = false;

  Future<List<MedicationModel>> getMedications() async {
    if (_hasLoadedCache) {
      return List<MedicationModel>.from(_cachedMedications ?? const []);
    }

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      _cachedMedications = const [];
      _hasLoadedCache = true;
      return const [];
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
    final sanitizedMedications = _sanitizeLoadedMedications(medications);

    if (storedVersion < _currentStorageVersion ||
        !_hasSameStatuses(medications, sanitizedMedications)) {
      await saveAll(sanitizedMedications);
    }

    _cachedMedications = List<MedicationModel>.from(sanitizedMedications);
    _hasLoadedCache = true;
    return List<MedicationModel>.from(sanitizedMedications);
  }

  Future<void> saveAll(List<MedicationModel> medications) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      medications.map((medication) => medication.toJson()).toList(),
    );
    await preferences.setString(_storageKey, encoded);
    await preferences.setInt(_storageVersionKey, _currentStorageVersion);
    _cachedMedications = List<MedicationModel>.from(medications);
    _hasLoadedCache = true;
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
    await preferences.remove(_storageVersionKey);
    _cachedMedications = null;
    _hasLoadedCache = true;
  }

  List<Map<String, dynamic>> _migrateStoredMedications(
    List<dynamic> decoded,
    int storedVersion,
  ) {
    return decoded.map((item) {
      final json = Map<String, dynamic>.from(item as Map);
      final id = json['id'] as String? ?? '';
      final isLegacySeed = _legacySeedIds.contains(id);

      if (isLegacySeed && storedVersion < 2) {
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

      if (isLegacySeed && storedVersion < 3) {
        final currentName = json['name'] as String? ?? '';
        switch (id) {
          case 'med-001':
            if (currentName == 'Lisinopril') {
              json['name'] = 'Р›РёР·РёРЅРѕРїСЂРёР»';
            }
            if (json['dosage'] == '10mg') {
              json['dosage'] = '10 РјРі';
            }
            break;
          case 'med-002':
            if (currentName == 'Metformin') {
              json['name'] = 'РњРµС‚С„РѕСЂРјРёРЅ';
            }
            if (json['dosage'] == '500mg') {
              json['dosage'] = '500 РјРі';
            }
            break;
          case 'med-003':
            if (currentName == 'Atorvastatin') {
              json['name'] = 'РђС‚РѕСЂРІР°СЃС‚Р°С‚РёРЅ';
            }
            if (json['dosage'] == '20mg') {
              json['dosage'] = '20 РјРі';
            }
            break;
          case 'med-004':
            if (currentName == 'Aspirin') {
              json['name'] = 'РђСЃРїРёСЂРёРЅ';
            }
            if (json['dosage'] == '100mg') {
              json['dosage'] = '100 РјРі';
            }
            break;
        }
      }

      if (storedVersion < 4) {
        final existingStatuses = Map<String, dynamic>.from(
          json['dayStatuses'] as Map<String, dynamic>? ?? const {},
        );
        final isLegacyWeekdayMap = existingStatuses.keys.any(
          (key) => !key.contains('-'),
        );
        if (isLegacyWeekdayMap) {
          json['dayStatuses'] = <String, dynamic>{};
        }
      }

      return json;
    }).toList();
  }

  List<MedicationModel> _sanitizeLoadedMedications(
    List<MedicationModel> medications,
  ) {
    return medications.map((medication) {
      final sanitizedStatuses = <String, MedicationDayStatus>{};
      for (final entry in medication.dayStatuses.entries) {
        if (_isDateKey(entry.key)) {
          sanitizedStatuses[entry.key] = entry.value;
        }
      }

      if (sanitizedStatuses.length == medication.dayStatuses.length) {
        return medication;
      }

      return MedicationModel.fromEntity(
        medication.copyWith(dayStatuses: sanitizedStatuses),
      );
    }).toList();
  }

  bool _hasSameStatuses(
    List<MedicationModel> original,
    List<MedicationModel> sanitized,
  ) {
    if (original.length != sanitized.length) {
      return false;
    }

    for (var index = 0; index < original.length; index++) {
      final originalStatuses = original[index].dayStatuses;
      final sanitizedStatuses = sanitized[index].dayStatuses;
      if (originalStatuses.length != sanitizedStatuses.length) {
        return false;
      }

      for (final entry in originalStatuses.entries) {
        if (sanitizedStatuses[entry.key] != entry.value) {
          return false;
        }
      }
    }

    return true;
  }

  bool _isDateKey(String key) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
      return false;
    }

    try {
      DateTime.parse(key);
      return true;
    } on FormatException {
      return false;
    }
  }
}
