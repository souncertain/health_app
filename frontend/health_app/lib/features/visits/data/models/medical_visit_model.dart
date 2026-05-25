import '../../domain/entities/medical_visit.dart';

class MedicalVisitModel extends MedicalVisit {
  const MedicalVisitModel({
    required super.id,
    required super.doctorName,
    required super.specialty,
    required super.appointmentDate,
    required super.timeInMinutes,
    required super.location,
    required super.visitType,
    required super.rating,
    required super.createdAt,
    required super.updatedAt,
    super.remoteId,
    super.syncState,
  });

  factory MedicalVisitModel.fromEntity(MedicalVisit visit) {
    return MedicalVisitModel(
      id: visit.id,
      doctorName: visit.doctorName,
      specialty: visit.specialty,
      appointmentDate: visit.appointmentDate,
      timeInMinutes: visit.timeInMinutes,
      location: visit.location,
      visitType: visit.visitType,
      rating: visit.rating,
      createdAt: visit.createdAt,
      updatedAt: visit.updatedAt,
      remoteId: visit.remoteId,
      syncState: visit.syncState,
    );
  }

  factory MedicalVisitModel.fromJson(Map<String, dynamic> json) {
    final parsedAppointmentDate = DateTime.parse(
      json['appointmentDate'] as String,
    );
    return MedicalVisitModel(
      id: json['id'] as String,
      doctorName: json['doctorName'] as String,
      specialty: json['specialty'] as String,
      appointmentDate: MedicalVisit.normalizeDate(
        parsedAppointmentDate.isUtc
            ? parsedAppointmentDate.toLocal()
            : parsedAppointmentDate,
      ),
      timeInMinutes: json['timeInMinutes'] as int,
      location: json['location'] as String,
      visitType: MedicalVisitType.values.firstWhere(
        (value) => value.name == json['visitType'],
      ),
      rating: (json['rating'] as num).toDouble(),
      createdAt: _parseTimestamp(json['createdAt'] as String),
      updatedAt: _parseTimestamp(json['updatedAt'] as String),
      remoteId: json['remoteId'] as String?,
      syncState: MedicalVisitSyncState.values.firstWhere(
        (value) => value.name == json['syncState'],
        orElse: () => MedicalVisitSyncState.localOnly,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorName': doctorName,
      'specialty': specialty,
      'appointmentDate': appointmentDate.toIso8601String(),
      'timeInMinutes': timeInMinutes,
      'location': location,
      'visitType': visitType.name,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'remoteId': remoteId,
      'syncState': syncState.name,
    };
  }
}

DateTime _parseTimestamp(String raw) {
  final parsed = DateTime.parse(raw);
  return parsed.isUtc ? parsed.toLocal() : parsed;
}
