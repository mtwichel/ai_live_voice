import 'client/config.dart';
import 'live/live_client.dart';

/// Minimal Google AI client used by [AILiveVoiceClient] for Live sessions only.
class GoogleAIClient {
  /// Creates a client with the given [config].
  GoogleAIClient({required GoogleAIConfig config}) : _config = config;

  final GoogleAIConfig _config;
  LiveClient? _liveClient;

  /// Returns a [LiveClient] for Gemini Live WebSocket sessions.
  LiveClient createLiveClient() {
    _liveClient ??= LiveClient(config: _config);
    return _liveClient!;
  }

  /// Closes active Live sessions.
  void close() {
    final client = _liveClient;
    _liveClient = null;
    if (client != null) {
      client.close();
    }
  }
}
