import 'dart:async' as async;

import 'package:googleai_dart/googleai_dart.dart';

import '../api_config.dart';
import 'prompt_builder.dart';
import 'tutor_service.dart';

/// Gemini-backed [TutorService] using the googleai_dart SDK (model locked to
/// `gemini-3.1-flash-lite`).
class GeminiTutorService implements TutorService {
  /// The locked model for the tutor.
  static const String model = 'gemini-3.1-flash-lite';

  final GoogleAIClient _client;

  /// Creates the service, resolving the API key via [ApiConfig] unless an
  /// explicit [client] is injected (useful for tests and alternate auth).
  GeminiTutorService({GoogleAIClient? client, String? apiKey})
      : _client = client ??
            GoogleAIClient(
              config: GoogleAIConfig.googleAI(
                authProvider: ApiKeyProvider(
                  apiKey ?? ApiConfig.resolveApiKey(),
                ),
                timeout: const Duration(seconds: 30),
              ),
            );

  @override
  Stream<String> chat({
    required List<TutorTurn> history,
    required TutorContext context,
  }) async* {
    final request = GenerateContentRequest(
      systemInstruction: Content(
        parts: [TextPart(buildSystemPrompt(context))],
      ),
      contents: trimHistory(history)
          .map(
            (turn) => Content(
              role: turn.role == 'tutor' ? 'model' : 'user',
              parts: [TextPart(turn.text)],
            ),
          )
          .toList(),
    );

    try {
      await for (final chunk in _client.models.streamGenerateContent(
        model: model,
        request: request,
      )) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          yield text;
        }
      }
    } on GoogleAIException {
      throw const TutorException(
        'Ada could not reach the tutor service just now. '
        'Please try again in a moment.',
      );
    } on async.TimeoutException {
      throw const TutorException(
        'Ada did not reply in time. Check your connection and try again.',
      );
    }
  }

  @override
  void dispose() {
    _client.close();
  }
}