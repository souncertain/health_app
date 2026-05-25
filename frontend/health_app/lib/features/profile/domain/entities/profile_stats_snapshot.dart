class ProfileStatsSnapshot {
  const ProfileStatsSnapshot({
    required this.bloodPressureReadingsCount,
    required this.medicationsCount,
    required this.appointmentsCount,
    required this.daysTracked,
  });

  final int bloodPressureReadingsCount;
  final int medicationsCount;
  final int appointmentsCount;
  final int daysTracked;
}
