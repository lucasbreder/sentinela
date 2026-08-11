import 'package:sentinela/core/app_constants.dart';

class Invite {
  const Invite({
    required this.email,
    required this.unitId,
    required this.unitName,
    this.ownerId,
    this.expiresAt,
  });

  final String email;
  final String unitId;
  final String unitName;
  final String? ownerId;
  final DateTime? expiresAt;

  factory Invite.fromMap(String id, Map<String, dynamic> data) => Invite(
        email: data[AppFields.email] ?? '',
        unitId: data[AppFields.unitId] ?? '',
        unitName: data[AppFields.unitName] ?? '',
        ownerId: data[AppFields.ownerId],
        expiresAt: data[AppFields.expiresAt] as DateTime?,
      );

  Map<String, dynamic> toMap() => {
        AppFields.email: email,
        AppFields.unitId: unitId,
        AppFields.unitName: unitName,
        if (ownerId != null) AppFields.ownerId: ownerId,
        if (expiresAt != null) AppFields.expiresAt: expiresAt,
      };
}
