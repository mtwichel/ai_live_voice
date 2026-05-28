import 'providers/gemini/gemini_live.dart';

/// Host-implemented handler for Gemini Live [FunctionCall] batches.
typedef VoiceToolCallHandler =
    List<FunctionResponse> Function(List<FunctionCall> calls);
