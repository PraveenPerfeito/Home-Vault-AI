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
  const NetworkException(super.message, {super.cause});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.cause});
}
