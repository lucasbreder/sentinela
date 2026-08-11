/// Erros de domínio tipados da aplicação.
sealed class AppError implements Exception {
  const AppError(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthError extends AppError {
  const AuthError(super.message);
}

class NotFoundError extends AppError {
  const NotFoundError(super.message);
}

class ValidationError extends AppError {
  const ValidationError(super.message);
}

class StorageError extends AppError {
  const StorageError(super.message);
}

class ForbiddenError extends AppError {
  const ForbiddenError(super.message);
}

class OperationError extends AppError {
  const OperationError(super.message);
}
