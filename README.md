# ai_live_voice

[![ci](https://github.com/mtwichel/ai_live_voice/actions/workflows/main.yaml/badge.svg)](https://github.com/mtwichel/ai_live_voice/actions/workflows/main.yaml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Flutter package for real-time **AI voice** conversations using the **Gemini Live** API: microphone capture, speaker playback, voice barge-in, and optional tool calling.

## Supported platforms (v1)

iOS, Android, macOS, Windows, Linux. Web is not supported in v1.

## Quick start

```yaml
dependencies:
  ai_live_voice: ^0.0.1-dev.1
```

```dart
import 'package:ai_live_voice/ai_live_voice.dart';
import 'package:ai_live_voice/gemini_tools.dart';

final client = AILiveVoiceClient(
  apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
  onToolCalls: myHandler, // required if `liveTools` is non-empty
);

client.status.listen((status) {
  // VoiceIdle, VoiceConnecting, VoiceListening, VoiceSpeaking, VoiceError
});

await client.start();
// ...
await client.stop();
await client.dispose();
```

Run with:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key
```

Optional model override:

```bash
flutter run --dart-define=GEMINI_API_KEY=... --dart-define=GEMINI_LIVE_MODEL=gemini-2.0-flash-live-preview-04-09
```

## Tool calling

Define tools with types from `gemini_tools.dart` (Gemini-specific in v1). Implement [VoiceToolCallHandler] and pass it to [AILiveVoiceClient] when `liveTools` is non-empty.

## Host responsibilities

- Provide a valid API key at runtime (never commit keys).
- Add microphone permission strings / entitlements on each platform.
- Own UI for start/stop and error display ([AILiveVoiceClient.status] only).
- Reuse one [AILiveVoiceClient] per tool set — config is fixed for the instance lifetime.

## Voice barge-in

While the model speaks, real mic audio is sent so server VAD can interrupt. On `interrupted`, queued speaker audio is cleared. A short post-turn silence uplink (~450 ms) reduces speaker→mic false triggers (v1 uses this profile on all outputs).

## License

MIT — see [LICENSE](LICENSE).
