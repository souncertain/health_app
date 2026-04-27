String formatMinutesAsClock(int totalMinutes) {
  final hour = totalMinutes ~/ 60;
  final minute = totalMinutes % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String formatDotDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String formatShortMonthDate(DateTime date) {
  return '${date.day} ${shortMonthLabel(date.month)}';
}

String formatLongMonthDate(DateTime date) {
  return '${date.day} ${shortMonthLabel(date.month)} ${date.year}';
}

String shortMonthLabel(int month) {
  switch (month) {
    case 1:
      return 'янв.';
    case 2:
      return 'февр.';
    case 3:
      return 'мар.';
    case 4:
      return 'апр.';
    case 5:
      return 'мая';
    case 6:
      return 'июн.';
    case 7:
      return 'июл.';
    case 8:
      return 'авг.';
    case 9:
      return 'сент.';
    case 10:
      return 'окт.';
    case 11:
      return 'нояб.';
    case 12:
      return 'дек.';
  }
  return '';
}

String shortWeekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'ПН';
    case DateTime.tuesday:
      return 'ВТ';
    case DateTime.wednesday:
      return 'СР';
    case DateTime.thursday:
      return 'ЧТ';
    case DateTime.friday:
      return 'ПТ';
    case DateTime.saturday:
      return 'СБ';
    case DateTime.sunday:
      return 'ВС';
  }
  return '';
}

String fullWeekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Понедельник';
    case DateTime.tuesday:
      return 'Вторник';
    case DateTime.wednesday:
      return 'Среда';
    case DateTime.thursday:
      return 'Четверг';
    case DateTime.friday:
      return 'Пятница';
    case DateTime.saturday:
      return 'Суббота';
    case DateTime.sunday:
      return 'Воскресенье';
  }
  return '';
}
