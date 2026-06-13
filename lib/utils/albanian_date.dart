import 'dart:math' as math;

const _albanianMonths = <String>[
  'Janar',
  'Shkurt',
  'Mars',
  'Prill',
  'Maj',
  'Qershor',
  'Korrik',
  'Gusht',
  'Shtator',
  'Tetor',
  'Nëntor',
  'Dhjetor',
];

DateTime oneMonthFrom(DateTime date) {
  final targetYear = date.month == 12 ? date.year + 1 : date.year;
  final targetMonth = date.month == 12 ? 1 : date.month + 1;
  final lastTargetDay = DateTime(targetYear, targetMonth + 1, 0).day;

  return DateTime(targetYear, targetMonth, math.min(date.day, lastTargetDay));
}

String formatAlbanianDate(DateTime date) {
  return '${date.day} ${_albanianMonths[date.month - 1]} ${date.year}';
}
