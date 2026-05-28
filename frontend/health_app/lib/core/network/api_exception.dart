class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }

    return '$message (HTTP $statusCode)';
  }
}

class ApiValidationException extends ApiException {
  const ApiValidationException(
    super.message, {
    required this.uiMessage,
    this.fieldErrors = const {},
    super.statusCode,
  });

  final String uiMessage;
  final Map<String, List<String>> fieldErrors;
}

class ApiNetworkException extends ApiException {
  const ApiNetworkException([super.message = 'Network request failed.']);
}

class ApiUnauthorizedException extends ApiException {
  const ApiUnauthorizedException([super.message = 'Authorization is required.'])
    : super(statusCode: 401);
}
