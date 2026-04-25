const _monthShortNames = <int, String>{
  1: 'Jan',
  2: 'Feb',
  3: 'Mar',
  4: 'Apr',
  5: 'May',
  6: 'Jun',
  7: 'Jul',
  8: 'Aug',
  9: 'Sep',
  10: 'Oct',
  11: 'Nov',
  12: 'Dec',
};

String formatMonthDay(DateTime value) {
  return '${_monthShortNames[value.month]} ${value.day}';
}

String formatMonthDayYear(DateTime value) {
  return '${_monthShortNames[value.month]} ${value.day}, ${value.year}';
}

String formatTimeOfDay(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute $suffix';
}

String formatMonthDayTime(DateTime value) {
  return '${formatMonthDay(value)} - ${formatTimeOfDay(value)}';
}
