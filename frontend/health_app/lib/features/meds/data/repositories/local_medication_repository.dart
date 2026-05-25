import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/medication_local_data_source.dart';
import '../models/medication_model.dart';

class LocalMedicationRepository implements MedicationRepository {
  const LocalMedicationRepository(this._localDataSource);

  final MedicationLocalDataSource _localDataSource;

  @override
  Future<List<Medication>> getCachedMedications() {
    return getMedications();
  }

  @override
  Future<void> deleteMedication(String id) async {
    final medications = await _localDataSource.getMedications();
    final updated = medications
        .where((medication) => medication.id != id)
        .toList();
    await _localDataSource.saveAll(updated);
  }

  @override
  Future<List<Medication>> getMedications() async {
    final medications = await _localDataSource.getMedications();
    medications.sort(
      (left, right) =>
          left.timesInMinutes.first.compareTo(right.timesInMinutes.first),
    );
    return medications;
  }

  @override
  Future<void> saveMedication(Medication medication) async {
    final medications = await _localDataSource.getMedications();
    final model = MedicationModel.fromEntity(medication);
    final index = medications.indexWhere((item) => item.id == medication.id);

    if (index == -1) {
      medications.add(model);
    } else {
      medications[index] = model;
    }

    medications.sort(
      (left, right) =>
          left.timesInMinutes.first.compareTo(right.timesInMinutes.first),
    );
    await _localDataSource.saveAll(medications);
  }

  @override
  Future<void> setMedicationDailyStatus(
    String medicationId,
    DateTime date,
    MedicationDayStatus? status,
  ) async {
    final medications = await _localDataSource.getMedications();
    final index = medications.indexWhere((item) => item.id == medicationId);
    if (index == -1) {
      return;
    }

    final updated = medications[index].copyWithStatusForDate(date, status);
    medications[index] = MedicationModel.fromEntity(updated);
    await _localDataSource.saveAll(medications);
  }
}
