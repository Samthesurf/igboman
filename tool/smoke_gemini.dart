// Live smoke test for the Gemini tutor service.
//
// Uses the resolved API key (dart-define, GEMINI_API_KEY, GOOGLE_GENAI_API_KEY)
// and prints ONLY the tutor's reply. The key itself is never printed.
//
// Usage: GEMINI_API_KEY=... dart run tool/smoke_gemini.dart
import 'dart:io';

import 'package:igboman/models/unit.dart';
import 'package:igboman/services/gemini_tutor_service.dart';
import 'package:igboman/services/tutor_service.dart';

Future<void> main() async {
  final service = GeminiTutorService();
  final context = TutorContext(
    learnerName: 'smoke test user',
    completedUnits: 3,
    whitelistVocab: const [
      VocabEntry(igbo: 'ndewo', en: 'hello'),
      VocabEntry(igbo: 'kedu ka ị mere', en: 'how are you'),
      VocabEntry(igbo: 'ọ dị mma', en: 'it is fine'),
      VocabEntry(igbo: 'daalụ', en: 'thank you'),
      VocabEntry(igbo: 'biko', en: 'please'),
      VocabEntry(igbo: 'nna', en: 'father'),
      VocabEntry(igbo: 'nne', en: 'mother'),
      VocabEntry(igbo: 'ụtụtụ ọma', en: 'good morning'),
      VocabEntry(igbo: 'ehihie ọma', en: 'good afternoon'),
      VocabEntry(igbo: 'abalị ọma', en: 'good night'),
      VocabEntry(igbo: 'ka ọ dị', en: 'goodbye'),
      VocabEntry(igbo: 'aha', en: 'name'),
      VocabEntry(igbo: 'otu', en: 'one'),
      VocabEntry(igbo: 'abụọ', en: 'two'),
      VocabEntry(igbo: 'atọ', en: 'three'),
    ],
  );

  final buffer = StringBuffer();
  try {
    await for (final chunk in service.chat(
      history: const [
        TutorTurn(role: 'user', text: 'Ndewo! Biko, kedu ka ị mere?'),
      ],
      context: context,
    )) {
      buffer.write(chunk);
    }
  } on TutorException catch (e) {
    stderr.writeln('TutorException: ${e.userMessage}');
    exit(1);
  } finally {
    service.dispose();
  }

  final reply = buffer.toString().trim();
  if (reply.isEmpty) {
    stderr.writeln('Empty tutor reply: smoke FAILED');
    exit(1);
  }
  stdout.writeln('ADA: $reply');
  stdout.writeln('Smoke OK: ${reply.length} chars');
}