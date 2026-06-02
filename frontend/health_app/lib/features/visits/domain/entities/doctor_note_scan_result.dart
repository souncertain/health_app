enum DoctorNoteCategory { unknown, medication, medicalVisit, mixed }

class DoctorNoteMedicationCandidate {
  const DoctorNoteMedicationCandidate({
    required this.name,
    required this.dosageText,
    required this.frequencyText,
    required this.instructions,
    required this.note,
  });

  final String name;
  final String dosageText;
  final String frequencyText;
  final String instructions;
  final String note;
}

class DoctorNoteVisitCandidate {
  const DoctorNoteVisitCandidate({
    required this.doctorName,
    required this.specialty,
    required this.dateText,
    required this.timeText,
    required this.location,
    required this.note,
  });

  final String doctorName;
  final String specialty;
  final String dateText;
  final String timeText;
  final String location;
  final String note;
}

class DoctorNoteScanResult {
  const DoctorNoteScanResult({
    required this.category,
    required this.rawText,
    required this.summary,
    required this.warnings,
    required this.medications,
    required this.visits,
  });

  final DoctorNoteCategory category;
  final String rawText;
  final String summary;
  final List<String> warnings;
  final List<DoctorNoteMedicationCandidate> medications;
  final List<DoctorNoteVisitCandidate> visits;

  bool get hasStructuredData => medications.isNotEmpty || visits.isNotEmpty;
}
