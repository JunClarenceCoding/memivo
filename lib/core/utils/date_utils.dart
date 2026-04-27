import 'package:intl/intl.dart';

class AppDateUtils {

  // Days until next birthday
  static int daysUntilBirthday(String birthdate) {
    final today = DateTime.now();
    final bday = DateTime.parse(birthdate);
    var next = DateTime(today.year, bday.month, bday.day);
    if (next.isBefore(DateTime(today.year, today.month, today.day))) {
      next = DateTime(today.year + 1, bday.month, bday.day);
    }
    return next
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  // Format date to readable string
  static String formatDate(String date, {String pattern = 'MMMM dd, yyyy'}) {
    return DateFormat(pattern).format(DateTime.parse(date));
  }

  // Days label
  static String daysLabel(int days) {
    if (days == 0) return 'Today!';
    if (days == 1) return 'Tomorrow';
    return '$days days';
  }
}