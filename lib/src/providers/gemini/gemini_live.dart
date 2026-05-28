/// Inlined Gemini Live / tool types (from googleai_dart, trimmed for ai_live_voice).
library;

export 'auth/auth_provider.dart';
export 'client/config.dart' show ApiMode, ApiVersion, GoogleAIConfig;
export 'errors/exceptions.dart'
    show
        LiveConnectionException,
        LiveSessionClosedException,
        LiveSessionException,
        LiveSessionSetupException;
export 'googleai_client.dart';
export 'live/live_client.dart';
export 'live/live_session.dart';
export 'models/content/content.dart';
export 'models/content/part.dart' show InlineDataPart, Part, TextPart;
export 'models/generation/response_modality.dart';
export 'models/generation/schema.dart';
export 'models/config/live_config.dart';
export 'models/config/live_generation_config.dart';
export 'models/config/automatic_activity_detection.dart';
export 'models/config/realtime_input_config.dart';
export 'models/enums/activity_handling.dart';
export 'models/enums/end_sensitivity.dart';
export 'models/enums/start_sensitivity.dart';
export 'models/messages/server/server_message.dart';
export 'models/tools/function_call.dart';
export 'models/tools/function_declaration.dart';
export 'models/tools/function_response.dart';
export 'models/tools/tool.dart';
