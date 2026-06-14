import '../l10n/app_localizations.dart';

/// 人性化的"过去"时间：今天 / 昨天 / N天前 / N个月前 / N年前。
String relativePast(DateTime d, DateTime now, AppLocalizations t) {
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return t.dateToday;
  if (days == 1) return t.dateYesterday;
  if (days < 30) return t.daysAgo(days);
  if (days < 365) return t.monthsAgo(days ~/ 30);
  return t.yearsAgo(days ~/ 365);
}

/// 距离下个生日还有几天（0 = 今天）。
int daysUntilNextBirthday(DateTime birth, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  var next = DateTime(now.year, birth.month, birth.day);
  if (next.isBefore(today)) {
    next = DateTime(now.year + 1, birth.month, birth.day);
  }
  return next.difference(today).inDays;
}

/// 下个生日时将满的周岁。
int nextBirthdayAge(DateTime birth, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final thisYear = DateTime(now.year, birth.month, birth.day);
  final year = thisYear.isBefore(today) ? now.year + 1 : now.year;
  return year - birth.year;
}
