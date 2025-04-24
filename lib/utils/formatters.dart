import 'package:intl/intl.dart';

class Formatters {
  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat.jm().format(date);
  }

  static String formatDateOnly(DateTime date) {
    return DateFormat.yMMMMd().format(date);
  }
}
