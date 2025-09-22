import 'package:intl/intl.dart';

formatDate(date) {
  if (date.toString().isNotEmpty) {
    // Formato corrigido: hh para horas, mm para minutos e ss para segundos
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    final itemDate = DateTime.parse(date);
    final formattedDate = formatter.format(itemDate);
    return formattedDate;
  } 
  return '';
}