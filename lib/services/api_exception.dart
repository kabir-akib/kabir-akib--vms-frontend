/// Custom exception representing API errors from the Spring Boot backend.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? error;
  final String? path;
  final Map<String, String>? fieldErrors;

  ApiException({
    required this.message,
    this.statusCode,
    this.error,
    this.path,
    this.fieldErrors,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException ($statusCode): $message';
    }
    return 'ApiException: $message';
  }

  /// Extracts user-friendly error message, taking into account field errors if present.
  String get userMessage {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return fieldErrors!.values.join('\n');
    }
    if (message.trim().isNotEmpty) {
      return message;
    }
    switch (statusCode) {
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested vehicle record was not found.';
      case 409:
        return 'A vehicle with this Vehicle Number already exists.';
      default:
        return 'Request failed. Please try again.';
    }
  }
}

