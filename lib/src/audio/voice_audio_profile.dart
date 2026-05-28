import '../providers/gemini/gemini_live.dart';

/// Live audio behavior for v1 (speaker-style echo guard on all platforms).
class VoiceAudioProfile {
  const VoiceAudioProfile({
    required this.postTurnEchoGuard,
    required this.realtimeInputConfig,
    this.useSilenceDuringPostTurnGuard = true,
  });

  /// How long after [turnComplete] to keep the post-turn echo guard active.
  final Duration postTurnEchoGuard;

  /// When true, uplink sends silence while the post-turn guard is active.
  final bool useSilenceDuringPostTurnGuard;

  /// VAD / interruption config sent at Live session connect.
  final RealtimeInputConfig realtimeInputConfig;

  /// Conservative profile for built-in speakers (v1 default everywhere).
  static final VoiceAudioProfile speakers = VoiceAudioProfile(
    postTurnEchoGuard: const Duration(milliseconds: 450),
    realtimeInputConfig: _kSpeakersRealtimeInput,
  );
}

final RealtimeInputConfig _kSpeakersRealtimeInput = RealtimeInputConfig(
  automaticActivityDetection: AutomaticActivityDetection.enabled(
    silenceDurationMs: 1000,
    prefixPaddingMs: 220,
    startSensitivity: StartSensitivity.low,
    endSensitivity: EndSensitivity.low,
  ),
  activityHandling: ActivityHandling.startOfActivityInterrupts,
);
