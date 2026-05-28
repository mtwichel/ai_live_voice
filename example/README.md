# ai_live_voice example

Minimal app for evaluating [ai_live_voice](../README.md). Not published (`publish_to: none`).

## Prerequisites

- Flutter 3.41+ and Dart 3.11+
- A [Gemini API key](https://aistudio.google.com/apikey) with the Generative Language API enabled
- Microphone access on the device or desktop

## Run

From this directory:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key
```

Optional model override (see package README):

```bash
flutter run \
  --dart-define=GEMINI_API_KEY=your_key \
  --dart-define=GEMINI_LIVE_MODEL=gemini-2.0-flash-live-preview-04-09
```

### Platform targets

```bash
flutter run -d macos --dart-define=GEMINI_API_KEY=your_key
flutter run -d ios --dart-define=GEMINI_API_KEY=your_key
flutter run -d android --dart-define=GEMINI_API_KEY=your_key
```

Windows and Linux builds are supported by the package; smoke-test on your machine if you use them.

### IDE dart-defines

Configure `GEMINI_API_KEY` in your IDE’s Flutter run arguments (same as `--dart-define`).

## Usage

1. Tap **Start** — status moves through Connecting → Listening (and Speaking while the model talks).
2. Tap **Stop** — returns to Idle. After an error, tap **Stop** before starting again.

## Troubleshooting

- **Missing key at launch** — the app shows setup instructions; pass `--dart-define=GEMINI_API_KEY=...`.
- **macOS mic denied** — ensure microphone is allowed for the app in System Settings; this example includes the audio-input sandbox entitlement.
- **iOS Simulator** — microphone behavior is limited; use a physical device for a full voice test.
- **Linux** — audio depends on PipeWire/PulseAudio and desktop permissions; some distros require your user in the `audio` group.

Never commit API keys to git.
