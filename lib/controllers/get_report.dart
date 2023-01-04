import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sentinela/controllers/get_user_profile_by_id.dart';

Future<List> getReport(DateTime date, String unitId) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  DateTime dateFilterCeil = date.add(
    const Duration(days: 1),
  );

  List report = [];

  QuerySnapshot query = await db
      .collection('units')
      .doc(unitId)
      .collection('registries')
      .where('created_at', isGreaterThan: date, isLessThan: dateFilterCeil)
      .where('unit_id', isEqualTo: unitId)
      .orderBy('created_at', descending: true)
      .get();

  for (var reportItem in query.docs) {
    final user = await getUserProfileById(reportItem.get('author_id'));
    final registry = reportItem.data();

    (registry as Map)['user'] = user.data();

    report.add(registry);
  }

  return report;
}
