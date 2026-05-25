import '../../domain/entities/medication.dart';

class MedicationModel extends Medication {
  const MedicationModel({
    required super.id,
    required super.name,
    required super.dosage,
    required super.frequency,
    required super.timesInMinutes,
    required super.notificationsEnabled,
    required super.form,
    required super.scheduledWeekdays,
    required super.dayStatuses,
    required super.createdAt,
    required super.updatedAt,
    super.remoteId,
    super.syncState,
  });

  factory MedicationModel.fromEntity(Medication medication) {
    return MedicationModel(
      id: medication.id,
      name: medication.name,
      dosage: medication.dosage,
      frequency: medication.frequency,
      timesInMinutes: medication.timesInMinutes,
      notificationsEnabled: medication.notificationsEnabled,
      form: medication.form,
      scheduledWeekdays: medication.scheduledWeekdays,
      dayStatuses: medication.dayStatuses,
      createdAt: medication.createdAt,
      updatedAt: medication.updatedAt,
      remoteId: medication.remoteId,
      syncState: medication.syncState,
    );
  }

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    final rawStatuses =
        json['dayStatuses'] as Map<String, dynamic>? ?? const {};
    return MedicationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      frequency: MedicationFrequency.values.firstWhere(
        (value) => value.name == json['frequency'],
      ),
      timesInMinutes: (json['timesInMinutes'] as List<dynamic>)
          .map((item) => item as int)
          .toList(),
      notificationsEnabled: json['notificationsEnabled'] as bool,
      form: MedicationForm.values.firstWhere(
        (value) => value.name == json['form'],
      ),
      scheduledWeekdays: (json['scheduledWeekdays'] as List<dynamic>)
          .map((item) => item as int)
          .toList(),
      dayStatuses: rawStatuses.map(
        (key, value) => MapEntry(
          key,
          MedicationDayStatus.values.firstWhere(
            (status) => status.name == value,
          ),
        ),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      remoteId: json['remoteId'] as String?,
      syncState: MedicationSyncState.values.firstWhere(
        (value) => value.name == json['syncState'],
        orElse: () => MedicationSyncState.localOnly,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency.name,
      'timesInMinutes': timesInMinutes,
      'notificationsEnabled': notificationsEnabled,
      'form': form.name,
      'scheduledWeekdays': scheduledWeekdays,
      'dayStatuses': dayStatuses.map(
        (key, value) => MapEntry(key, value.name),
      ),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'remoteId': remoteId,
      'syncState': syncState.name,
    };
  }
}
