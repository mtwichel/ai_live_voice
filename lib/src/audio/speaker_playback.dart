import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

import '../ai_live_voice_log.dart';

/// Plays 24 kHz, 16-bit, little-endian, mono PCM audio chunks through the
/// system speakers using the SoLoud engine.
///
/// SoLoud's `setBufferStream` API matches the format the Gemini Live API
/// emits (`BufferType.s16le`, mono, 24 kHz) and plays back with low latency
/// across iOS, Android, macOS, and the web.
class SpeakerPlayback {
  SpeakerPlayback({SoLoud? soLoud}) : _soLoud = soLoud ?? SoLoud.instance;

  static const int _sampleRate = 24000;
  static const Channels _channels = Channels.mono;
  static const BufferType _format = BufferType.s16le;

  final SoLoud _soLoud;

  AudioSource? _stream;
  SoundHandle? _handle;
  bool _streaming = false;
  bool _disposed = false;

  bool get isRunning => _streaming;

  /// Initializes the audio engine if needed and opens a fresh PCM buffer
  /// stream ready to receive chunks.
  Future<void> start() async {
    if (_disposed) {
      throw StateError('SpeakerPlayback has been disposed');
    }
    if (_streaming) return;

    try {
      if (!_soLoud.isInitialized) {
        aiLiveVoiceLog('SoLoud.init()…');
        await _soLoud.init();
      }

      aiLiveVoiceLog(
        'SoLoud setBufferStream ($_sampleRate Hz, $_channels, $_format)…',
      );
      final stream = _soLoud.setBufferStream(
        sampleRate: _sampleRate,
        channels: _channels,
        format: _format,
        bufferingType: BufferingType.released,
        // Slightly larger buffer reduces dropped chunks (buffer-full) during
        // bursty Live API audio without a large latency hit.
        bufferingTimeNeeds: 0.18,
      );
      _stream = stream;
      _handle = _soLoud.play(stream);
      _streaming = true;
      aiLiveVoiceLog('Speaker playback started (handle=$_handle)');
    } catch (e, st) {
      aiLiveVoiceLog('Speaker start failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Enqueues a chunk of PCM16 mono 24 kHz audio for playback.
  ///
  /// No-ops if [start] has not been called or has been [stop]ped, and silently
  /// ignores buffer-full or end-of-stream errors so a single hiccup doesn't
  /// kill the conversation.
  void feed(Uint8List chunk) {
    final stream = _stream;
    if (!_streaming || stream == null || chunk.isEmpty) return;
    try {
      _soLoud.addAudioDataStream(stream, chunk);
    } on SoLoudPcmBufferFullCppException {
      // Buffer caught up: drop a chunk rather than crashing the session.
    } on SoLoudStreamEndedAlreadyCppException {
      // Stream was finalized concurrently; nothing to do.
    }
  }

  /// Drops queued PCM and opens a fresh stream.
  ///
  /// Use when the Live session signals an interruption so leftover audio in
  /// the buffer does not keep playing after the model stops generating.
  Future<void> clearQueuedAudio() async {
    if (_disposed) return;
    await stop();
    if (!_disposed) {
      await start();
    }
  }

  /// Stops playback while keeping the engine initialized for the next call.
  Future<void> stop() async {
    if (!_streaming) return;
    _streaming = false;

    final stream = _stream;
    final handle = _handle;
    _stream = null;
    _handle = null;

    if (stream != null) {
      try {
        _soLoud.setDataIsEnded(stream);
      } catch (_) {
        // Best-effort cleanup.
      }
    }
    if (handle != null) {
      try {
        await _soLoud.stop(handle);
      } catch (_) {
        // Best-effort cleanup.
      }
    }
    if (stream != null) {
      try {
        await _soLoud.disposeSource(stream);
      } catch (_) {
        // Best-effort cleanup.
      }
    }
  }

  /// Releases the playback stream and tears down the SoLoud engine.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    if (_soLoud.isInitialized) {
      _soLoud.deinit();
    }
  }
}
