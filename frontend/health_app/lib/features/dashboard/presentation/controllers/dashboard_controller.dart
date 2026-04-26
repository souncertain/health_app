import 'package:flutter/foundation.dart';

import '../../domain/entities/blood_pressure_reading.dart';
import '../../domain/usecases/delete_blood_pressure_reading.dart';
import '../../domain/usecases/get_blood_pressure_readings.dart';
import '../../domain/usecases/save_blood_pressure_reading.dart';

enum DashboardHistoryRange { sevenDays, thirtyDays }

class DashboardController extends ChangeNotifier {
  DashboardController({
    required GetBloodPressureReadingsUseCase getReadings,
    required SaveBloodPressureReadingUseCase saveReading,
    required DeleteBloodPressureReadingUseCase deleteReading,
  }) : _getReadings = getReadings,
       _saveReading = saveReading,
       _deleteReading = deleteReading;

  final GetBloodPressureReadingsUseCase _getReadings;
  final SaveBloodPressureReadingUseCase _saveReading;
  final DeleteBloodPressureReadingUseCase _deleteReading;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<BloodPressureReading> _readings = const [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasReadings => _readings.isNotEmpty;

  List<BloodPressureReading> get allReadings => List.unmodifiable(_readings);

  List<BloodPressureReading> get recentReadings =>
      List.unmodifiable(_readings.take(4));

  BloodPressureReading? get latestReading =>
      _readings.isEmpty ? null : _readings.first;

  int get averageSystolic => _averageOf(_readings.map((item) => item.systolic));

  int get averageDiastolic =>
      _averageOf(_readings.map((item) => item.diastolic));

  int get averagePulse => _averageOf(_readings.map((item) => item.pulse));

  int countByCategory(BloodPressureCategory category) {
    return _readings.where((reading) => reading.category == category).length;
  }

  Future<void> initialize() async {
    if (_isLoading || _readings.isNotEmpty) {
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final readings = await _getReadings();
      _readings = List<BloodPressureReading>.from(readings)
        ..sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    } catch (_) {
      _errorMessage = 'Не удалось загрузить измерения давления.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveReading({
    BloodPressureReading? existingReading,
    required int systolic,
    required int diastolic,
    required int pulse,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final now = DateTime.now();
    final reading =
        existingReading?.copyWith(
          systolic: systolic,
          diastolic: diastolic,
          pulse: pulse,
          updatedAt: now,
          syncState: existingReading.syncState,
        ) ??
        BloodPressureReading(
          id: 'bp-${now.microsecondsSinceEpoch}',
          systolic: systolic,
          diastolic: diastolic,
          pulse: pulse,
          recordedAt: now,
          createdAt: now,
          updatedAt: now,
        );

    try {
      await _saveReading(reading);
      await refresh();
    } catch (_) {
      _errorMessage = 'Не удалось сохранить измерение.';
      _isSaving = false;
      notifyListeners();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteReading(BloodPressureReading reading) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deleteReading(reading.id);
      await refresh();
    } catch (_) {
      _errorMessage = 'Не удалось удалить измерение.';
      _isSaving = false;
      notifyListeners();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  List<BloodPressureReading> readingsForRange(DashboardHistoryRange range) {
    final now = DateTime.now();
    final threshold = range == DashboardHistoryRange.sevenDays
        ? now.subtract(const Duration(days: 7))
        : now.subtract(const Duration(days: 30));

    final filtered =
        _readings
            .where((reading) => reading.recordedAt.isAfter(threshold))
            .toList()
          ..sort((left, right) => left.recordedAt.compareTo(right.recordedAt));

    if (filtered.isNotEmpty) {
      return filtered;
    }

    return List<BloodPressureReading>.from(_readings.reversed);
  }

  int _averageOf(Iterable<int> values) {
    if (values.isEmpty) {
      return 0;
    }

    final list = values.toList();
    final total = list.fold<int>(0, (sum, value) => sum + value);
    return (total / list.length).round();
  }
}
