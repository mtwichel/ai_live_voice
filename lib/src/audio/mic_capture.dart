import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../ai_live_voice_log.dart';

/// Streams 16 kHz, 16-bit, mono PCM audio bytes from the system microphone.
///
/// This is the input format the Gemini Live API expects on `sendAudio`.
class MicCapture {
  MicCapture({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  static const _config = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
  );

  final AudioRecorder _recorder;

  StreamSubscription<Uint8List>? _subscription;
  StreamController<Uint8List>? _outputController;
  bool _disposed = false;

  /// Whether [start] has produced a stream that has not yet been [stop]ped.
  bool get isRunning => _outputController != null;

  /// Requests microphone permission and begins streaming PCM frames.
  ///
  /// The returned stream yields raw little-endian Int16 samples packed into
  /// `Uint8List` chunks. Listeners must drain it; otherwise the underlying
  /// recorder will buffer indefinitely.
  Future<Stream<Uint8List>> start() async {
    if (_disposed) {
      throw StateError('MicCapture has been disposed');
    }
    if (_outputController != null) {
      throw StateError('MicCapture is already running');
    }

    // permission_handler only registers native code on Android, iOS, web, and
    // Windows — not on macOS or Linux. Calling [Permission.microphone] there
    // throws MissingPluginException.
    await _requestMicPermissionOnMobile();

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      aiLiveVoiceLog(
        'Microphone not permitted (recorder.hasPermission == false, '
        'platform=$defaultTargetPlatform)',
      );
      throw const _MicPermissionDeniedException();
    }

    aiLiveVoiceLog('Starting AudioRecorder stream (16kHz pcm16 mono)…');
    final source = await _recorder.startStream(_config);
    final controller = StreamController<Uint8List>.broadcast();
    _outputController = controller;
    _subscription = source.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
      cancelOnError: false,
    );
    return controller.stream;
  }

  /// Stops the underlying recorder and closes the output stream.
  Future<void> stop() async {
    final subscription = _subscription;
    final controller = _outputController;
    _subscription = null;
    _outputController = null;

    await subscription?.cancel();
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  /// Releases all underlying resources. Safe to call multiple times.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    await _recorder.dispose();
  }

  /// Runtime request where the permission_handler plugin is actually embedded.
  ///
  /// Desktop (especially macOS) uses `record` + plist/entitlements and the
  /// OS dialog via [AudioRecorder.hasPermission] / [startStream] instead.
  Future<void> _requestMicPermissionOnMobile() async {
    if (kIsWeb) return;
    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      return;
    }
    final status = await Permission.microphone.request();
    aiLiveVoiceLog(
      'permission_handler microphone status=$status '
      '(platform=$defaultTargetPlatform)',
    );
    if (!status.isGranted && !status.isLimited) {
      throw const _MicPermissionDeniedException();
    }
  }
}

class _MicPermissionDeniedException implements Exception {
  const _MicPermissionDeniedException();

  @override
  String toString() =>
      'Microphone permission was denied. Grant access in system settings '
      'and try again.';
}
