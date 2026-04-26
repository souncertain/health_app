const _monthShortNames = <int, String>{
  1: 'янв.',
  2: 'февр.',
  3: 'мар.',
  4: 'апр.',
  5: 'мая',
  6: 'июн.',
  7: 'июл.',
  8: 'авг.',
  9: 'сент.',
  10: 'окт.',
  11: 'нояб.',
  12: 'дек.',
};

String formatMonthDay(DateTime value) {
  return '${value.day} ${_monthShortNames[value.month]}';
}

String formatMonthDayYear(DateTime value) {
  return '${value.day} ${_monthShortNames[value.month]} ${value.year}';
}

String formatTimeOfDay(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatMonthDayTime(DateTime value) {
  return '${formatMonthDay(value)} - ${formatTimeOfDay(value)}';
}
