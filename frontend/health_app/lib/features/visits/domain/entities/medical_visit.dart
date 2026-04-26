enum MedicalVisitType { oneTime, recurring }

enum MedicalVisitSyncState { localOnly, pendingUpload, synced }

class MedicalVisit {
  const MedicalVisit({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.appointmentDate,
    required this.timeInMinutes,
    required this.location,
    required this.visitType,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.syncState = MedicalVisitSyncState.localOnly,
  });

  final String id;
  final String doctorName;
  final String specialty;
  final DateTime appointmentDate;
  final int timeInMinutes;
  final String location;
  final MedicalVisitType visitType;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? remoteId;
  final MedicalVisitSyncState syncState;

  DateTime get scheduledAt {
    return DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      timeInMinutes ~/ 60,
      timeInMinutes % 60,
    );
  }

  MedicalVisit copyWith({
    String? id,
    String? doctorName,
    String? specialty,
    DateTime? appointmentDate,
    int? timeInMinutes,
    String? location,
    MedicalVisitType? visitType,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remoteId,
    MedicalVisitSyncState? syncState,
  }) {
    return MedicalVisit(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeInMinutes: timeInMinutes ?? this.timeInMinutes,
      location: location ?? this.location,
      visitType: visitType ?? this.visitType,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: remoteId ?? this.remoteId,
      syncState: syncState ?? this.syncState,
    );
  }

  static DateTime normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
