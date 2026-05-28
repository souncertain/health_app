import 'package:flutter_test/flutter_test.dart';

import 'package:health_app/features/visits/domain/entities/medical_visit.dart';

import '../../../../support/test_data.dart';

void main() {
  test('scheduledAt combines appointment date and minutes of day', () {
    final visit = sampleMedicalVisit(
      appointmentDate: DateTime(2026, 5, 26),
      timeInMinutes: 9 * 60 + 45,
    );

    expect(visit.scheduledAt, DateTime(2026, 5, 26, 9, 45));
  });

  test('normalizeDate strips time component', () {
    expect(
      MedicalVisit.normalizeDate(DateTime(2026, 5, 26, 14, 20)),
      DateTime(2026, 5, 26),
    );
  });

  test('copyWith updates selected values', () {
    final visit = sampleMedicalVisit(timeInMinutes: 540);

    final updated = visit.copyWith(timeInMinutes: 600, location: 'New clinic');

    expect(updated.timeInMinutes, 600);
    expect(updated.location, 'New clinic');
    expect(updated.doctorName, visit.doctorName);
  });
}
