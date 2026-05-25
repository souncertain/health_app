import '../entities/medication.dart';

abstract interface class MedicationRepository {
  Future<List<Medication>> getCachedMedications();

  Future<List<Medication>> getMedications();

  Future<void> saveMedication(Medication medication);

  Future<void> deleteMedication(String id);

  Future<void> setMedicationDailyStatus(
    String medicationId,
    DateTime date,
    MedicationDayStatus? status,
  );
}
