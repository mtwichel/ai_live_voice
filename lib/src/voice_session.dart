import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'providers/gemini/gemini_live.dart';
import 'package:meta/meta.dart';
import 'package:web_socket/web_socket.dart';

import 'ai_live_voice_log.dart';
import 'ai_live_voice_user_messages.dart';
import 'audio/mic_capture.dart';
import 'audio/speaker_playback.dart';
import 'audio/voice_audio_profile.dart';
import 'audio/voice_uplink_policy.dart';
import 'models/voice_status.dart';
import 'voice_tool_handler.dart';

/// Orchestrates a single Gemini Live conversation: WebSocket, mic uplink,
/// speaker playback, and [VoiceStatus] updates.
class VoiceSession {
  VoiceSession({
    required GoogleAIClient client,
    required String model,
    required MicCapture mic,
    required SpeakerPlayback speaker,
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
  final MicCapture _mic;
  final SpeakerPlayback _speaker;
  final List<Tool>? _liveTools;
  final Content? _liveSystemInstruction;
  final VoiceToolCallHandler? _onToolCalls;

  final StreamController<VoiceStatus> _statusController =
      StreamController<VoiceStatus>.broadcast();

  static final VoiceAudioProfile _audioProfile = VoiceAudioProfile.speakers;

  LiveClient? _liveClient;
  LiveSession? _liveSession;
  StreamSubscription<BidiGenerateContentServerMessage>? _messagesSubscription;
  StreamSubscription<Uint8List>? _micSubscription;
  Timer? _idleAfterAudioTimer;
  bool _running = false;
  bool _disposed = false;
  bool _speakingUiActive = false;
  bool _postTurnEchoGuardActive = false;

  Stream<VoiceStatus> get statusStream => _statusController.stream;

  Future<void> start() async {
    if (_disposed) {
      throw StateError('VoiceSession has been disposed');
    }
    if (_running) {
      throw StateError('VoiceSession is already running');
    }
    _running = true;
    _emit(const VoiceConnecting());

    try {
      aiLiveVoiceLog(
        'Starting session (model=$_model, web=$kIsWeb, '
        'platform=$defaultTargetPlatform)',
      );
      await _speaker.start();
      final micStream = await _mic.start();

      aiLiveVoiceLog(
        'Audio profile postTurnEchoGuard='
        '${_audioProfile.postTurnEchoGuard.inMilliseconds}ms',
      );

      final liveClient = _client.createLiveClient();
      _liveClient = liveClient;

      final session = await liveClient.connect(
        model: _model,
        liveConfig: LiveConfig(
          generationConfig: LiveGenerationConfig.audioOnly(),
          systemInstruction: _liveSystemInstruction,
          tools: _liveTools,
          realtimeInputConfig: _audioProfile.realtimeInputConfig,
        ),
      );
      _liveSession = session;

      _messagesSubscription = session.messages.listen(
        _onServerMessage,
        onError: (Object error, StackTrace stackTrace) {
          aiLiveVoiceLog(
            'Live message stream error',
            error: error,
            stackTrace: stackTrace,
          );
          _emit(VoiceError('Live session error: $error'));
        },
        onDone: () {
          aiLiveVoiceLog('Live message stream closed (onDone)');
          if (_running) {
            _running = false;
            _emit(const VoiceError('Connection lost'));
          }
        },
      );

      _micSubscription = micStream.listen(
        (chunk) {
          final live = _liveSession;
          if (live != null && live.isConnected) {
            try {
              final mode = resolveUplinkSendMode(
                postTurnEchoGuardActive: _postTurnEchoGuardActive,
                useSilenceDuringPostTurnGuard:
                    _audioProfile.useSilenceDuringPostTurnGuard,
              );
              live.sendAudio(uplinkPayloadForChunk(chunk, mode));
            } catch (e, st) {
              aiLiveVoiceLog(
                'sendAudio failed (isConnected=${live.isConnected})',
                error: e,
                stackTrace: st,
              );
            }
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          aiLiveVoiceLog(
            'Microphone stream error',
            error: error,
            stackTrace: stackTrace,
          );
          _emit(VoiceError('Microphone error: $error'));
        },
      );

      _emitListening();
    } on LiveSessionClosedException catch (e, st) {
      aiLiveVoiceLog(
        'LiveSessionClosedException code=${e.code} reason=${e.reason}',
        error: e,
        stackTrace: st,
      );
      final detail = StringBuffer('Server closed the WebSocket')
        ..write(e.code != null ? ' (code ${e.code})' : '')
        ..write(e.reason != null && e.reason!.isNotEmpty ? ': ${e.reason}' : '')
        ..write(
          '. Check GEMINI_API_KEY, enable the Generative Language API for that '
          'key, and try a supported Live model id if this persists.',
        );
      _emit(VoiceError(detail.toString()));
      await _teardown();
      rethrow;
    } on WebSocketConnectionClosed catch (e, st) {
      aiLiveVoiceLog(
        'WebSocket closed before setup completed',
        error: e,
        stackTrace: st,
      );
      _emit(
        VoiceError(
          'Connection closed before setup completed ($e). Usually the server '
          'rejected the session: wrong or retired model id, invalid API key, '
          'or Live API not enabled. Try `--dart-define=GEMINI_LIVE_MODEL=...` '
          'or another Live model id (e.g. gemini-2.0-flash-live-preview-04-09).',
        ),
      );
      await _teardown();
      rethrow;
    } on LiveConnectionException catch (e, st) {
      aiLiveVoiceLog(
        'LiveConnectionException uri=${e.uri} message=${e.message}',
        error: e,
        stackTrace: st,
      );
      _emit(VoiceError('Could not connect to Live API: $e'));
      await _teardown();
      rethrow;
    } on LiveSessionSetupException catch (e, st) {
      aiLiveVoiceLog(
        'LiveSessionSetupException details=${e.details}',
        error: e,
        stackTrace: st,
      );
      _emit(VoiceError(messageForLiveSessionSetupFailure(e, _model)));
      await _teardown();
      rethrow;
    } catch (error, stackTrace) {
      aiLiveVoiceLog(
        'Failed to start session',
        error: error,
        stackTrace: stackTrace,
      );
      _emit(VoiceError('Failed to start session: $error'));
      await _teardown();
      rethrow;
    }
  }

  Future<void> stop() async {
    if (!_running) return;
    aiLiveVoiceLog('stop() requested');
    _running = false;
    await _teardown();
    _emit(const VoiceIdle());
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _running = false;
    await _teardown();
    await _statusController.close();
  }

  void _onServerMessage(BidiGenerateContentServerMessage message) {
    switch (message) {
      case BidiGenerateContentSetupComplete(:final sessionId):
        aiLiveVoiceLog('Server setupComplete sessionId=$sessionId');
      case BidiGenerateContentServerContent(
        :final modelTurn,
        :final turnComplete,
        :final interrupted,
      ):
        if (interrupted ?? false) {
          aiLiveVoiceLog('Server interrupted model output');
          _idleAfterAudioTimer?.cancel();
          _postTurnEchoGuardActive = false;
          unawaited(_speaker.clearQueuedAudio());
          _emitListening();
        } else if (modelTurn != null) {
          _playAudioParts(modelTurn);
        }
        if (turnComplete ?? false) {
          _scheduleReturnToListening();
        }
      case BidiGenerateContentToolCall(:final functionCalls):
        _dispatchToolCalls(functionCalls);
      case BidiGenerateContentToolCallCancellation(:final ids):
        aiLiveVoiceLog('Server toolCallCancellation ids=$ids');
      case GoAway(:final timeLeft):
        aiLiveVoiceLog('Server GoAway timeLeft=$timeLeft');
      case SessionResumptionUpdate(:final newHandle, :final resumable):
        aiLiveVoiceLog(
          'SessionResumptionUpdate resumable=$resumable '
          'newHandle=${newHandle != null ? "(present)" : "null"}',
        );
      case UnknownServerMessage(:final rawJson):
        aiLiveVoiceLog('Unknown server message keys=${rawJson.keys.toList()}');
    }
  }

  void _dispatchToolCalls(List<FunctionCall> functionCalls) {
    final handler = _onToolCalls;
    final live = _liveSession;
    if (handler == null) {
      aiLiveVoiceLog(
        'Tool call: no onToolCalls handler registered; skipping responses',
      );
      return;
    }
    if (live == null || !live.isConnected) {
      aiLiveVoiceLog('Tool call: session not connected; skipping responses');
      return;
    }
    try {
      final responses = handler(functionCalls);
      live.sendToolResponse(responses);
    } catch (e, st) {
      aiLiveVoiceLog('onToolCalls failed', error: e, stackTrace: st);
      final errorResponses = <FunctionResponse>[
        for (final call in functionCalls)
          FunctionResponse(
            id: call.id,
            name: call.name,
            response: {'ok': false, 'error': e.toString()},
          ),
      ];
      try {
        live.sendToolResponse(errorResponses);
      } catch (sendError, sendSt) {
        aiLiveVoiceLog(
          'sendToolResponse after handler failure',
          error: sendError,
          stackTrace: sendSt,
        );
      }
    }
  }

  void _playAudioParts(Content modelTurn) {
    var hadAudio = false;
    for (final part in modelTurn.parts) {
      if (part is InlineDataPart) {
        final data = part.inlineData;
        if (data.mimeType.startsWith('audio/')) {
          final bytes = Uint8List.fromList(base64Decode(data.data));
          _speaker.feed(bytes);
          hadAudio = true;
        }
      }
    }
    if (hadAudio) {
      _postTurnEchoGuardActive = false;
      _idleAfterAudioTimer?.cancel();
      if (!_speakingUiActive) {
        _speakingUiActive = true;
        _emit(const VoiceSpeaking());
      }
    }
  }

  void _scheduleReturnToListening() {
    _idleAfterAudioTimer?.cancel();
    final guard = _audioProfile.postTurnEchoGuard;
    if (guard > Duration.zero) {
      _postTurnEchoGuardActive = true;
    }
    _idleAfterAudioTimer = Timer(guard, () {
      if (_running) {
        _emitListening();
      }
    });
  }

  void _emitListening() {
    _speakingUiActive = false;
    _postTurnEchoGuardActive = false;
    _emit(const VoiceListening());
  }

  void _emit(VoiceStatus status) {
    if (_statusController.isClosed) return;
    _statusController.add(status);
  }

  Future<void> _teardown() async {
    _idleAfterAudioTimer?.cancel();
    _idleAfterAudioTimer = null;

    await _micSubscription?.cancel();
    _micSubscription = null;

    final session = _liveSession;
    _liveSession = null;
    if (session != null && session.isConnected) {
      try {
        session.signalAudioStreamEnd();
      } catch (e, st) {
        aiLiveVoiceLog(
          'signalAudioStreamEnd during teardown',
          error: e,
          stackTrace: st,
        );
      }
      try {
        await session.close();
      } catch (e, st) {
        aiLiveVoiceLog(
          'session.close during teardown',
          error: e,
          stackTrace: st,
        );
      }
    }

    await _messagesSubscription?.cancel();
    _messagesSubscription = null;

    final liveClient = _liveClient;
    _liveClient = null;
    if (liveClient != null) {
      try {
        await liveClient.close();
      } catch (e, st) {
        aiLiveVoiceLog(
          'liveClient.close during teardown',
          error: e,
          stackTrace: st,
        );
      }
    }

    try {
      await _mic.stop();
    } catch (e, st) {
      aiLiveVoiceLog('mic.stop during teardown', error: e, stackTrace: st);
    }
    try {
      await _speaker.stop();
    } catch (e, st) {
      aiLiveVoiceLog('speaker.stop during teardown', error: e, stackTrace: st);
    }
  }

  @visibleForTesting
  bool get isRunning => _running;
}
