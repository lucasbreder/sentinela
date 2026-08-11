import 'package:sentinela/core/app_errors.dart';

/// Resultado tipado de uma operação: sucesso com valor ou falha com erro.
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  });
}

class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  }) =>
      success(value);
}

class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppError error;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  }) =>
      failure(error);
}
