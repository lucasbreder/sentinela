import 'package:cloud_firestore/cloud_firestore.dart';

/// Na web, o cloud_firestore devolve timestamps como `Timestamp` (não
/// `DateTime`, como no Android/iOS). Normaliza os campos informados antes
/// de construir os models.
Map<String, dynamic> normalizeTimestamps(
  Map<String, dynamic> data,
  List<String> fields,
) {
  final out = Map<String, dynamic>.from(data);
  for (final field in fields) {
    final value = out[field];
    if (value is Timestamp) {
      out[field] = value.toDate();
    }
  }
  return out;
}
