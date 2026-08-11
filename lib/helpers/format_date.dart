import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
  return formatter.format(date);
}
