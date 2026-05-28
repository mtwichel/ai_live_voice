import 'dart:typed_data';

/// Whether mic chunks sent to the Live API are real PCM or zero-filled silence.
enum VoiceUplinkSendMode {
  /// Stream captured microphone audio.
  realMic,

  /// Stream silence of the same byte length (echo guard after a turn).
  silence,
}

/// Pure policy for uplink during a Live session.
///
/// During model speech we always send real mic audio so server VAD can barge-in.
/// After [turnComplete], the speaker profile may silence uplink briefly.
VoiceUplinkSendMode resolveUplinkSendMode({
  required bool postTurnEchoGuardActive,
  required bool useSilenceDuringPostTurnGuard,
}) {
  if (postTurnEchoGuardActive && useSilenceDuringPostTurnGuard) {
    return VoiceUplinkSendMode.silence;
  }
  return VoiceUplinkSendMode.realMic;
}

/// Returns the PCM buffer to send for [chunk] under [mode].
Uint8List uplinkPayloadForChunk(Uint8List chunk, VoiceUplinkSendMode mode) {
  return switch (mode) {
    VoiceUplinkSendMode.realMic => chunk,
    VoiceUplinkSendMode.silence => Uint8List(chunk.length),
  };
}
