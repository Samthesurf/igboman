import 'tutor_service.dart';

/// Builds the system prompt that shapes Ada, the Igbo tutor persona.
///
/// Pure function: no I/O, no randomness, deterministic output for a given
/// context.
String buildSystemPrompt(TutorContext ctx) {
  final buffer = StringBuffer()
    ..writeln(
      'You are Ada, a warm and patient Igbo tutor for an English-speaking '
      'adult learner named ${ctx.learnerName}.',
    )
    ..writeln(
      'Speak mainly in Igbo at the learner\'s level, using standard Igbo '
      '(Igbo Izugbe).',
    )
    ..writeln('Use short sentences.')
    ..writeln(
      'Use ONLY words from the available vocabulary below, plus simple '
      'connectors.',
    )
    ..writeln(
      'If the learner writes in English, give the Igbo version and correct '
      'them gently.',
    )
    ..writeln('Ask only ONE question at a time.')
    ..writeln(
      'Never deliver a lecture. Keep the conversation playful and '
      'encouraging.',
    )
    ..writeln(
      'When the learner makes an error, show the corrected form and ask '
      'them to repeat it.',
    )
    ..writeln(
      'When closing a session, list the new words used in the conversation.',
    )
    ..writeln()
    ..writeln('The learner has completed ${ctx.completedUnits} unit(s) so far.')
    ..writeln()
    ..writeln('Available vocabulary (igbo: english):');
  for (final entry in ctx.whitelistVocab) {
    buffer.writeln('${entry.igbo}: ${entry.en}');
  }
  final story = ctx.storyContext;
  if (story != null && story.trim().isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('Talk about the story given below.')
      ..writeln('Ask 2-3 simple questions about it and stay on topic.')
      ..writeln('Quote the story text at the end of your reply.')
      ..writeln()
      ..writeln('Story:')
      ..writeln(story.trim());
  }
  return buffer.toString();
}

/// Keeps the last [maxTurns] turns, dropping oldest ones in user+tutor pairs
/// so the kept window starts on a learner turn. Order is preserved.
List<TutorTurn> trimHistory(
  List<TutorTurn> history, {
  int maxTurns = 12,
}) {
  if (history.isEmpty || maxTurns <= 0) {
    return const [];
  }
  var start = history.length - maxTurns;
  if (start < 0) {
    start = 0;
  }
  var trimmed = history.sublist(start);
  while (trimmed.isNotEmpty && trimmed.first.role != 'user') {
    trimmed = trimmed.sublist(1);
  }
  return trimmed;
}

/// Opens the session with a level-appropriate line from Ada.
///
/// Low levels get a short greeting plus one simple question; learners who
/// have completed more units get a richer welcome.
String buildSessionGreeting(TutorContext ctx) {
  final name = ctx.learnerName;
  if (ctx.completedUnits >= 5) {
    final story = ctx.storyContext;
    if (story != null && story.trim().isNotEmpty) {
      return 'Ndewo, $name! Kedu ka ị mere? I see you have come far. Biko, '
          'tell me what you remember from our story, then we will practise '
          'a little more Igbo together.';
    }
    return 'Ndewo, $name! Kedu ka ị mere? You have finished '
        '${ctx.completedUnits} units, so let us have a real chat in Igbo '
        'today. Biko, what did you learn last time?';
  }
  return 'Ndewo, $name! Kedu ka ị mere? Biko, let us start with one simple '
      'question and answer it together.';
}