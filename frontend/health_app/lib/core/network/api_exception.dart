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

class ApiNetworkException extends ApiException {
  const ApiNetworkException([super.message = 'Network request failed.']);
}

class ApiUnauthorizedException extends ApiException {
  const ApiUnauthorizedException([super.message = 'Authorization is required.'])
    : super(statusCode: 401);
}
