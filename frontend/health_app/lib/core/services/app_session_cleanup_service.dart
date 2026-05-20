import '../../features/dashboard/data/datasources/blood_pressure_local_data_source.dart';
import '../../features/meds/data/datasources/medication_local_data_source.dart';
import '../../features/metrics/data/datasources/health_metrics_local_data_source.dart';
import '../../features/profile/data/datasources/profile_local_data_source.dart';
import '../../features/visits/data/datasources/medical_visits_local_data_source.dart';
import 'local_notifications_service.dart';

class AppSessionCleanupService {
  AppSessionCleanupService({
    BloodPressureLocalDataSource? bloodPressureLocalDataSource,
    MedicationLocalDataSource? medicationLocalDataSource,
    HealthMetricsLocalDataSource? healthMetricsLocalDataSource,
    MedicalVisitsLocalDataSource? medicalVisitsLocalDataSource,
    ProfileLocalDataSource? profileLocalDataSource,
    LocalNotificationsService? notificationsService,
  }) : _bloodPressureLocalDataSource =
           bloodPressureLocalDataSource ?? BloodPressureLocalDataSource(),
       _medicationLocalDataSource =
           medicationLocalDataSource ?? MedicationLocalDataSource(),
       _healthMetricsLocalDataSource =
           healthMetricsLocalDataSource ?? HealthMetricsLocalDataSource(),
       _medicalVisitsLocalDataSource =
           medicalVisitsLocalDataSource ?? MedicalVisitsLocalDataSource(),
       _profileLocalDataSource =
           profileLocalDataSource ?? ProfileLocalDataSource(),
       _notificationsService =
           notificationsService ?? LocalNotificationsService.instance;

  final BloodPressureLocalDataSource _bloodPressureLocalDataSource;
  final MedicationLocalDataSource _medicationLocalDataSource;
  final HealthMetricsLocalDataSource _healthMetricsLocalDataSource;
  final MedicalVisitsLocalDataSource _medicalVisitsLocalDataSource;
  final ProfileLocalDataSource _profileLocalDataSource;
  final LocalNotificationsService _notificationsService;

  Future<void> clearUserScopedData() async {
    await Future.wait([
      _ignoreErrors(_notificationsService.cancelAllNotifications()),
      _ignoreErrors(_bloodPressureLocalDataSource.clear()),
      _ignoreErrors(_medicationLocalDataSource.clear()),
      _ignoreErrors(_healthMetricsLocalDataSource.clear()),
      _ignoreErrors(_medicalVisitsLocalDataSource.clear()),
      _ignoreErrors(_profileLocalDataSource.clear()),
    ]);
  }

  Future<void> _ignoreErrors(Future<void> operation) async {
    try {
      await operation;
    } catch (_) {
      return;
    }
  }
}
