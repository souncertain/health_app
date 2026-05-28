import 'package:health_app/core/services/app_session_cleanup_service.dart';
import 'package:health_app/core/services/local_notifications_service.dart';
import 'package:health_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:health_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:health_app/features/auth/data/datasources/secure_credentials_data_source.dart';
import 'package:health_app/features/auth/data/models/auth_session_model.dart';
import 'package:health_app/features/auth/data/models/provider_authorization_grant.dart';
import 'package:health_app/features/auth/data/services/oauth_identity_provider.dart';
import 'package:health_app/features/auth/domain/entities/auth_session.dart';
import 'package:health_app/features/auth/domain/entities/auth_register_result.dart';
import 'package:health_app/features/auth/domain/entities/saved_credentials.dart';
import 'package:health_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:health_app/features/dashboard/data/datasources/blood_pressure_local_data_source.dart';
import 'package:health_app/features/dashboard/domain/entities/blood_pressure_reading.dart';
import 'package:health_app/features/dashboard/domain/repositories/blood_pressure_repository.dart';
import 'package:health_app/features/meds/data/datasources/medication_local_data_source.dart';
import 'package:health_app/features/meds/domain/entities/medication.dart';
import 'package:health_app/features/meds/domain/repositories/medication_repository.dart';
import 'package:health_app/features/metrics/data/datasources/health_metrics_local_data_source.dart';
import 'package:health_app/features/metrics/domain/entities/health_metric_item.dart';
import 'package:health_app/features/metrics/domain/repositories/health_metric_repository.dart';
import 'package:health_app/features/profile/domain/entities/profile_stats_snapshot.dart';
import 'package:health_app/features/profile/domain/entities/user_profile.dart';
import 'package:health_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:health_app/features/profile/domain/repositories/profile_stats_repository.dart';
import 'package:health_app/features/visits/data/datasources/medical_visits_local_data_source.dart';
import 'package:health_app/features/visits/domain/entities/medical_visit.dart';
import 'package:health_app/features/visits/domain/repositories/medical_visit_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockSecureCredentialsDataSource extends Mock
    implements SecureCredentialsDataSource {}

class MockAppSessionCleanupService extends Mock
    implements AppSessionCleanupService {}

class MockOAuthIdentityProvider extends Mock
    implements OAuthIdentityProvider {}

class MockNotificationScheduler extends Mock implements NotificationScheduler {}

class MockBloodPressureRepository extends Mock
    implements BloodPressureRepository {}

class MockMedicationRepository extends Mock implements MedicationRepository {}

class MockHealthMetricRepository extends Mock
    implements HealthMetricRepository {}

class MockMedicalVisitRepository extends Mock
    implements MedicalVisitRepository {}

class MockProfileRepository extends Mock
    implements ProfileRepository, ProfileStatsRepository {}

class MockBloodPressureLocalDataSource extends Mock
    implements BloodPressureLocalDataSource {}

class MockMedicationLocalDataSource extends Mock
    implements MedicationLocalDataSource {}

class MockHealthMetricsLocalDataSource extends Mock
    implements HealthMetricsLocalDataSource {}

class MockMedicalVisitsLocalDataSource extends Mock
    implements MedicalVisitsLocalDataSource {}

class FakeMedication extends Fake implements Medication {}

class FakeHealthMetricItem extends Fake implements HealthMetricItem {}

class FakeMedicalVisit extends Fake implements MedicalVisit {}

class FakeBloodPressureReading extends Fake implements BloodPressureReading {}

class FakeUserProfile extends Fake implements UserProfile {}

class FakeAuthSession extends Fake implements AuthSession {}

class FakeAuthSessionModel extends Fake implements AuthSessionModel {}

class FakeAuthRegisterResult extends Fake implements AuthRegisterResult {}

class FakeSavedCredentials extends Fake implements SavedCredentials {}

class FakeProviderAuthorizationGrant extends Fake
    implements ProviderAuthorizationGrant {}

class FakeProfileStatsSnapshot extends Fake implements ProfileStatsSnapshot {}

void registerTestFallbackValues() {
  registerFallbackValue(FakeMedication());
  registerFallbackValue(FakeHealthMetricItem());
  registerFallbackValue(FakeMedicalVisit());
  registerFallbackValue(FakeBloodPressureReading());
  registerFallbackValue(FakeUserProfile());
  registerFallbackValue(FakeAuthSession());
  registerFallbackValue(FakeAuthSessionModel());
  registerFallbackValue(FakeAuthRegisterResult());
  registerFallbackValue(FakeSavedCredentials());
  registerFallbackValue(FakeProviderAuthorizationGrant());
  registerFallbackValue(FakeProfileStatsSnapshot());
  registerFallbackValue(DateTime(2026, 5, 26));
  registerFallbackValue(AuthProvider.password);
  registerFallbackValue(MedicationDayStatus.pending);
  registerFallbackValue(<Medication>[]);
  registerFallbackValue(<MedicalVisit>[]);
  registerFallbackValue(<BloodPressureReading>[]);
}
