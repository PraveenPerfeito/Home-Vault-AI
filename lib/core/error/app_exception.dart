/// Data-layer exceptions thrown by datasources and mapped to [Failure]
/// types at the repository boundary.
class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, {this.cause});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Network request failed.',
    Object? cause,
  ]) : super(cause: cause);
}

class AuthException extends AppException {
  const AuthException([
    super.message = 'Authentication error.',
    Object? cause,
  ]) : super(cause: cause);
}

class StorageException extends AppException {
  const StorageException([
    super.message = 'Storage error.',
    Object? cause,
  ]) : super(cause: cause);
}

class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'Resource not found.',
    Object? cause,
  ]) : super(cause: cause);
}

class PermissionException extends AppException {
  const PermissionException([
    super.message = 'Permission denied.',
    Object? cause,
  ]) : super(cause: cause);
}
