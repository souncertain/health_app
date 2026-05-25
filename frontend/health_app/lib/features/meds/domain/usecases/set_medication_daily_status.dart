import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class SetMedicationDailyStatusUseCase {
  const SetMedicationDailyStatusUseCase(this._repository);

  final MedicationRepository _repository;

  Future<void> call(
    String medicationId,
    DateTime date,
    MedicationDayStatus? status,
  ) {
    return _repository.setMedicationDailyStatus(medicationId, date, status);
  }
}
