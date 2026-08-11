import 'package:sentinela/core/app_constants.dart';

class Registry {
  const Registry({
    required this.id,
    required this.type,
    required this.licensePlate,
    required this.driver,
    required this.documentNumber,
    required this.unitId,
    required this.notes,
    required this.authorId,
    required this.createdAt,
    this.authorName,
    this.authorRegistry,
  });

  final String id;
  final String type;
  final String licensePlate;
  final String driver;
  final String documentNumber;
  final String unitId;
  final String notes;
  final String authorId;
  final DateTime createdAt;
  final String? authorName;
  final String? authorRegistry;

  factory Registry.fromMap(String id, Map<String, dynamic> data) => Registry(
        id: id,
        type: data[AppFields.type] ?? '',
        licensePlate: data[AppFields.licensePlate] ?? '',
        driver: data[AppFields.driver] ?? '',
        documentNumber: data[AppFields.documentNumber] ?? '',
        unitId: data[AppFields.unitId] ?? '',
        notes: data[AppFields.notes] ?? '',
        authorId: data[AppFields.authorId] ?? '',
        createdAt:
            (data[AppFields.createdAt] as DateTime?) ?? DateTime.fromMillisecondsSinceEpoch(0),
        authorName: data[AppFields.name],
        authorRegistry: data[AppFields.registry],
      );

  Map<String, dynamic> toMap() => {
        AppFields.type: type,
        AppFields.licensePlate: licensePlate,
        AppFields.driver: driver,
        AppFields.documentNumber: documentNumber,
        AppFields.unitId: unitId,
        AppFields.notes: notes,
        AppFields.authorId: authorId,
        AppFields.createdAt: createdAt,
      };

  Registry copyWith({String? authorName, String? authorRegistry}) => Registry(
        id: id,
        type: type,
        licensePlate: licensePlate,
        driver: driver,
        documentNumber: documentNumber,
        unitId: unitId,
        notes: notes,
        authorId: authorId,
        createdAt: createdAt,
        authorName: authorName ?? this.authorName,
        authorRegistry: authorRegistry ?? this.authorRegistry,
      );
}
