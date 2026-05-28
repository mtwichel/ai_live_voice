/// Lifecycle of an [AILiveVoiceClient] session.
///
/// Surfaced on [AILiveVoiceClient.status] so the host app can drive UI.
sealed class VoiceStatus {
  const VoiceStatus();
}

/// No active session.
class VoiceIdle extends VoiceStatus {
  const VoiceIdle();

  @override
  String toString() => 'VoiceIdle';
}

/// Connecting mic, speaker, and Live WebSocket.
class VoiceConnecting extends VoiceStatus {
  const VoiceConnecting();

  @override
  String toString() => 'VoiceConnecting';
}

/// Listening for user speech (mic uplink active).
class VoiceListening extends VoiceStatus {
  const VoiceListening();

  @override
  String toString() => 'VoiceListening';
}

/// Model audio is playing through the speakers.
class VoiceSpeaking extends VoiceStatus {
  const VoiceSpeaking();

  @override
  String toString() => 'VoiceSpeaking';
}

/// Session failed or was interrupted with an error.
class VoiceError extends VoiceStatus {
  const VoiceError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      other is VoiceError && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'VoiceError($message)';
}
