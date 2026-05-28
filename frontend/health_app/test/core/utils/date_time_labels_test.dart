import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/core/utils/date_time_labels.dart';
import 'package:health_app/features/dashboard/presentation/utils/dashboard_date_formatter.dart'
    as dashboard;

void main() {
  test('formatMinutesAsClock zero pads hours and minutes', () {
    expect(formatMinutesAsClock(5), '00:05');
    expect(formatMinutesAsClock(605), '10:05');
  });

  test('formatDotDate returns dd.MM.yyyy', () {
    expect(formatDotDate(DateTime(2026, 5, 26)), '26.05.2026');
  });

  test('formatShortMonthDate and formatLongMonthDate include date parts', () {
    final date = DateTime(2026, 5, 26);

    expect(formatShortMonthDate(date), startsWith('26 '));
    expect(formatLongMonthDate(date), contains('2026'));
  });

  test('weekday label helpers return non-empty values for valid weekdays', () {
    expect(shortWeekdayLabel(DateTime.monday), isNotEmpty);
    expect(fullWeekdayLabel(DateTime.sunday), isNotEmpty);
  });

  test('month label helpers return empty string for invalid month', () {
    expect(shortMonthLabel(0), isEmpty);
  });

  test('dashboard formatters return expected time and date layout', () {
    final date = DateTime(2026, 5, 26, 9, 7);

    expect(dashboard.formatTimeOfDay(date), '09:07');
    expect(dashboard.formatMonthDay(date), startsWith('26 '));
    expect(dashboard.formatMonthDayYear(date), contains('2026'));
    expect(dashboard.formatMonthDayTime(date), contains(' - 09:07'));
  });
}
