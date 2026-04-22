class MedicalVisit {
  const MedicalVisit({
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.location,
    required this.rating,
    required this.accentColorHex,
  });

  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String location;
  final double rating;
  final int accentColorHex;
}
