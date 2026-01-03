import 'package:intl/intl.dart';

class HelperFormat {
  static String tanggal(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  static String jam(DateTime d) => DateFormat('HH:mm').format(d);
}
