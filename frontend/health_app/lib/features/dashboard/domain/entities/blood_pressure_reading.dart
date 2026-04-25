enum BloodPressureCategory {
  normal,
  elevated,
  highStage1,
  highStage2,
  hypertensiveCrisis,
}

enum BloodPressureSyncState { localOnly, pendingUpload, synced }

class BloodPressureReading {
  const BloodPressureReading({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.syncState = BloodPressureSyncState.localOnly,
  });

  final String id;
  final int systolic;
  final int diastolic;
  final int pulse;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? remoteId;
  final BloodPressureSyncState syncState;

  BloodPressureReading copyWith({
    String? id,
    int? systolic,
    int? diastolic,
    int? pulse,
    DateTime? recordedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remoteId,
    BloodPressureSyncState? syncState,
  }) {
    return BloodPressureReading(
      id: id ?? this.id,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: remoteId ?? this.remoteId,
      syncState: syncState ?? this.syncState,
    );
  }

  BloodPressureCategory get category {
    if (systolic >= 180 || diastolic >= 120) {
      return BloodPressureCategory.hypertensiveCrisis;
    }
    if (systolic >= 140 || diastolic >= 90) {
      return BloodPressureCategory.highStage2;
    }
    if (systolic >= 130 || diastolic >= 80) {
      return BloodPressureCategory.highStage1;
    }
    if (systolic >= 120 && diastolic < 80) {
      return BloodPressureCategory.elevated;
    }
    return BloodPressureCategory.normal;
  }

  String get pressureLabel => '$systolic/$diastolic';
}
