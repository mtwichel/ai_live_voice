import 'dart:typed_data';

import 'package:ai_live_voice/src/audio/voice_audio_profile.dart';
import 'package:ai_live_voice/src/audio/voice_uplink_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveUplinkSendMode', () {
    test('returns realMic during model speech', () {
      expect(
        resolveUplinkSendMode(
          postTurnEchoGuardActive: false,
          useSilenceDuringPostTurnGuard: true,
        ),
        VoiceUplinkSendMode.realMic,
      );
    });

    test('returns silence when post-turn guard is active', () {
      expect(
        resolveUplinkSendMode(
          postTurnEchoGuardActive: true,
          useSilenceDuringPostTurnGuard: true,
        ),
        VoiceUplinkSendMode.silence,
      );
    });
  });

  group('uplinkPayloadForChunk', () {
    test('silence mode produces zero-filled buffer of same length', () {
      final chunk = Uint8List.fromList([1, 2, 3, 4]);
      final payload = uplinkPayloadForChunk(chunk, VoiceUplinkSendMode.silence);
      expect(payload.length, chunk.length);
      expect(payload.every((b) => b == 0), isTrue);
    });
  });

  group('VoiceAudioProfile', () {
    test('speakers profile uses post-turn echo guard', () {
      expect(
        VoiceAudioProfile.speakers.postTurnEchoGuard,
        const Duration(milliseconds: 450),
      );
      expect(VoiceAudioProfile.speakers.useSilenceDuringPostTurnGuard, isTrue);
    });
  });
}
