import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/api_config.dart';

void main() {
  group('resolveKey', () {
    test('fromEnv wins over environment variables', () {
      expect(
        resolveKey('define-key', {
          'GEMINI_API_KEY': 'gemini-key',
          'GOOGLE_GENAI_API_KEY': 'google-key',
        }),
        'define-key',
      );
    });

    test('falls back to GEMINI_API_KEY when fromEnv is empty', () {
      expect(
        resolveKey('', {
          'GEMINI_API_KEY': 'gemini-key',
          'GOOGLE_GENAI_API_KEY': 'google-key',
        }),
        'gemini-key',
      );
    });

    test('prefers GEMINI_API_KEY over GOOGLE_GENAI_API_KEY', () {
      expect(
        resolveKey('', {
          'GOOGLE_GENAI_API_KEY': 'google-key',
          'GEMINI_API_KEY': 'gemini-key',
        }),
        'gemini-key',
      );
    });

    test('falls back to GOOGLE_GENAI_API_KEY', () {
      expect(
        resolveKey('', {
          'GOOGLE_GENAI_API_KEY': 'google-key',
        }),
        'google-key',
      );
    });

    test('throws StateError when all sources are empty', () {
      expect(
        () => resolveKey('', {}),
        throwsA(isA<StateError>()),
      );
    });

    test('throws StateError when values are present but empty', () {
      expect(
        () => resolveKey('', {
          'GEMINI_API_KEY': '',
          'GOOGLE_GENAI_API_KEY': '',
        }),
        throwsA(isA<StateError>()),
      );
    });
  });
}