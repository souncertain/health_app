import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/local_notifications_service.dart';
import '../../../dashboard/data/datasources/blood_pressure_local_data_source.dart';
import '../../../dashboard/domain/entities/blood_pressure_reading.dart';
import '../../../meds/data/datasources/medication_local_data_source.dart';
import '../../../metrics/data/datasources/health_metrics_local_data_source.dart';
import '../../../visits/data/datasources/medical_visits_local_data_source.dart';
import '../../domain/entities/profile_stats_snapshot.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/profile_stats_repository.dart';

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

  factory ProfileStats.fromSnapshot(ProfileStatsSnapshot snapshot) {
    return ProfileStats(
      bpReadingsCount: snapshot.bloodPressureReadingsCount,
      medicationsCount: snapshot.medicationsCount,
      appointmentsCount: snapshot.appointmentsCount,
      daysTracked: snapshot.daysTracked,
    );
  }

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
    await _loadCached();
    unawaited(refresh(showLoading: !_hasVisibleProfileData));
  }

  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
    }
    notifyListeners();

    try {
      _profile = await _repository.getProfile() ?? UserProfile.empty();
      if (_repository is ProfileStatsRepository) {
        _stats = ProfileStats.fromSnapshot(
          await (_repository as ProfileStatsRepository).getProfileStats(),
        );
      } else {
        _stats = await _buildStats();
      }
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    _isSaving = true;
    final previousProfile = _profile;
    _profile = profile;
    notifyListeners();

    try {
      await _repository.saveProfile(profile);
      _profile = await _repository.getCachedProfile() ?? profile;
      if (_repository is ProfileStatsRepository) {
        _stats = ProfileStats.fromSnapshot(
          await (_repository as ProfileStatsRepository).getProfileStats(),
        );
      } else {
        _stats = await _buildStats();
      }
    } catch (_) {
      _profile = previousProfile;
      rethrow;
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
    final previousProfile = _profile;
    _profile = _profile.copyWith(
      notificationsEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      final updatedProfile = _profile;
      await _repository.saveProfile(updatedProfile);
      _profile = await _repository.getCachedProfile() ?? updatedProfile;

      if (enabled) {
        final medications = await _medicationLocalDataSource.getMedications();
        final visits = await _medicalVisitsLocalDataSource.getVisits();
        await _notifications.syncMedicationNotifications(medications);
        await _notifications.syncVisitNotifications(visits);
      } else {
        await _notifications.cancelAllNotifications();
      }
    } catch (_) {
      _profile = previousProfile;
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _loadCached() async {
    try {
      _profile = await _repository.getCachedProfile() ?? UserProfile.empty();
      if (_repository is ProfileStatsRepository) {
        _stats = ProfileStats.fromSnapshot(
          await (_repository as ProfileStatsRepository).getProfileStats(),
        );
      } else {
        _stats = await _buildStats();
      }
    } catch (_) {
      // Keep empty state if cache loading fails.
    }

    _isLoading = false;
    notifyListeners();
  }

  bool get _hasVisibleProfileData {
    return _profile.fullName.trim().isNotEmpty ||
        _profile.email.trim().isNotEmpty ||
        (_profile.primaryDoctor?.trim().isNotEmpty ?? false) ||
        (_profile.bloodType?.trim().isNotEmpty ?? false) ||
        (_profile.emergencyContactName?.trim().isNotEmpty ?? false) ||
        (_profile.emergencyContactDetails?.trim().isNotEmpty ?? false) ||
        _profile.heightCm != null ||
        _profile.weightKg != null ||
        _profile.age != null ||
        _profile.remoteId?.trim().isNotEmpty == true;
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
