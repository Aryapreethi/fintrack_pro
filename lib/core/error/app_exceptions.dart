class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => 'AppException: $message';
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class IntegrityException extends AppException {
  IntegrityException(super.message);
}

class ImportException extends AppException {
  ImportException(super.message);
}
