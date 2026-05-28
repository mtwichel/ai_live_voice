import 'dart:async';

import 'package:ai_live_voice/ai_live_voice.dart';
import 'package:flutter/material.dart';

const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

void main() {
  runApp(const VoiceExampleApp());
}

/// Minimal host app for evaluators — see [example/README.md].
class VoiceExampleApp extends StatelessWidget {
  const VoiceExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ai_live_voice example',
      home: _apiKey.isEmpty
          ? const _MissingApiKeyScreen()
          : VoiceDemoScreen(client: AILiveVoiceClient(apiKey: _apiKey)),
    );
  }
}

class _MissingApiKeyScreen extends StatelessWidget {
  const _MissingApiKeyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ai_live_voice')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Set GEMINI_API_KEY when running:\n\n'
          'flutter run --dart-define=GEMINI_API_KEY=your_key',
        ),
      ),
    );
  }
}

class VoiceDemoScreen extends StatefulWidget {
  const VoiceDemoScreen({required this.client, super.key});

  final AILiveVoiceClient client;

  @override
  State<VoiceDemoScreen> createState() => _VoiceDemoScreenState();
}

class _VoiceDemoScreenState extends State<VoiceDemoScreen> {
  late final StreamSubscription<VoiceStatus> _statusSub;
  VoiceStatus _status = const VoiceIdle();
  String? _startError;

  @override
  void initState() {
    super.initState();
    _statusSub = widget.client.status.listen((status) {
      if (!mounted) return;
      setState(() => _status = status);
    });
  }

  @override
  void dispose() {
    _statusSub.cancel();
    unawaited(widget.client.dispose());
    super.dispose();
  }

  String _statusLabel(VoiceStatus status) {
    return switch (status) {
      VoiceIdle() => 'Idle',
      VoiceConnecting() => 'Connecting…',
      VoiceListening() => 'Listening',
      VoiceSpeaking() => 'Speaking',
      VoiceError(:final message) => 'Error: $message',
    };
  }

  Future<void> _onStart() async {
    setState(() => _startError = null);
    try {
      await widget.client.start();
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _startError = voiceUserFacingMessage(error, widget.client.model),
      );
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onStop() async {
    await widget.client.stop();
    if (!mounted) return;
    setState(() => _startError = null);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.client.isActive;
    return Scaffold(
      appBar: AppBar(title: const Text('ai_live_voice')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Status: ${_statusLabel(_status)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_startError != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _startError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isActive ? null : _onStart,
                    child: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isActive ? _onStop : null,
                    child: const Text('Stop'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
