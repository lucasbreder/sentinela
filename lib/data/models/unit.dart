import 'package:sentinela/core/app_constants.dart';

class Unit {
  const Unit({required this.id, required this.name, this.ownerId});

  final String id;
  final String name;
  final String? ownerId;

  factory Unit.fromMap(String id, Map<String, dynamic> data) => Unit(
        id: id,
        name: data[AppFields.name] ?? '',
        ownerId: data[AppFields.ownerId],
      );

  Map<String, dynamic> toMap() => {AppFields.name: name};
}
