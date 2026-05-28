import 'package:flutter/material.dart';

import '../../features/auth/domain/auth_exception.dart';
import '../network/api_exception.dart';

String resolveUiErrorMessage(
  Object error, {
  required String fallbackMessage,
}) {
  if (error is ApiValidationException) {
    return error.uiMessage;
  }

  if (error is AuthException) {
    return error.uiMessage;
  }

  if (error is ApiException) {
    return error.message;
  }

  return fallbackMessage;
}

void showAppErrorSnackBar(
  BuildContext context,
  String message,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

void showAppErrorSnackBarForException(
  BuildContext context,
  Object error, {
  required String fallbackMessage,
}) {
  showAppErrorSnackBar(
    context,
    resolveUiErrorMessage(error, fallbackMessage: fallbackMessage),
  );
}
