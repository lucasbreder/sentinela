/// Constantes globais de coleções, campos e domínio.
abstract final class AppCollections {
  static const units = 'units';
  static const registries = 'registries';
  static const permissions = 'permissions';
  static const profiles = 'profiles';
}

abstract final class AppFields {
  static const userId = 'user_id';
  static const unitId = 'unit_id';
  static const unitName = 'unit_name';
  static const role = 'role';
  static const expiresAt = 'expires_at';
  static const createdAt = 'created_at';
  static const type = 'type';
  static const licensePlate = 'license_plate';
  static const driver = 'driver';
  static const documentNumber = 'document_number';
  static const notes = 'notes';
  static const authorId = 'author_id';
  static const name = 'name';
  static const email = 'email';
  static const registry = 'registry';
  static const ownerId = 'owner_id';
}

abstract final class UserRole {
  static const owner = 'owner';
  static const guest = 'guest';
}

abstract final class MovementType {
  static const entrada = 'Entrada';
  static const saida = 'Saída';
}
