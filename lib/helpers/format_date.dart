import 'package:intl/intl.dart';

formatDate(date) {
  if (date.toString().isNotEmpty) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy hh:ss');
    final itemDate = DateTime.parse(date);
    final formattedDate = formatter.format(itemDate);

    return formattedDate;
  }
  return '';
}
