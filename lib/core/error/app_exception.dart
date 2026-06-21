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
  const NetworkException(String message, {Object? cause})
      : super(message, cause: cause);
}

class AuthException extends AppException {
  const AuthException(String message, {Object? cause})
      : super(message, cause: cause);
}

class StorageException extends AppException {
  const StorageException(String message, {Object? cause})
      : super(message, cause: cause);
}

class NotFoundException extends AppException {
  const NotFoundException(String message, {Object? cause})
      : super(message, cause: cause);
}

class PermissionException extends AppException {
  const PermissionException(String message, {Object? cause})
      : super(message, cause: cause);
}
