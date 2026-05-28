import 'dart:async';

import 'providers/gemini/gemini_live.dart';
import 'package:meta/meta.dart';

import 'ai_live_voice_log.dart';
import 'audio/mic_capture.dart';
import 'audio/speaker_playback.dart';
import 'models/voice_status.dart';
import 'voice_session.dart';
import 'voice_tool_handler.dart';

/// Default Live model for native audio in/out.
///
/// Override via `--dart-define=GEMINI_LIVE_MODEL=...`.
const String kDefaultLiveVoiceModel = String.fromEnvironment(
  'GEMINI_LIVE_MODEL',
  defaultValue: 'gemini-3.1-flash-live-preview',
);

/// AI voice client: mic, speakers, and a Gemini Live WebSocket session.
///
/// One instance owns at most one active session. Call [start], [stop], and
/// [dispose] when finished.
class AILiveVoiceClient {
  /// Creates an [AILiveVoiceClient].
  AILiveVoiceClient({
    required String apiKey,
    String model = kDefaultLiveVoiceModel,
    List<Tool>? liveTools,
    Content? liveSystemInstruction,
    VoiceToolCallHandler? onToolCalls,
  }) : assert(apiKey.isNotEmpty, 'apiKey must not be empty'),
       assert(
         liveTools == null || liveTools.isEmpty || onToolCalls != null,
         'onToolCalls is required when liveTools is non-empty',
       ),
       _model = model,
       _liveTools = liveTools,
       _liveSystemInstruction = liveSystemInstruction,
       _onToolCalls = onToolCalls,
       _client = GoogleAIClient(
         config: GoogleAIConfig.googleAI(authProvider: ApiKeyProvider(apiKey)),
       );

  @visibleForTesting
  AILiveVoiceClient.forTesting({
    required GoogleAIClient client,
    MicCapture? mic,
    SpeakerPlayback? speaker,
    String model = kDefaultLiveVoiceModel,
    List<Tool>? liveTools,
    Content? liveSystemInstruction,
    VoiceToolCallHandler? onToolCalls,
  }) : _client = client,
       _model = model,
       _mic = mic,
       _speaker = speaker,
       _liveTools = liveTools,
       _liveSystemInstruction = liveSystemInstruction,
       _onToolCalls = onToolCalls;

  final GoogleAIClient _client;
  final String _model;
  final List<Tool>? _liveTools;
  final Content? _liveSystemInstruction;
  final VoiceToolCallHandler? _onToolCalls;
  MicCapture? _mic;
  SpeakerPlayback? _speaker;

  VoiceSession? _session;
  StreamSubscription<VoiceStatus>? _sessionStatusSub;

  final StreamController<VoiceStatus> _statusController =
      StreamController<VoiceStatus>.broadcast();

  VoiceStatus _lastStatus = const VoiceIdle();
  bool _disposed = false;

  Stream<VoiceStatus> get status async* {
    yield _lastStatus;
    yield* _statusController.stream;
  }

  bool get isActive => _session != null;

  String get model => _model;

  Future<void> start() async {
    if (_disposed) {
      throw StateError('AILiveVoiceClient has been disposed');
    }
    if (_session != null) return;

    final mic = _mic ??= MicCapture();
    final speaker = _speaker ??= SpeakerPlayback();

    final session = VoiceSession(
      client: _client,
      model: _model,
      mic: mic,
      speaker: speaker,
      liveTools: _liveTools,
      liveSystemInstruction: _liveSystemInstruction,
      onToolCalls: _onToolCalls,
    );
    _session = session;
    _sessionStatusSub = session.statusStream.listen(_emit);

    try {
      await session.start();
    } catch (error, stackTrace) {
      aiLiveVoiceLog(
        'AILiveVoiceClient.start failed (model=$_model)',
        error: error,
        stackTrace: stackTrace,
      );
      await _sessionStatusSub?.cancel();
      _sessionStatusSub = null;
      _session = null;
      await session.dispose();
      rethrow;
    }
  }

  Future<void> stop() async {
    final session = _session;
    if (session == null) return;
    _session = null;
    await session.stop();
    await _sessionStatusSub?.cancel();
    _sessionStatusSub = null;
    await session.dispose();
    _emit(const VoiceIdle());
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _sessionStatusSub?.cancel();
    _sessionStatusSub = null;
    final session = _session;
    _session = null;
    await session?.dispose();
    await _mic?.dispose();
    await _speaker?.dispose();
    _client.close();
    if (!_statusController.isClosed) {
      await _statusController.close();
    }
  }

  void _emit(VoiceStatus status) {
    _lastStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
