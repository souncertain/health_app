import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/core/network/api_exception.dart';

void main() {
  test('ApiException toString returns message without status code', () {
    const exception = ApiException('Failure');

    expect(exception.toString(), 'Failure');
  });

  test('ApiException toString includes status code when present', () {
    const exception = ApiException('Failure', statusCode: 400);

    expect(exception.toString(), 'Failure (HTTP 400)');
  });

  test('ApiValidationException exposes uiMessage and field errors', () {
    const exception = ApiValidationException(
      'Validation failed',
      uiMessage: 'Show this to the user',
      fieldErrors: {
        'email': ['Invalid email'],
      },
      statusCode: 422,
    );

    expect(exception.uiMessage, 'Show this to the user');
    expect(exception.fieldErrors['email'], ['Invalid email']);
    expect(exception.statusCode, 422);
  });

  test('ApiUnauthorizedException uses 401 status code by default', () {
    const exception = ApiUnauthorizedException();

    expect(exception.statusCode, 401);
    expect(exception.message, isNotEmpty);
  });
}
