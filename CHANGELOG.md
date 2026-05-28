# Changelog

## 1.0.0 (2026-05-28)


### Features

* add minimal example app for package evaluators ([0d06d49](https://github.com/mtwichel/ai_live_voice/commit/0d06d49141b2e2238357e4b448eda04929256672))
* add minimal example app for package evaluators ([c98ed5f](https://github.com/mtwichel/ai_live_voice/commit/c98ed5f0300fa6a9351c755b6b8a6306c5480a73))


### Bug Fixes

* **ci:** allow distros in spell check ([2bfeb1f](https://github.com/mtwichel/ai_live_voice/commit/2bfeb1f65f3ba81db202abac573be5e923c1d942))

## 0.0.1-dev.1

### Added

- `example/` app for evaluators: minimal voice loop with `GEMINI_API_KEY` via `--dart-define`.

- Publishable `ai_live_voice` package with `AILiveVoiceClient` and `VoiceStatus` API.
- `gemini_tools.dart` export for Gemini Live tool schema types.
- Speaker-only echo guard and voice barge-in via Gemini Live server VAD.
