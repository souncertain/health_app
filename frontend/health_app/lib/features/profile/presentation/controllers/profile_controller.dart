import 'package:flutter/foundation.dart';

import '../../../../core/services/local_notifications_service.dart';
import '../../../dashboard/data/datasources/blood_pressure_local_data_source.dart';
import '../../../dashboard/domain/entities/blood_pressure_reading.dart';
import '../../../meds/data/datasources/medication_local_data_source.dart';
import '../../../metrics/data/datasources/health_metrics_local_data_source.dart';
import '../../../visits/data/datasources/medical_visits_local_data_source.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileStats {
  const ProfileStats({
    required this.bpReadingsCount,
    required this.medicationsCount,
    required this.appointmentsCount,
    required this.daysTracked,
  });

  const ProfileStats.empty()
    : bpReadingsCount = 0,
      medicationsCount = 0,
      appointmentsCount = 0,
      daysTracked = 0;

  final int bpReadingsCount;
  final int medicationsCount;
  final int appointmentsCount;
  final int daysTracked;
}

class ProfileController extends ChangeNotifier {
  ProfileController({
    required ProfileRepository repository,
    required NotificationScheduler notifications,
    BloodPressureLocalDataSource? bloodPressureLocalDataSource,
    MedicationLocalDataSource? medicationLocalDataSource,
    HealthMetricsLocalDataSource? healthMetricsLocalDataSource,
    MedicalVisitsLocalDataSource? medicalVisitsLocalDataSource,
  }) : _repository = repository,
       _notifications = notifications,
       _bloodPressureLocalDataSource =
           bloodPressureLocalDataSource ?? BloodPressureLocalDataSource(),
       _medicationLocalDataSource =
           medicationLocalDataSource ?? MedicationLocalDataSource(),
       _healthMetricsLocalDataSource =
           healthMetricsLocalDataSource ?? HealthMetricsLocalDataSource(),
       _medicalVisitsLocalDataSource =
           medicalVisitsLocalDataSource ?? MedicalVisitsLocalDataSource();

  final ProfileRepository _repository;
  final NotificationScheduler _notifications;
  final BloodPressureLocalDataSource _bloodPressureLocalDataSource;
  final MedicationLocalDataSource _medicationLocalDataSource;
  final HealthMetricsLocalDataSource _healthMetricsLocalDataSource;
  final MedicalVisitsLocalDataSource _medicalVisitsLocalDataSource;

  UserProfile _profile = UserProfile.empty();
  ProfileStats _stats = const ProfileStats.empty();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _initialized = false;

  UserProfile get profile => _profile;
  ProfileStats get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _repository.getProfile() ?? UserProfile.empty();
      _stats = await _buildStats();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    _isSaving = true;
    notifyListeners();

    try {
      await _repository.saveProfile(profile);
      _profile = profile;
      _stats = await _buildStats();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (_isSaving || enabled == _profile.notificationsEnabled) {
      return;
    }

    _isSaving = true;
    notifyListeners();

    try {
      final updatedProfile = _profile.copyWith(
        notificationsEnabled: enabled,
        updatedAt: DateTime.now(),
      );
      await _repository.saveProfile(updatedProfile);
      _profile = updatedProfile;

      if (enabled) {
        final medications = await _medicationLocalDataSource.getMedications();
        final visits = await _medicalVisitsLocalDataSource.getVisits();
        await _notifications.syncMedicationNotifications(medications);
        await _notifications.syncVisitNotifications(visits);
      } else {
        await _notifications.cancelAllNotifications();
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<ProfileStats> _buildStats() async {
    final readings = (await _bloodPressureLocalDataSource.getReadings())
        .where((item) => item.syncState != BloodPressureSyncState.pendingDelete)
        .toList();
    final medications = await _medicationLocalDataSource.getMedications();
    final metrics = await _healthMetricsLocalDataSource.getMetrics();
    final visits = await _medicalVisitsLocalDataSource.getVisits();

    final trackedDates = <DateTime>[
      ...readings.map((item) => _normalizeDate(item.recordedAt)),
      ...medications.map((item) => _normalizeDate(item.createdAt)),
      ...metrics.expand(
        (metric) =>
            metric.records.map((record) => _normalizeDate(record.recordedOn)),
      ),
      ...visits.map((item) => _normalizeDate(item.createdAt)),
    ]..sort();

    final daysTracked = trackedDates.isEmpty
        ? 0
        : _normalizeDate(DateTime.now()).difference(trackedDates.first).inDays +
              1;

    return ProfileStats(
      bpReadingsCount: readings.length,
      medicationsCount: medications.length,
      appointmentsCount: visits.length,
      daysTracked: daysTracked,
    );
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
