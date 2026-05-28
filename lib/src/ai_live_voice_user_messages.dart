import 'providers/gemini/gemini_live.dart';

/// Short message for UI (SnackBar, dialogs) from a thrown error object.
String voiceUserFacingMessage(Object error, String model) {
  if (error is LiveSessionSetupException) {
    return messageForLiveSessionSetupFailure(error, model);
  }
  return 'Live voice error: $error';
}

/// Explains [LiveSessionSetupException] with special handling for common
/// WebSocket close codes from Google's Live endpoint.
String messageForLiveSessionSetupFailure(
  LiveSessionSetupException e,
  String model,
) {
  final cause = e.cause;
  if (cause is LiveSessionClosedException) {
    final code = cause.code;
    final reason = cause.reason?.trim();
    if (code == 1011) {
      final detail = (reason != null && reason.isNotEmpty)
          ? reason
          : 'Internal error encountered.';
      return 'Gemini Live ended setup from the server (close code $code: '
          '$detail) while using "$model". That comes from Google\'s service, '
          'not this app. Retry later, confirm the Generative Language API is '
          'enabled for your key, and try the same model in Google AI Studio '
          'Live (https://aistudio.google.com/live?model=$model) with the same '
          'Google account as your API key to see if the failure is outside '
          'this app. You can also try another Live model via '
          '--dart-define=GEMINI_LIVE_MODEL=gemini-2.0-flash-live-preview-04-09.';
    }
    if (code != null || (reason != null && reason.isNotEmpty)) {
      return 'Live session setup failed: WebSocket closed (code: $code)'
          '${reason != null && reason.isNotEmpty ? ': $reason' : ''}';
    }
  }
  return 'Live session setup failed: $e';
}
