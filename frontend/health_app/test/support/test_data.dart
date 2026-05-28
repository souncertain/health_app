import 'package:health_app/features/auth/data/models/auth_session_model.dart';
import 'package:health_app/features/auth/domain/entities/auth_session.dart';
import 'package:health_app/features/auth/domain/entities/auth_register_result.dart';
import 'package:health_app/features/dashboard/domain/entities/blood_pressure_reading.dart';
import 'package:health_app/features/meds/domain/entities/medication.dart';
import 'package:health_app/features/metrics/domain/entities/health_metric_item.dart';
import 'package:health_app/features/profile/domain/entities/profile_stats_snapshot.dart';
import 'package:health_app/features/profile/domain/entities/user_profile.dart';
import 'package:health_app/features/visits/domain/entities/medical_visit.dart';

DateTime sampleDateTime({
  int year = 2026,
  int month = 5,
  int day = 26,
  int hour = 12,
  int minute = 0,
}) {
  return DateTime(year, month, day, hour, minute);
}

BloodPressureReading sampleBloodPressureReading({
  String id = 'bp-1',
  int systolic = 120,
  int diastolic = 79,
  int pulse = 70,
  DateTime? recordedAt,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? remoteId,
  BloodPressureSyncState syncState = BloodPressureSyncState.synced,
}) {
  final timestamp = sampleDateTime();
  return BloodPressureReading(
    id: id,
    systolic: systolic,
    diastolic: diastolic,
    pulse: pulse,
    recordedAt: recordedAt ?? timestamp,
    createdAt: createdAt ?? timestamp,
    updatedAt: updatedAt ?? timestamp,
    remoteId: remoteId,
    syncState: syncState,
  );
}

Medication sampleMedication({
  String id = 'med-1',
  String name = 'Medication',
  String dosage = '10 mg',
  MedicationFrequency frequency = MedicationFrequency.onceDaily,
  List<int>? timesInMinutes,
  bool notificationsEnabled = true,
  MedicationForm form = MedicationForm.tablet,
  List<int>? scheduledWeekdays,
  Map<String, MedicationDayStatus>? dayStatuses,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? remoteId,
  MedicationSyncState syncState = MedicationSyncState.synced,
}) {
  final timestamp = sampleDateTime();
  return Medication(
    id: id,
    name: name,
    dosage: dosage,
    frequency: frequency,
    timesInMinutes: timesInMinutes ?? const [480],
    notificationsEnabled: notificationsEnabled,
    form: form,
    scheduledWeekdays:
        scheduledWeekdays ?? List<int>.generate(7, (index) => index + 1),
    dayStatuses: dayStatuses ?? const {},
    createdAt: createdAt ?? timestamp,
    updatedAt: updatedAt ?? timestamp,
    remoteId: remoteId,
    syncState: syncState,
  );
}

MetricRecord sampleMetricRecord({
  String id = 'record-1',
  double value = 5,
  DateTime? recordedOn,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final timestamp = sampleDateTime();
  return MetricRecord(
    id: id,
    value: value,
    recordedOn: recordedOn ?? timestamp,
    createdAt: createdAt ?? timestamp,
    updatedAt: updatedAt ?? timestamp,
  );
}

HealthMetricItem sampleHealthMetric({
  String id = 'metric-1',
  String title = 'Metric',
  String unit = 'mg/L',
  double targetMin = 4,
  double targetMax = 6,
  MetricVisualStyle visualStyle = MetricVisualStyle.amberDrop,
  List<MetricRecord>? records,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isCustom = false,
  String? remoteId,
  MetricSyncState syncState = MetricSyncState.synced,
}) {
  final timestamp = sampleDateTime();
  return HealthMetricItem(
    id: id,
    title: title,
    unit: unit,
    targetMin: targetMin,
    targetMax: targetMax,
    visualStyle: visualStyle,
    records: records ?? const [],
    createdAt: createdAt ?? timestamp,
    updatedAt: updatedAt ?? timestamp,
    isCustom: isCustom,
    remoteId: remoteId,
    syncState: syncState,
  );
}

MedicalVisit sampleMedicalVisit({
  String id = 'visit-1',
  String doctorName = 'Doctor',
  String specialty = 'Cardiology',
  DateTime? appointmentDate,
  int timeInMinutes = 540,
  String location = 'Clinic',
  MedicalVisitType visitType = MedicalVisitType.oneTime,
  double rating = 4.9,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? remoteId,
  MedicalVisitSyncState syncState = MedicalVisitSyncState.synced,
}) {
  final timestamp = sampleDateTime();
  return MedicalVisit(
    id: id,
    doctorName: doctorName,
    specialty: specialty,
    appointmentDate: appointmentDate ?? DateTime(timestamp.year, timestamp.month, timestamp.day),
    timeInMinutes: timeInMinutes,
    location: location,
    visitType: visitType,
    rating: rating,
    createdAt: createdAt ?? timestamp,
    updatedAt: updatedAt ?? timestamp,
    remoteId: remoteId,
    syncState: syncState,
  );
}

UserProfile sampleUserProfile({
  String id = 'profile-1',
  String fullName = 'Ivan Ivanov',
  String email = 'ivan@example.com',
  String phone = '+79991234567',
  ProfileGender gender = ProfileGender.male,
  DateTime? birthDate,
  int? age = 30,
  String? bloodType = 'A+',
  int? heightCm = 180,
  double? weightKg = 75,
  String? primaryDoctor = 'Dr. House',
  String? emergencyContactName = 'Anna',
  String? emergencyContactDetails = '+79999999999',
  bool notificationsEnabled = true,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? remoteId,
  ProfileSyncState syncState = ProfileSyncState.synced,
}) {
  final timestamp = sampleDateTime();
  return UserProfile(
    id: id,
    fullName: fullName,
    email: email,
    phone: phone,
    gender: gender,
    birthDate: birthDate,
    age: age,
    bloodType: bloodType,
    heightCm: heightCm,
    weightKg: weightKg,
    primaryDoctor: primaryDoctor,
    emergencyContactName: emergencyContactName,
    emergencyContactDetails: emergencyContactDetails,
    notificationsEnabled: notificationsEnabled,
    createdAt: createdAt ?? timestamp,
    updatedAt: updatedAt ?? timestamp,
    remoteId: remoteId,
    syncState: syncState,
  );
}

ProfileStatsSnapshot sampleProfileStatsSnapshot({
  int bloodPressureReadingsCount = 3,
  int medicationsCount = 2,
  int appointmentsCount = 1,
  int daysTracked = 10,
}) {
  return ProfileStatsSnapshot(
    bloodPressureReadingsCount: bloodPressureReadingsCount,
    medicationsCount: medicationsCount,
    appointmentsCount: appointmentsCount,
    daysTracked: daysTracked,
  );
}

AuthSession sampleAuthSession({
  String userId = 'user-1',
  String displayName = 'Ivan',
  String email = 'ivan@example.com',
  AuthProvider provider = AuthProvider.password,
  String accessToken = 'access-token',
  String refreshToken = 'refresh-token',
  DateTime? issuedAt,
  DateTime? accessTokenExpiresAt,
  String? refreshSessionId = 'session-1',
}) {
  final timestamp = sampleDateTime();
  return AuthSession(
    userId: userId,
    displayName: displayName,
    email: email,
    provider: provider,
    accessToken: accessToken,
    refreshToken: refreshToken,
    issuedAt: issuedAt ?? timestamp,
    accessTokenExpiresAt:
        accessTokenExpiresAt ?? timestamp.add(const Duration(hours: 1)),
    refreshSessionId: refreshSessionId,
  );
}

AuthSessionModel sampleAuthSessionModel({
  String userId = 'user-1',
  String displayName = 'Ivan',
  String email = 'ivan@example.com',
  AuthProvider provider = AuthProvider.password,
  String accessToken = 'access-token',
  String refreshToken = 'refresh-token',
  DateTime? issuedAt,
  DateTime? accessTokenExpiresAt,
  String? refreshSessionId = 'session-1',
}) {
  final session = sampleAuthSession(
    userId: userId,
    displayName: displayName,
    email: email,
    provider: provider,
    accessToken: accessToken,
    refreshToken: refreshToken,
    issuedAt: issuedAt,
    accessTokenExpiresAt: accessTokenExpiresAt,
    refreshSessionId: refreshSessionId,
  );

  return AuthSessionModel.fromEntity(session);
}

AuthRegisterResult sampleAuthRegisterResult({
  String email = 'ivan@example.com',
  bool emailConfirmationRequired = true,
}) {
  return AuthRegisterResult(
    email: email,
    emailConfirmationRequired: emailConfirmationRequired,
  );
}
