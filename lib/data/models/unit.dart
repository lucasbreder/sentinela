import 'package:sentinela/core/app_constants.dart';

class Unit {
  const Unit({
    required this.id,
    required this.name,
    this.ownerId,
    this.archived = false,
  });

  final String id;
  final String name;
  final String? ownerId;
  final bool archived;

  factory Unit.fromMap(String id, Map<String, dynamic> data) => Unit(
        id: id,
        name: data[AppFields.name] ?? '',
        ownerId: data[AppFields.ownerId],
        archived: data[AppFields.archived] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {AppFields.name: name};

  Unit copyWith({String? name, String? ownerId, bool? archived}) => Unit(
        id: id,
        name: name ?? this.name,
        ownerId: ownerId ?? this.ownerId,
        archived: archived ?? this.archived,
      );
}
