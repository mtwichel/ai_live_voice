# Changelog

## Unreleased

### Added

- `example/` app for evaluators: minimal voice loop with `GEMINI_API_KEY` via `--dart-define`.

## 0.0.1-dev.1

### Added

- Publishable `ai_live_voice` package with `AILiveVoiceClient` and `VoiceStatus` API.
- `gemini_tools.dart` export for Gemini Live tool schema types.
- Speaker-only echo guard and voice barge-in via Gemini Live server VAD.

### Changed

- Renamed from `gemini_live_repository`; neutral session API (`AILiveVoiceClient`).
- Removed macOS audio route monitor plugin (v1 uses conservative speaker profile everywhere).

### Removed

- `AudioRouteMonitor` and per-route headphone/speaker profiles.

### Changed (protocol)

- Inlined minimal Gemini Live client and models under `lib/src/providers/gemini/` (no `googleai_dart` path dependency).
