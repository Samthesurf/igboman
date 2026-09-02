import 'dart:io' show Platform;

/// Resolves the Gemini API key, preferring the compile-time define first.
///
/// Pure helper so tests can exercise the resolution logic without touching
/// the process environment. Order:
/// 1. [fromEnv] (compile-time `String.fromEnvironment` value),
/// 2. `GEMINI_API_KEY` in [env],
/// 3. `GOOGLE_GENAI_API_KEY` in [env],
/// otherwise throws [StateError].
String resolveKey(String fromEnv, Map<String, String> env) {
  if (fromEnv.isNotEmpty) {
    return fromEnv;
  }
  final geminiKey = env['GEMINI_API_KEY'] ?? '';
  if (geminiKey.isNotEmpty) {
    return geminiKey;
  }
  final googleGenAiKey = env['GOOGLE_GENAI_API_KEY'] ?? '';
  if (googleGenAiKey.isNotEmpty) {
    return googleGenAiKey;
  }
  throw StateError(
    'No Gemini API key found. Set GEMINI_API_KEY (via --dart-define or the '
    'environment) or GOOGLE_GENAI_API_KEY before starting the tutor.',
  );
}

/// The only source of the API key in the app.
///
/// Reads the key from `String.fromEnvironment('GEMINI_API_KEY')` first
/// (supports `flutter run --dart-define=GEMINI_API_KEY=...`), then falls back
/// to the `GEMINI_API_KEY` and `GOOGLE_GENAI_API_KEY` environment variables.
class ApiConfig {
  ApiConfig._();

  static String resolveApiKey() {
    return resolveKey(
      const String.fromEnvironment('GEMINI_API_KEY'),
      Platform.environment,
    );
  }
}