import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static const List<String> _monthsId = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String integer(num value) {
    final rounded = value.round();
    final negative = rounded < 0;
    final digits = rounded.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final fromRight = digits.length - i;
      buffer.write(digits[i]);
      if (fromRight > 1 && fromRight % 3 == 1) {
        buffer.write('.');
      }
    }
    return negative ? '-$buffer' : buffer.toString();
  }

  static String decimal(num value, {int digits = 1}) {
    final fixed = value.toStringAsFixed(digits);
    final parts = fixed.split('.');
    final intPart = integer(int.parse(parts[0]));
    if (parts.length == 1) return intPart;
    return '$intPart,${parts[1]}';
  }

  static String timeHm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  static String dateTimeShort(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mon = _monthsId[dt.month - 1];
    return '$d $mon, ${timeHm(dt)}';
  }

  static String dateIso(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  static String dateFull(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mon = _monthsId[dt.month - 1];
    return '$d $mon ${dt.year}';
  }

  static String timestampExcel(DateTime dt) {
    final y = dt.year.toString();
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi';
  }

  static String initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
