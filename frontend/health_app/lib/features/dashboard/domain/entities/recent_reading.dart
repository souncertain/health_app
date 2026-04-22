enum ReadingStatus { normal, elevated }

class RecentReading {
  const RecentReading({
    required this.pressure,
    required this.status,
    required this.date,
    required this.pulse,
  });

  final String pressure;
  final ReadingStatus status;
  final String date;
  final String pulse;
}
