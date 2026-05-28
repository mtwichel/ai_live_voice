import 'package:ai_live_voice/ai_live_voice.dart';
import 'package:ai_live_voice/gemini_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AILiveVoiceClient', () {
    test('can be constructed with an API key', () {
      final client = AILiveVoiceClient(apiKey: 'fake-key');
      expect(client.isActive, isFalse);
      expect(client.status, isA<Stream<VoiceStatus>>());
    });

    test('seeds the status stream with VoiceIdle', () async {
      final client = AILiveVoiceClient(apiKey: 'fake-key');
      addTearDown(client.dispose);

      final first = await client.status.first;
      expect(first, isA<VoiceIdle>());
    });

    test('asserts when tools are non-empty without onToolCalls', () {
      expect(
        () => AILiveVoiceClient(
          apiKey: 'fake-key',
          liveTools: [Tool(functionDeclarations: [])],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('dispose is safe before start', () async {
      final client = AILiveVoiceClient(apiKey: 'fake-key');
      await client.dispose();
      await client.dispose();
    });

    test('stop is a no-op when not running', () async {
      final client = AILiveVoiceClient(apiKey: 'fake-key');
      addTearDown(client.dispose);
      await client.stop();
      expect(client.isActive, isFalse);
    });
  });

  group('VoiceStatus', () {
    test('errors with the same message are equal', () {
      expect(const VoiceError('boom'), equals(const VoiceError('boom')));
    });

    test('toString includes meaningful labels', () {
      expect(const VoiceIdle().toString(), 'VoiceIdle');
      expect(const VoiceConnecting().toString(), 'VoiceConnecting');
      expect(const VoiceListening().toString(), 'VoiceListening');
      expect(const VoiceSpeaking().toString(), 'VoiceSpeaking');
      expect(const VoiceError('nope').toString(), 'VoiceError(nope)');
    });
  });
}
