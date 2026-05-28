import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/meds/data/datasources/medication_local_data_source.dart';
import 'package:health_app/features/meds/data/models/medication_model.dart';
import 'package:health_app/features/meds/domain/entities/medication.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/test_data.dart';

void main() {
  late MedicationLocalDataSource dataSource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataSource = MedicationLocalDataSource();
  });

  test('getMedications returns empty list when storage is empty', () async {
    expect(await dataSource.getMedications(), isEmpty);
  });

  test('saveAll persists and restores medications', () async {
    final medications = [
      MedicationModel.fromEntity(sampleMedication(name: 'Aspirin')),
    ];

    await dataSource.saveAll(medications);

    final restored = await dataSource.getMedications();
    expect(restored.single.name, 'Aspirin');
  });

  test('migration removes legacy weekday status map on old storage version', () async {
    final legacyMedication = MedicationModel.fromEntity(
      sampleMedication(
        id: 'custom-med',
        dayStatuses: const {
          '1': MedicationDayStatus.pending,
          '2026-05-26': MedicationDayStatus.taken,
        },
      ),
    );

    SharedPreferences.setMockInitialValues({
      'meds.medications': jsonEncode([legacyMedication.toJson()]),
      'meds.medications.version': 3,
    });
    dataSource = MedicationLocalDataSource();

    final restored = await dataSource.getMedications();

    expect(restored.single.dayStatuses, isEmpty);
  });

  test('sanitization drops invalid non-date keys even on current storage version', () async {
    final medication = MedicationModel.fromJson({
      ...MedicationModel.fromEntity(sampleMedication()).toJson(),
      'dayStatuses': {
        '1': MedicationDayStatus.pending.name,
        '2026-05-26': MedicationDayStatus.taken.name,
      },
    });

    SharedPreferences.setMockInitialValues({
      'meds.medications': jsonEncode([medication.toJson()]),
      'meds.medications.version': 4,
    });
    dataSource = MedicationLocalDataSource();

    final restored = await dataSource.getMedications();

    expect(restored.single.dayStatuses.keys, ['2026-05-26']);
  });

  test('clear removes stored medications', () async {
    await dataSource.saveAll([
      MedicationModel.fromEntity(sampleMedication()),
    ]);

    await dataSource.clear();

    expect(await dataSource.getMedications(), isEmpty);
  });
}
