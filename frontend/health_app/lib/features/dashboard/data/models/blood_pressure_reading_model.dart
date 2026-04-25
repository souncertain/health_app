import '../../domain/entities/blood_pressure_reading.dart';

class BloodPressureReadingModel extends BloodPressureReading {
  const BloodPressureReadingModel({
    required super.id,
    required super.systolic,
    required super.diastolic,
    required super.pulse,
    required super.recordedAt,
    required super.createdAt,
    required super.updatedAt,
    super.remoteId,
    super.syncState,
  });

  factory BloodPressureReadingModel.fromEntity(BloodPressureReading reading) {
    return BloodPressureReadingModel(
      id: reading.id,
      systolic: reading.systolic,
      diastolic: reading.diastolic,
      pulse: reading.pulse,
      recordedAt: reading.recordedAt,
      createdAt: reading.createdAt,
      updatedAt: reading.updatedAt,
      remoteId: reading.remoteId,
      syncState: reading.syncState,
    );
  }

  factory BloodPressureReadingModel.fromJson(Map<String, dynamic> json) {
    return BloodPressureReadingModel(
      id: json['id'] as String,
      systolic: json['systolic'] as int,
      diastolic: json['diastolic'] as int,
      pulse: json['pulse'] as int,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      remoteId: json['remoteId'] as String?,
      syncState: BloodPressureSyncState.values.firstWhere(
        (value) => value.name == json['syncState'],
        orElse: () => BloodPressureSyncState.localOnly,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'recordedAt': recordedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'remoteId': remoteId,
      'syncState': syncState.name,
    };
  }
}
