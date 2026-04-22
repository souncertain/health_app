enum MedicationStatus { taken, pending, missed }

enum MedicationForm { capsule, syringe, tablet, circle }

class MedicationItem {
  const MedicationItem({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.status,
    required this.form,
    required this.notificationsEnabled,
    this.completed = false,
  });

  final String name;
  final String dosage;
  final String frequency;
  final List<String> times;
  final MedicationStatus status;
  final MedicationForm form;
  final bool notificationsEnabled;
  final bool completed;
}
