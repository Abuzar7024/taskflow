/// Application-level failures.
///
/// Every layer below the UI throws one of these, so widgets can render a
/// human message without ever seeing a raw exception.
sealed class AppException implements Exception {
  const AppException(this.message);

  /// User-facing text. Written for the person using the app, not for a log.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([
    super.message =
        'We could not reach the server. Check your connection and try again.',
  ]);
}

class TimeoutException extends AppException {
  const TimeoutException([
    super.message = 'The request took too long. Please try again.',
  ]);
}

class OfflineException extends AppException {
  const OfflineException([
    super.message = 'You are offline. Connect to the internet to make changes.',
  ]);
}

class ServerException extends AppException {
  const ServerException([
    super.message = 'Something went wrong on our side. Please try again.',
  ]);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'We could not find that item.']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

class InvalidCredentialsException extends AppException {
  const InvalidCredentialsException([
    super.message = 'Incorrect email or password.',
  ]);
}

/// A rule the current user is not allowed to break, e.g. a member attempting
/// an admin-only operation.
class ForbiddenException extends AppException {
  const ForbiddenException([
    super.message = 'You do not have permission to do that.',
  ]);
}

/// Failed input validation. [fieldErrors] lets a form highlight the exact
/// field that was rejected.
class ValidationException extends AppException {
  const ValidationException(super.message, [this.fieldErrors = const {}]);

  final Map<String, String> fieldErrors;
}

/// Maps anything thrown below the UI onto a user-facing message.
String messageFor(Object error) {
  if (error is AppException) return error.message;
  return 'Something went wrong. Please try again.';
}
