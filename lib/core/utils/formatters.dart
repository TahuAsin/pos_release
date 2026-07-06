import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  static String format(num value) => _formatter.format(value);

  static String formatCompact(num value) {
    if (value >= 1000000) return _compact.format(value);
    return _formatter.format(value);
  }

  static String formatNumber(num value) {
    return NumberFormat('#,###', 'id_ID').format(value);
  }
}

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm', 'id_ID').format(date);
  }

  static String formatShort(DateTime date) {
    return DateFormat('dd/MM/yy', 'id_ID').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  static String formatDayMonth(DateTime date) {
    return DateFormat('dd MMM', 'id_ID').format(date);
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 0, 0, 0);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1, 0, 0, 0);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }
}
