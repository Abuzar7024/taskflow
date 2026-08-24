import 'package:intl/intl.dart';

final _dayMonth = DateFormat('d MMM');
final _dayMonthYear = DateFormat('d MMM yyyy');
final _fullDateTime = DateFormat('d MMM yyyy, HH:mm');

abstract final class Dates {
  /// Date only, dropping the year when it matches [now] to keep lists compact.
  static String short(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    return date.year == reference.year
        ? _dayMonth.format(date)
        : _dayMonthYear.format(date);
  }

  static String full(DateTime date) => _dayMonthYear.format(date);

  static String dateTime(DateTime date) => _fullDateTime.format(date);

  /// Relative description used for due dates, e.g. "Today", "In 3 days".
  static String relativeDay(DateTime date, DateTime now) {
    final days = _dayDifference(date, now);
    return switch (days) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      < 0 => '${-days} days overdue',
      < 7 => 'In $days days',
      _ => short(date, now: now),
    };
  }

  /// Compact "time ago" used in comment and notification lists.
  static String timeAgo(DateTime date, DateTime now) {
    final diff = now.difference(date);
    if (diff.isNegative) return 'Just now';
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 7).floor()}w ago';
    return short(date, now: now);
  }

  static int _dayDifference(DateTime date, DateTime now) {
    final a = DateTime(date.year, date.month, date.day);
    final b = DateTime(now.year, now.month, now.day);
    return a.difference(b).inDays;
  }

  /// `yyyy-MM-dd`, matching the mock data's `due_date` format.
  static String toWireDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

abstract final class Plurals {
  static String count(int n, String singular, [String? plural]) {
    return n == 1 ? '$n $singular' : '$n ${plural ?? '${singular}s'}';
  }

  /// "No tasks" reads better than "0 tasks" in list subtitles.
  static String countLabel(int n) =>
      n == 0 ? 'No tasks' : count(n, 'task');
}
