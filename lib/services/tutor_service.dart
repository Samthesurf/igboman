import '../models/unit.dart';

/// One message in the tutor conversation.
class TutorTurn {
  /// Either 'user' or 'tutor'.
  final String role;

  final String text;

  const TutorTurn({required this.role, required this.text});
}

/// Everything the tutor needs to know about the learner and session.
class TutorContext {
  /// The learner's name.
  final String learnerName;

  /// Number of curriculum units the learner has completed.
  final int completedUnits;

  /// Vocabulary the tutor may use, from the learner's units so far.
  final List<VocabEntry> whitelistVocab;

  /// Optional story context to discuss during the session.
  final String? storyContext;

  const TutorContext({
    required this.learnerName,
    required this.completedUnits,
    required this.whitelistVocab,
    this.storyContext,
  });
}

/// A friendly, user-facing failure from the tutor.
class TutorException implements Exception {
  /// Message safe to show to the learner as-is.
  final String userMessage;

  const TutorException(this.userMessage);

  @override
  String toString() => userMessage;
}

/// Contract for any tutor implementation.
abstract class TutorService {
  /// Streams the tutor's reply for [history] plus the given [context].
  Stream<String> chat({
    required List<TutorTurn> history,
    required TutorContext context,
  });

  /// Releases any underlying resources.
  void dispose();
}