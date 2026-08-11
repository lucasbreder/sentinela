import 'package:sentinela/core/app_constants.dart';
import 'package:sentinela/data/models/unit.dart';

class Permission {
  const Permission({
    required this.id,
    required this.userId,
    required this.unitId,
    required this.unitName,
    required this.role,
    this.ownerId,
    this.expiresAt,
  });

  final String id;
  final String userId;
  final String unitId;
  final String unitName;
  final String role;
  final String? ownerId;
  final DateTime? expiresAt;

  bool get isOwner => role == UserRole.owner;
  bool get isGuest => role == UserRole.guest;

  factory Permission.fromMap(String id, Map<String, dynamic> data) => Permission(
        id: id,
        userId: data[AppFields.userId] ?? '',
        unitId: data[AppFields.unitId] ?? '',
        unitName: data[AppFields.unitName] ?? '',
        role: data[AppFields.role] ?? UserRole.guest,
        ownerId: data[AppFields.ownerId],
        expiresAt: data[AppFields.expiresAt] as DateTime?,
      );

  Map<String, dynamic> toMap() => {
        AppFields.userId: userId,
        AppFields.unitId: unitId,
        AppFields.unitName: unitName,
        AppFields.role: role,
        if (ownerId != null) AppFields.ownerId: ownerId,
        if (expiresAt != null) AppFields.expiresAt: expiresAt,
      };

  Unit get asUnit => Unit(id: unitId, name: unitName);
}
