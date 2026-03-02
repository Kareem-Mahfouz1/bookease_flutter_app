import 'package:equatable/equatable.dart';
import 'package:appointment_booking/core/exceptions/app_exceptions.dart';

/// Represents the result of an operation that can either succeed or fail
sealed class Result<T> extends Equatable {
  const Result();

  /// Returns true if the result is a success
  bool get isSuccess => this is Success<T>;

  /// Returns true if the result is a failure
  bool get isFailure => this is Failure<T>;

  /// Returns the data if successful, null otherwise
  T? get dataOrNull => switch (this) {
    Success(data: final data) => data,
    Failure() => null,
  };

  /// Returns the exception if failed, null otherwise
  AppException? get exceptionOrNull => switch (this) {
    Success() => null,
    Failure(exception: final exception) => exception,
  };

  /// Executes the appropriate callback based on the result
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  }) {
    return switch (this) {
      Success(data: final data) => success(data),
      Failure(exception: final exception) => failure(exception),
    };
  }
}

/// Represents a successful result with data
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  List<Object?> get props => [data];
}

/// Represents a failed result with an exception
final class Failure<T> extends Result<T> {
  final AppException exception;

  const Failure(this.exception);

  @override
  List<Object?> get props => [exception];
}
