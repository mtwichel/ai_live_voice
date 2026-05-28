import 'dart:developer' as developer;

/// Logger name for [aiLiveVoiceLog] output.
const String aiLiveVoiceLogName = 'ai_live_voice';

/// Logs a line to the Dart developer log (visible in IDE / `flutter run`).
void aiLiveVoiceLog(String message, {Object? error, StackTrace? stackTrace}) {
  developer.log(
    message,
    name: aiLiveVoiceLogName,
    error: error,
    stackTrace: stackTrace,
  );
}
