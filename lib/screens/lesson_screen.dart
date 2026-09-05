import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson.dart';
import '../models/question_result.dart';
import '../services/answer_checker.dart';
import '../services/audio_service.dart';
import '../services/lesson_intro.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../widgets/avatar_view.dart';
import '../widgets/coach_comment.dart';
import '../widgets/content_box.dart';
import '../widgets/diacritic_bar.dart';
import '../widgets/flat_button.dart';
import '../widgets/prop_spot.dart';
import '../widgets/streak_celebration.dart';

// ---------------------------------------------------------------------------
// LessonScreen entry point
// ---------------------------------------------------------------------------

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _questionIndex = 0;
  int _earnedXp = 0;
  int _comboCount = 0;
  bool _hadMistake = false;
  bool _isReplay = false;
  bool _showIntro = true;

  /// One record per answered question, shown on the review screen.
  final List<QuestionResult> _results = [];

  /// The teach phase, derived from the lesson's own content (see
  /// lib/services/lesson_intro.dart). Lessons flagged skipIntro (unit
  /// quizzes) never show it.
  LessonIntro? _intro;

  @override
  void initState() {
    super.initState();
    if (!widget.lesson.skipIntro) {
      _intro = buildLessonIntroForLesson(widget.lesson);
      // Lesson content that yields neither words nor examples has nothing
      // to teach; jump straight to the questions.
      if (_intro!.words.isEmpty && _intro!.examples.isEmpty) {
        _intro = null;
      }
    }
    _showIntro = _intro != null;
  }

  void _onQuestionDone(
    int xpEarned,
    int newCombo,
    bool hadMistake,
    QuestionResult result,
  ) {
    setState(() {
      _earnedXp += xpEarned;
      _comboCount = newCombo;
      if (hadMistake) {
        _hadMistake = true;
      }
      _results.add(result);
      _questionIndex++;
    });
  }

  Future<void> _onLessonComplete(BuildContext context) async {
    final appState = context.read<AppState>();
    final alreadyDone = appState.isLessonCompleted(widget.lesson.id);
    if (!_isReplay && !alreadyDone) {
      // award per-question XP first, then completion bonus via completeLesson
      await appState.awardXp(_earnedXp);
      await appState.completeLesson(widget.lesson.id);
    }
  }

  void _restartLesson() {
    setState(() {
      _questionIndex = 0;
      _earnedXp = 0;
      _comboCount = 0;
      _hadMistake = false;
      _isReplay = true;
      _results.clear();
      // Practice again is a re-test: skip the teach phase.
      _showIntro = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.lesson.questions;
    final isComplete = _questionIndex >= questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _LessonAppBar(
        title: widget.lesson.title,
        questionNumber: isComplete ? questions.length : (_questionIndex + 1),
        totalQuestions: questions.length,
        progress: isComplete
            ? 1.0
            : questions.isEmpty
            ? 1.0
            : _questionIndex / questions.length,
      ),
      body: isComplete
          ? _CompletionScreen(
              earnedXp: _earnedXp,
              lessonId: widget.lesson.id,
              onContinue: () => Navigator.of(context).pop(),
              onPracticeAgain: _restartLesson,
              onFirstCompletion: () => _onLessonComplete(context),
              isReplay: _isReplay,
              isPerfect: !_hadMistake,
              results: List.of(_results),
            )
          : _showIntro
          ? _LessonIntroView(
              intro: _intro!,
              onStart: () => setState(() => _showIntro = false),
            )
          : _QuestionEntrance(
              key: const Key('runQuestionEntrance'),
              child: _QuestionPage(
                key: ValueKey('q_${_questionIndex}_${widget.lesson.id}'),
                question: questions[_questionIndex],
                questionNumber: _questionIndex + 1,
                totalQuestions: questions.length,
                isReplay: _isReplay,
                initialCombo: _comboCount,
                onDone: _onQuestionDone,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Teach phase (lesson intro)
// ---------------------------------------------------------------------------

class _LessonIntroView extends StatelessWidget {
  const _LessonIntroView({required this.intro, required this.onStart});

  final LessonIntro intro;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ContentBox(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Study first',
              style: TextStyle(
                fontSize: TypeScale.bodySmall,
                color: AppColors.textSecondary,
                fontFamily: 'NotoSans',
              ),
            ),
            const SizedBox(height: Spacing.xs),
            const Text(
              'New words',
              style: TextStyle(
                fontSize: TypeScale.headline,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'NotoSans',
              ),
            ),
            const SizedBox(height: Spacing.s),
            const Text(
              'Tap the speaker to hear each one.',
              style: TextStyle(
                fontSize: TypeScale.bodySmall,
                color: AppColors.textSecondary,
                fontFamily: 'NotoSans',
              ),
            ),
            const SizedBox(height: Spacing.lg),
            for (final word in intro.words) _SpeakableRow(word: word),
            if (intro.examples.isNotEmpty) ...[
              const SizedBox(height: Spacing.lg),
              const Text(
                'Examples',
                style: TextStyle(
                  fontSize: TypeScale.headline,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoSans',
                ),
              ),
              const SizedBox(height: Spacing.s),
              for (final example in intro.examples)
                _ExampleRow(example: example),
            ],
            const SizedBox(height: Spacing.lg),
            FlatButton(
              key: const Key('lessonStartButton'),
              label: 'Start',
              enabled: true,
              color: AppColors.secondary,
              onTap: onStart,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeakableRow extends StatelessWidget {
  const _SpeakableRow({required this.word});

  final LessonIntroWord word;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.s),
      child: Row(
        children: [
          Expanded(
            child: Text(
              word.igbo,
              style: const TextStyle(
                fontSize: TypeScale.title,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'NotoSans',
              ),
            ),
          ),
          Text(
            word.en,
            style: const TextStyle(
              fontSize: TypeScale.body,
              color: AppColors.textSecondary,
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(width: Spacing.s),
          _SpeakButton(icon: Icons.volume_up, token: word.igbo),
        ],
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  const _ExampleRow({required this.example});

  final LessonIntroExample example;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.s),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.m,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    example.igbo,
                    style: const TextStyle(
                      fontSize: TypeScale.body,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    example.en,
                    style: const TextStyle(
                      fontSize: TypeScale.bodySmall,
                      color: AppColors.textSecondary,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ],
              ),
            ),
            _SpeakButton(icon: Icons.volume_up, token: example.igbo),
          ],
        ),
      ),
    );
  }
}

/// Speaker button that only appears when a bundled audio clip exists for
/// the token (see AudioService + assets/audio/manifest.json).
class _SpeakButton extends StatefulWidget {
  const _SpeakButton({required this.icon, required this.token});

  final IconData icon;
  final String token;

  @override
  State<_SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<_SpeakButton> {
  bool? _available;

  @override
  void initState() {
    super.initState();
    AudioService.hasAudio(widget.token).then((available) {
      if (mounted) setState(() => _available = available);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_available != true) return const SizedBox.shrink();
    return IconButton(
      key: Key('speak_${AudioService.tokenKey(widget.token)}'),
      onPressed: () => AudioService.play(widget.token),
      tooltip: 'Hear pronunciation',
      icon: Icon(widget.icon, size: IconSizes.md, color: AppColors.secondary),
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar with flat progress bar
// ---------------------------------------------------------------------------

class _LessonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _LessonAppBar({
    required this.title,
    required this.progress,
    this.questionNumber,
    this.totalQuestions,
  });

  final String title;
  final double progress;
  final int? questionNumber;
  final int? totalQuestions;

  @override
  Size get preferredSize => const Size.fromHeight(
    kToolbarHeight + ControlSizes.progressBarMd + Spacing.s,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: kToolbarHeight,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: AppColors.textPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: TypeScale.title,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'NotoSans',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (questionNumber != null &&
                    totalQuestions != null &&
                    totalQuestions! > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.s,
                      vertical: Spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warnBg,
                      borderRadius: BorderRadius.circular(Radii.chip),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      'Question $questionNumber of $totalQuestions',
                      style: const TextStyle(
                        fontSize: TypeScale.caption,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'NotoSans',
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: Spacing.md),
              ],
            ),
          ),
          _FlatProgressBar(progress: progress),
          const SizedBox(height: Spacing.s),
        ],
      ),
    );
  }
}

class _FlatProgressBar extends StatelessWidget {
  const _FlatProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth = (constraints.maxWidth * progress.clamp(0.0, 1.0));
          return Container(
            key: const Key('lessonRunTrack'),
            height: ControlSizes.progressBarMd,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(Radii.chip),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: kMedAnim,
                width: fillWidth,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(Radii.chip),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Question page dispatcher
// ---------------------------------------------------------------------------

/// One-shot micro-transition for each question: a short fade with a small
/// upward rise and a subtle settle from 0.97 scale, over 280ms ease-out.
/// Mirrors the vens-hub list micro-transition feel (fade plus a small rise,
/// no full-screen swoop). Only the question body animates: the lesson app
/// bar and the run progress bar live outside this widget in the Scaffold
/// and stay put while questions pass. Unlike an AnimatedSwitcher, the
/// outgoing page is never kept alive, so each action button exists exactly
/// once in the tree.
class _QuestionEntrance extends StatefulWidget {
  const _QuestionEntrance({super.key, required this.child});

  final Widget child;

  @override
  State<_QuestionEntrance> createState() => _QuestionEntranceState();
}

class _QuestionEntranceState extends State<_QuestionEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _rise;
  late final Animation<double> _fade;
  late final Animation<double> _settle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _rise = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(curve);
    _fade = curve;
    _settle = Tween<double>(begin: 0.97, end: 1).animate(curve);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _QuestionEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child.key != widget.child.key) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _rise,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(scale: _settle, child: widget.child),
      ),
    );
  }
}

class _QuestionPage extends StatefulWidget {
  const _QuestionPage({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.isReplay,
    required this.onDone,
    this.initialCombo = 0,
  });

  final LessonQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final bool isReplay;
  final void Function(
    int xpEarned,
    int newCombo,
    bool hadMistake,
    QuestionResult result,
  )
  onDone;
  final int initialCombo;

  @override
  State<_QuestionPage> createState() => _QuestionPageState();
}

enum _AnswerState { idle, correct, correctToneNote, wrong }

class _QuestionPageState extends State<_QuestionPage>
    with SingleTickerProviderStateMixin {
  _AnswerState _answerState = _AnswerState.idle;
  late AnimationController _animController;
  late Animation<double> _shakeAnim;

  // Per-type state
  String? _selectedOption; // MCQ
  String? _correctOption; // MCQ correct reveal
  List<_PairAttempt> _pairAttempts = []; // matchPairs
  String? _selectedLeft; // matchPairs pending
  List<String> _filledSlots = []; // fillBlank
  final _translateController = TextEditingController(); // translate

  int _currentCombo = 0;
  bool _hadMistake = false;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _currentCombo = widget.initialCombo;
    _animController = AnimationController(vsync: this, duration: kFastAnim);
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 25),
    ]).animate(_animController);

    // Rebuild when translate text changes so _canConfirm updates
    _translateController.addListener(_onTranslateTextChanged);

    if (widget.question.type == QuestionType.matchPairs) {
      _pairAttempts = widget.question.pairs
          .map((p) => _PairAttempt(left: p.left, correctRight: p.right))
          .toList();
    }
    if (widget.question.type == QuestionType.fillBlank) {
      _filledSlots = [];
    }
  }

  void _onTranslateTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _translateController.removeListener(_onTranslateTextChanged);
    _animController.dispose();
    _translateController.dispose();
    super.dispose();
  }

  bool get _canConfirm {
    switch (widget.question.type) {
      case QuestionType.mcqIgboToEnglish:
      case QuestionType.mcqEnglishToIgbo:
        return _selectedOption != null && _answerState == _AnswerState.idle;
      case QuestionType.matchPairs:
        return false; // auto-confirms per pair
      case QuestionType.fillBlank:
        return _filledSlots.isNotEmpty && _answerState == _AnswerState.idle;
      case QuestionType.translate:
        return _translateController.text.trim().isNotEmpty &&
            _answerState == _AnswerState.idle;
    }
  }

  void _confirm() {
    final q = widget.question;
    AnswerCheckResult result;

    switch (q.type) {
      case QuestionType.mcqIgboToEnglish:
      case QuestionType.mcqEnglishToIgbo:
        final correct =
            _selectedOption == q.answer ||
            (q.acceptedAnswers.isNotEmpty &&
                q.acceptedAnswers.contains(_selectedOption));
        result = AnswerCheckResult(correct: correct);
        if (!correct) {
          _correctOption = q.answer ?? q.acceptedAnswers.firstOrNull;
        }
      case QuestionType.fillBlank:
        final userAnswer = _filledSlots.join(' ');
        final accepted = q.acceptedAnswers.isNotEmpty
            ? q.acceptedAnswers
            : (q.answer != null ? [q.answer!] : <String>[]);
        result = AnswerChecker.check(
          userInput: userAnswer,
          acceptedAnswers: accepted,
          toneLenient: q.toneLenient,
        );
      case QuestionType.translate:
        final accepted = q.acceptedAnswers.isNotEmpty
            ? q.acceptedAnswers
            : (q.answer != null ? [q.answer!] : <String>[]);
        result = AnswerChecker.check(
          userInput: _translateController.text,
          acceptedAnswers: accepted,
          toneLenient: q.toneLenient,
        );
      case QuestionType.matchPairs:
        return; // handled per-pair
    }

    _applyResult(result);
  }

  void _applyResult(AnswerCheckResult result) {
    if (result.correct) {
      _currentCombo = widget.initialCombo + 1;
      setState(() {
        _answerState = result.toneNote
            ? _AnswerState.correctToneNote
            : _AnswerState.correct;
      });
      _animController.forward(from: 0);
    } else {
      _currentCombo = 0;
      _hadMistake = true;
      setState(() {
        _answerState = _AnswerState.wrong;
      });
      _animController.forward(from: 0);
    }
  }

  int _computeXp() {
    if (widget.isReplay) return 0;
    switch (_answerState) {
      case _AnswerState.correct:
        return 10;
      case _AnswerState.correctToneNote:
        return 5;
      default:
        return 0;
    }
  }

  void _continue() {
    widget.onDone(_computeXp(), _currentCombo, _hadMistake, _buildResult());
  }

  /// Summarises this question for the end-of-lesson review screen.
  QuestionResult _buildResult() {
    final q = widget.question;
    final correct =
        _answerState == _AnswerState.correct ||
        _answerState == _AnswerState.correctToneNote;
    switch (q.type) {
      case QuestionType.mcqIgboToEnglish:
      case QuestionType.mcqEnglishToIgbo:
        return QuestionResult(
          prompt: q.prompt,
          userAnswer: _selectedOption ?? '',
          correctAnswer: q.answer ?? q.acceptedAnswers.firstOrNull ?? '',
          isCorrect: correct,
        );
      case QuestionType.fillBlank:
        return QuestionResult(
          prompt: q.prompt,
          userAnswer: _filledSlots.join(' '),
          correctAnswer: q.answer ?? q.acceptedAnswers.firstOrNull ?? '',
          isCorrect: correct,
        );
      case QuestionType.translate:
        return QuestionResult(
          prompt: q.prompt,
          userAnswer: _translateController.text.trim(),
          correctAnswer: q.answer ?? q.acceptedAnswers.firstOrNull ?? '',
          isCorrect: correct,
        );
      case QuestionType.matchPairs:
        final matched = _pairAttempts.where((p) => p.matched).length;
        final total = _pairAttempts.length;
        return QuestionResult(
          prompt: q.prompt,
          userAnswer: matched == total
              ? 'All pairs matched'
              : '$matched of $total pairs matched',
          correctAnswer: q.pairs
              .map((p) => '${p.left} = ${p.right}')
              .join(', '),
          isCorrect: correct,
        );
    }
  }

  // matchPairs pair tap handler
  void _tapLeft(String left) {
    if (_answerState != _AnswerState.idle) return;
    setState(() {
      _selectedLeft = left;
    });
  }

  void _tapRight(String right) {
    if (_answerState != _AnswerState.idle) return;
    final left = _selectedLeft;
    if (left == null) return;

    final attempt = _pairAttempts.firstWhere(
      (p) => p.left == left,
      orElse: () => _PairAttempt(left: '', correctRight: ''),
    );
    if (attempt.left.isEmpty) return;

    if (attempt.correctRight == right) {
      setState(() {
        attempt.matched = true;
        _selectedLeft = null;
      });
      // Check if all matched
      if (_pairAttempts.every((p) => p.matched)) {
        _currentCombo = widget.initialCombo + 1;
        setState(() => _answerState = _AnswerState.correct);
        _animController.forward(from: 0);
      }
    } else {
      // Wrong pair: shake and deselect
      _currentCombo = 0;
      _hadMistake = true;
      setState(() {
        attempt.shaking = true;
        _selectedLeft = null;
      });
      _animController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            attempt.shaking = false;
          });
        }
      });
    }
  }

  // fillBlank
  void _tapChip(String word) {
    if (_answerState != _AnswerState.idle) return;
    setState(() {
      _filledSlots.add(word);
    });
  }

  void _tapBlank() {
    if (_answerState != _AnswerState.idle) return;
    if (_filledSlots.isEmpty) return;
    setState(() {
      _filledSlots.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect =
        _answerState == _AnswerState.correct ||
        _answerState == _AnswerState.correctToneNote;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final offsetX = _answerState == _AnswerState.wrong
            ? _shakeAnim.value
            : 0.0;

        return Transform.translate(offset: Offset(offsetX, 0), child: child);
      },
      child: _buildBody(isCorrect),
    );
  }

  Widget _buildBody(bool isCorrect) {
    return Column(
      children: [
        _buildMomentumHud(),
        Expanded(
          child: ContentBox(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestionContent(),
                  if (_answerState == _AnswerState.idle) ...[
                    const SizedBox(height: Spacing.md),
                    _buildHintSection(),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (_answerState != _AnswerState.idle) _buildFeedbackStrip(isCorrect),
        if (_answerState == _AnswerState.idle &&
            widget.question.type != QuestionType.matchPairs)
          _buildConfirmBar(),
        if (isCorrect || _answerState == _AnswerState.wrong)
          _buildContinueBar(isCorrect),
      ],
    );
  }

  /// Persistent run HUD: question position plus live combo heat. The combo
  /// copy deliberately avoids the "Combo xN" wording used by the feedback
  /// strip badge so each surface keeps a single, testable claim.
  Widget _buildMomentumHud() {
    final combo = _currentCombo;
    return Container(
      key: const Key('runMomentumBadge'),
      margin: const EdgeInsets.only(
        left: Spacing.md,
        right: Spacing.md,
        top: Spacing.s,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.m,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.warnBg, AppColors.successBg],
        ),
        borderRadius: BorderRadius.circular(Radii.chip),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_run,
            size: IconSizes.s,
            color: AppColors.primary,
          ),
          const SizedBox(width: Spacing.xs),
          Text(
            'Q${widget.questionNumber} of ${widget.totalQuestions}',
            style: const TextStyle(
              fontSize: TypeScale.caption,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontFamily: 'NotoSans',
            ),
          ),
          const Spacer(),
          if (combo > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.s,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: IconSizes.s,
                    color: AppColors.onPrimary,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    'Heat x$combo',
                    style: const TextStyle(
                      fontSize: TypeScale.caption,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimary,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ],
              ),
            )
          else
            const Text(
              'Build a combo!',
              style: TextStyle(
                fontSize: TypeScale.caption,
                color: AppColors.textSecondary,
                fontFamily: 'NotoSans',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHintSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_showHint)
          GestureDetector(
            key: const Key('hintButton'),
            onTap: () => setState(() => _showHint = true),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.m,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.warnBg,
                borderRadius: BorderRadius.circular(Radii.chip),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: IconSizes.s,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: Spacing.xs),
                  Text(
                    'Hint',
                    style: TextStyle(
                      fontSize: TypeScale.caption,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_showHint)
          Container(
            key: const Key('hintCard'),
            width: double.infinity,
            padding: const EdgeInsets.all(Spacing.m),
            decoration: BoxDecoration(
              color: AppColors.warnBg,
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: AppColors.primary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: IconSizes.s,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: Spacing.xs),
                    const Text(
                      'Hint',
                      style: TextStyle(
                        fontSize: TypeScale.caption,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'NotoSans',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      key: const Key('hintDismissButton'),
                      icon: const Icon(Icons.close, size: IconSizes.s),
                      color: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      onPressed: () => setState(() => _showHint = false),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  widget.question.hint ?? _getContextualHint(widget.question),
                  style: const TextStyle(
                    fontSize: TypeScale.bodySmall,
                    color: AppColors.textPrimary,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getContextualHint(LessonQuestion q) {
    switch (q.type) {
      case QuestionType.translate:
        return 'Pay attention to tone marks and sentence word order.';
      case QuestionType.fillBlank:
        return 'Consider which word logically completes the sentence.';
      case QuestionType.matchPairs:
        return 'Look for cognates and familiar vocabulary roots.';
      case QuestionType.mcqIgboToEnglish:
      case QuestionType.mcqEnglishToIgbo:
        return 'Look closely at the Igbo root word.';
    }
  }

  Widget _buildQuestionContent() {
    switch (widget.question.type) {
      case QuestionType.mcqIgboToEnglish:
      case QuestionType.mcqEnglishToIgbo:
        return _McqView(
          question: widget.question,
          selectedOption: _selectedOption,
          correctOption: _correctOption,
          answerState: _answerState,
          onSelect: (opt) {
            if (_answerState == _AnswerState.idle) {
              setState(() => _selectedOption = opt);
            }
          },
        );
      case QuestionType.matchPairs:
        return _MatchPairsView(
          question: widget.question,
          pairAttempts: _pairAttempts,
          selectedLeft: _selectedLeft,
          shakeAnim: _shakeAnim,
          animController: _animController,
          onTapLeft: _tapLeft,
          onTapRight: _tapRight,
        );
      case QuestionType.fillBlank:
        return _FillBlankView(
          question: widget.question,
          filledSlots: _filledSlots,
          answerState: _answerState,
          onTapChip: _tapChip,
          onTapBlank: _tapBlank,
        );
      case QuestionType.translate:
        return _TranslateView(
          question: widget.question,
          controller: _translateController,
          answerState: _answerState,
        );
    }
  }

  Widget _buildConfirmBar() {
    return ContentBox(
      child: Padding(
        padding: const EdgeInsets.only(top: Spacing.s, bottom: Spacing.md),
        child: FlatButton(
          label: 'Check',
          enabled: _canConfirm,
          color: AppColors.secondary,
          onTap: _canConfirm ? _confirm : null,
        ),
      ),
    );
  }

  Widget _buildFeedbackStrip(bool isCorrect) {
    final isToneNote = _answerState == _AnswerState.correctToneNote;
    return Container(
      width: double.infinity,
      color: isCorrect ? AppColors.successBg : AppColors.error.withAlpha(30),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.s,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarView(
                assetPath: isCorrect ? 'assets/images/ada.jpg' : null,
                size: AvatarSizes.card,
              ),
              const SizedBox(width: Spacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          isCorrect ? 'Correct!' : 'Not quite',
                          style: TextStyle(
                            fontSize: TypeScale.body,
                            fontWeight: FontWeight.bold,
                            color: isCorrect
                                ? AppColors.secondary
                                : AppColors.error,
                            fontFamily: 'NotoSans',
                          ),
                        ),
                        if (isCorrect && _currentCombo > 0) ...[
                          const SizedBox(width: Spacing.s),
                          Container(
                            key: const Key('runComboBadge'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.s,
                              vertical: Spacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warnBg,
                              borderRadius: BorderRadius.circular(Radii.chip),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Text(
                              'Combo x$_currentCombo',
                              style: const TextStyle(
                                fontSize: TypeScale.caption,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontFamily: 'NotoSans',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isToneNote)
                      const Text(
                        'Watch the tone marks',
                        style: TextStyle(
                          fontSize: TypeScale.bodySmall,
                          color: AppColors.textSecondary,
                          fontFamily: 'NotoSans',
                        ),
                      ),
                    if (!isCorrect && _correctOption != null)
                      Text(
                        'Answer: $_correctOption',
                        style: const TextStyle(
                          fontSize: TypeScale.bodySmall,
                          color: AppColors.textSecondary,
                          fontFamily: 'NotoSans',
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                isCorrect ? Icons.check_circle_outline : Icons.close,
                color: isCorrect ? AppColors.secondary : AppColors.error,
                size: IconSizes.lg,
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Container(
            key: const Key('answerExplanation'),
            width: double.infinity,
            padding: const EdgeInsets.all(Spacing.s),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Radii.chip),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              _getExplanation(widget.question, isCorrect),
              style: const TextStyle(
                fontSize: TypeScale.caption,
                color: AppColors.textSecondary,
                fontFamily: 'NotoSans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getExplanation(LessonQuestion q, bool isCorrect) {
    if (isCorrect && q.explanation != null) {
      return q.explanation!;
    }
    if (isCorrect) {
      switch (q.type) {
        case QuestionType.mcqIgboToEnglish:
        case QuestionType.mcqEnglishToIgbo:
          final ans = q.answer ?? _selectedOption ?? 'this option';
          return '$ans is the correct translation.';
        case QuestionType.translate:
          return 'Great translation! You captured the right meaning and tone marks.';
        case QuestionType.fillBlank:
          final ans = q.answer ?? '';
          return '$ans completes the phrase accurately.';
        case QuestionType.matchPairs:
          return 'All vocabulary pairs matched correctly.';
      }
    } else {
      final ans =
          _correctOption ??
          q.answer ??
          (q.acceptedAnswers.isNotEmpty ? q.acceptedAnswers.first : '');
      if (q.explanation != null) {
        return 'The correct answer is $ans. ${q.explanation!}';
      }
      switch (q.type) {
        case QuestionType.mcqIgboToEnglish:
        case QuestionType.mcqEnglishToIgbo:
          return 'The correct answer is $ans. Notice the syllable structure and tones.';
        case QuestionType.translate:
          return 'Expected: $ans. Pay attention to diacritics and vowels.';
        case QuestionType.fillBlank:
          return 'The sentence requires $ans. Check the surrounding context.';
        case QuestionType.matchPairs:
          return 'Review the vocabulary pairs to reinforce the connections.';
      }
    }
  }

  Widget _buildContinueBar(bool isCorrect) {
    return ContentBox(
      child: Padding(
        padding: const EdgeInsets.only(top: Spacing.s, bottom: Spacing.md),
        child: FlatButton(
          label: 'Continue',
          enabled: true,
          color: isCorrect ? AppColors.secondary : AppColors.primary,
          onTap: _continue,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MCQ view
// ---------------------------------------------------------------------------

class _McqView extends StatelessWidget {
  const _McqView({
    required this.question,
    required this.selectedOption,
    required this.correctOption,
    required this.answerState,
    required this.onSelect,
  });

  final LessonQuestion question;
  final String? selectedOption;
  final String? correctOption;
  final _AnswerState answerState;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.prompt,
          style: const TextStyle(
            fontSize: TypeScale.title,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'NotoSans',
          ),
        ),
        const SizedBox(height: Spacing.lg),
        ...question.options.map((opt) {
          final isSelected = selectedOption == opt;
          final isCorrectReveal = correctOption == opt;
          final isWrong = answerState == _AnswerState.wrong && isSelected;

          Color borderColor = AppColors.cardBorder;
          Color bgColor = AppColors.surface;
          Color textColor = AppColors.textPrimary;
          Widget? trailingIcon;

          if (answerState != _AnswerState.idle) {
            if (isCorrectReveal ||
                (isSelected &&
                    (answerState == _AnswerState.correct ||
                        answerState == _AnswerState.correctToneNote))) {
              borderColor = AppColors.secondary;
              bgColor = AppColors.successBg;
              textColor = AppColors.secondary;
              trailingIcon = const Icon(
                Icons.check,
                color: AppColors.secondary,
                size: IconSizes.md,
              );
            } else if (isWrong) {
              borderColor = AppColors.error;
              bgColor = AppColors.error.withAlpha(20);
              textColor = AppColors.error;
            }
          } else if (isSelected) {
            borderColor = AppColors.primary;
            bgColor = AppColors.warnBg;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.s),
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.m,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(Radii.card),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: TypeScale.body,
                          color: textColor,
                          fontFamily: 'NotoSans',
                        ),
                      ),
                    ),
                    ?trailingIcon,
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Match pairs
// ---------------------------------------------------------------------------

class _PairAttempt {
  final String left;
  final String correctRight;
  bool matched = false;
  bool shaking = false;

  _PairAttempt({required this.left, required this.correctRight});
}

class _MatchPairsView extends StatelessWidget {
  const _MatchPairsView({
    required this.question,
    required this.pairAttempts,
    required this.selectedLeft,
    required this.shakeAnim,
    required this.animController,
    required this.onTapLeft,
    required this.onTapRight,
  });

  final LessonQuestion question;
  final List<_PairAttempt> pairAttempts;
  final String? selectedLeft;
  final Animation<double> shakeAnim;
  final AnimationController animController;
  final void Function(String) onTapLeft;
  final void Function(String) onTapRight;

  @override
  Widget build(BuildContext context) {
    // Build shuffled right column (deterministic based on question id)
    final rights = pairAttempts.map((p) => p.correctRight).toList();
    final shuffled = List<String>.from(rights)
      ..sort((a, b) => a.hashCode.compareTo(b.hashCode));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.prompt,
          style: const TextStyle(
            fontSize: TypeScale.title,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'NotoSans',
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: pairAttempts.map((attempt) {
                  final isSelected = selectedLeft == attempt.left;
                  final isMatched = attempt.matched;

                  Color bgColor = AppColors.surface;
                  Color borderColor = AppColors.cardBorder;
                  Color textColor = AppColors.textPrimary;

                  if (isMatched) {
                    bgColor = AppColors.successBg;
                    borderColor = AppColors.secondary;
                    textColor = AppColors.secondary;
                  } else if (isSelected) {
                    bgColor = AppColors.warnBg;
                    borderColor = AppColors.primary;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.s),
                    child: GestureDetector(
                      onTap: isMatched ? null : () => onTapLeft(attempt.left),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(Spacing.s),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(Radii.card),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                attempt.left,
                                style: TextStyle(
                                  fontSize: TypeScale.body,
                                  color: textColor,
                                  fontFamily: 'NotoSans',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (isMatched)
                              const Icon(
                                Icons.check,
                                color: AppColors.secondary,
                                size: IconSizes.s,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: Spacing.s),
            Expanded(
              child: Column(
                children: shuffled.map((right) {
                  final attempt = pairAttempts.firstWhere(
                    (p) => p.correctRight == right,
                    orElse: () => _PairAttempt(left: '', correctRight: right),
                  );
                  final isMatched = attempt.matched;
                  final isShaking = attempt.shaking;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.s),
                    child: AnimatedBuilder(
                      animation: animController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(isShaking ? shakeAnim.value : 0.0, 0),
                          child: child,
                        );
                      },
                      child: GestureDetector(
                        onTap: isMatched ? null : () => onTapRight(right),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(Spacing.s),
                          decoration: BoxDecoration(
                            color: isMatched
                                ? AppColors.successBg
                                : isShaking
                                ? AppColors.error.withAlpha(20)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(Radii.card),
                            border: Border.all(
                              color: isMatched
                                  ? AppColors.secondary
                                  : isShaking
                                  ? AppColors.error
                                  : AppColors.cardBorder,
                            ),
                          ),
                          child: Text(
                            right,
                            style: TextStyle(
                              fontSize: TypeScale.body,
                              color: isMatched
                                  ? AppColors.secondary
                                  : isShaking
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                              fontFamily: 'NotoSans',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Fill blank
// ---------------------------------------------------------------------------

class _FillBlankView extends StatelessWidget {
  const _FillBlankView({
    required this.question,
    required this.filledSlots,
    required this.answerState,
    required this.onTapChip,
    required this.onTapBlank,
  });

  final LessonQuestion question;
  final List<String> filledSlots;
  final _AnswerState answerState;
  final void Function(String) onTapChip;
  final void Function() onTapBlank;

  @override
  Widget build(BuildContext context) {
    final parts = question.prompt.split('___');
    final filledText = filledSlots.isEmpty ? '' : filledSlots.join(' ');

    final isCorrect =
        answerState == _AnswerState.correct ||
        answerState == _AnswerState.correctToneNote;
    final isWrong = answerState == _AnswerState.wrong;

    Color blankColor = AppColors.cardBorder;
    if (isCorrect) blankColor = AppColors.secondary;
    if (isWrong) blankColor = AppColors.error;

    // Build remaining word bank
    final usedWords = List<String>.from(filledSlots);
    final availableChips = List<String>.from(question.wordBank);
    for (final w in usedWords) {
      availableChips.remove(w);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (int i = 0; i < parts.length; i++) ...[
              Text(
                parts[i],
                style: const TextStyle(
                  fontSize: TypeScale.body,
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoSans',
                ),
              ),
              if (i < parts.length - 1)
                GestureDetector(
                  onTap: answerState == _AnswerState.idle ? onTapBlank : null,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 80),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.s,
                      vertical: Spacing.xs,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: blankColor, width: 2),
                      ),
                      color: isCorrect
                          ? AppColors.successBg
                          : isWrong
                          ? AppColors.error.withAlpha(20)
                          : Colors.transparent,
                    ),
                    child: Text(
                      filledText.isEmpty ? '     ' : filledText,
                      style: TextStyle(
                        fontSize: TypeScale.body,
                        color: isCorrect
                            ? AppColors.secondary
                            : isWrong
                            ? AppColors.error
                            : AppColors.textPrimary,
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: Spacing.xl),
        Wrap(
          spacing: Spacing.s,
          runSpacing: Spacing.s,
          children: availableChips.map((word) {
            return GestureDetector(
              onTap: () => onTapChip(word),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.m,
                  vertical: Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(Radii.chip),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  word,
                  style: const TextStyle(
                    fontSize: TypeScale.body,
                    color: AppColors.textPrimary,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Translate view
// ---------------------------------------------------------------------------

class _TranslateView extends StatelessWidget {
  const _TranslateView({
    required this.question,
    required this.controller,
    required this.answerState,
  });

  final LessonQuestion question;
  final TextEditingController controller;
  final _AnswerState answerState;

  @override
  Widget build(BuildContext context) {
    final isEnabled = answerState == _AnswerState.idle;
    final isCorrect =
        answerState == _AnswerState.correct ||
        answerState == _AnswerState.correctToneNote;
    final isWrong = answerState == _AnswerState.wrong;

    Color borderColor = AppColors.cardBorder;
    if (isCorrect) borderColor = AppColors.secondary;
    if (isWrong) borderColor = AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Translate this sentence',
          style: TextStyle(
            fontSize: TypeScale.bodySmall,
            color: AppColors.textSecondary,
            fontFamily: 'NotoSans',
          ),
        ),
        const SizedBox(height: Spacing.s),
        Text(
          question.prompt,
          style: const TextStyle(
            fontSize: TypeScale.title,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'NotoSans',
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            enabled: isEnabled,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            minLines: 3,
            style: const TextStyle(
              fontSize: TypeScale.body,
              color: AppColors.textPrimary,
              fontFamily: 'NotoSans',
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(Spacing.md),
              border: InputBorder.none,
              hintText: 'Type your answer...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'NotoSans',
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.s),
        DiacriticBar(controller: controller),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Completion screen
// ---------------------------------------------------------------------------

class _CompletionScreen extends StatefulWidget {
  const _CompletionScreen({
    required this.earnedXp,
    required this.lessonId,
    required this.onContinue,
    required this.onPracticeAgain,
    required this.onFirstCompletion,
    required this.isReplay,
    required this.results,
    this.isPerfect = true,
  });

  final int earnedXp;
  final String lessonId;
  final VoidCallback onContinue;
  final VoidCallback onPracticeAgain;
  final Future<void> Function() onFirstCompletion;
  final bool isReplay;
  final bool isPerfect;

  /// One record per answered question, shown on the review screen.
  final List<QuestionResult> results;

  @override
  State<_CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<_CompletionScreen> {
  bool _completionReported = false;

  /// The roster character reacting to this run, picked once so the comment
  /// and its streaming text stay stable across rebuilds.
  late final CoachComment _comment = pickCoachComment(
    correct: widget.results.where((r) => r.isCorrect).length,
    total: widget.results.length,
  );

  @override
  void initState() {
    super.initState();
    // Report completion once on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_completionReported && mounted) {
        _completionReported = true;
        final appState = context.read<AppState>();
        final wasRestored = isStreakRestored(
          lastActiveDay: appState.progress.lastActiveDay,
          now: DateTime.now(),
        );
        widget.onFirstCompletion();
        if (wasRestored && mounted) {
          showStreakCelebration(
            context,
            streakDays: appState.streakDays,
            isRestored: true,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final totalXp = appState.xp;
    final streakDays = appState.streakDays;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ControlSizes.contentMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ada avatar + Excellent! header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AvatarView(
                        assetPath: 'assets/images/ada.jpg',
                        size: AvatarSizes.chat,
                      ),
                      const SizedBox(width: Spacing.m),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Excellent!',
                            style: TextStyle(
                              fontSize: TypeScale.title,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'NotoSans',
                            ),
                          ),
                          if (!widget.isReplay)
                            TweenAnimationBuilder<int>(
                              tween: IntTween(begin: 0, end: totalXp),
                              duration: kMedAnim,
                              builder: (context, value, child) {
                                return Text(
                                  '$value XP',
                                  style: const TextStyle(
                                    fontSize: TypeScale.body,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                    fontFamily: 'NotoSans',
                                  ),
                                );
                              },
                            ),
                          if (widget.isReplay)
                            const Text(
                              'Practice complete',
                              style: TextStyle(
                                fontSize: TypeScale.bodySmall,
                                color: AppColors.textSecondary,
                                fontFamily: 'NotoSans',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: Spacing.m),

                  // Coach comment: a random roster character reacts to the
                  // run, streaming the line from a speech bubble.
                  CoachCommentView(comment: _comment),

                  const SizedBox(height: Spacing.s),

                  // Celebration props: small Igbo illustrations cheering
                  // with the learner on the results screen.
                  const Row(
                    key: Key('celebrationProps'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PropSpot(name: 'lion', size: AvatarSizes.chat),
                      SizedBox(width: Spacing.m),
                      PropSpot(name: 'ogene', size: AvatarSizes.chat),
                      SizedBox(width: Spacing.m),
                      PropSpot(name: 'yam', size: AvatarSizes.chat),
                    ],
                  ),

                  const SizedBox(height: Spacing.s),

                  // Run Stats Card
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.92, end: 1.0),
                    duration: kMedAnim,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      key: const Key('runStatsCard'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                        vertical: Spacing.s,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warnBg,
                        borderRadius: BorderRadius.circular(Radii.card),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'XP Earned',
                                  style: TextStyle(
                                    fontSize: TypeScale.caption,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'NotoSans',
                                  ),
                                ),
                                const SizedBox(height: Spacing.xs),
                                Text(
                                  '+${widget.earnedXp} XP',
                                  style: const TextStyle(
                                    fontSize: TypeScale.body,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                    fontFamily: 'NotoSans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: AppColors.cardBorder),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Accuracy',
                                    style: TextStyle(
                                      fontSize: TypeScale.caption,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'NotoSans',
                                    ),
                                  ),
                                  const SizedBox(height: Spacing.xs),
                                  Text(
                                    widget.isReplay
                                        ? 'Practice Run'
                                        : (widget.isPerfect
                                              ? 'Perfect'
                                              : 'Completed'),
                                    style: const TextStyle(
                                      fontSize: TypeScale.body,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontFamily: 'NotoSans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: AppColors.cardBorder),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Streak',
                                    style: TextStyle(
                                      fontSize: TypeScale.caption,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'NotoSans',
                                    ),
                                  ),
                                  const SizedBox(height: Spacing.xs),
                                  Row(
                                    key: const Key('streakStatValue'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$streakDays',
                                        style: const TextStyle(
                                          fontSize: TypeScale.body,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          fontFamily: 'NotoSans',
                                        ),
                                      ),
                                      const SizedBox(width: Spacing.xs),
                                      const Icon(
                                        Icons.local_fire_department,
                                        size: IconSizes.s,
                                        color: AppColors.ember,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: Spacing.s),

                  // Milestone Progress Bar
                  Container(
                    key: const Key('milestoneProgressBar'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.s,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(Radii.card),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: IconSizes.s,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: Spacing.xs),
                            Text(
                              'Next Milestone: Unit Mastery',
                              style: TextStyle(
                                fontSize: TypeScale.caption,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontFamily: 'NotoSans',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.xs),
                        Container(
                          height: ControlSizes.progressBarS,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(Radii.chip),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.75,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(Radii.chip),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: Spacing.md),

                  // Continue button
                  FlatButton(
                    label: 'Continue',
                    enabled: true,
                    color: AppColors.secondary,
                    onTap: widget.onContinue,
                  ),
                  const SizedBox(height: Spacing.s),

                  // Practice again button
                  FlatButton(
                    label: 'Practice again',
                    enabled: true,
                    color: AppColors.primary,
                    onTap: widget.onPracticeAgain,
                  ),
                  const SizedBox(height: Spacing.s),

                  // Review answers button
                  FlatButton(
                    key: const Key('reviewButton'),
                    label: 'Review answers',
                    icon: Icons.fact_check,
                    enabled: true,
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _ReviewScreen(results: widget.results),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          key: Key('completionConfetti'),
          child: IgnorePointer(child: _CompletionBurst()),
        ),
      ],
    );
  }
}

/// One-shot celebration burst for the completion screen. Unlike the looping
/// streak confetti, this plays once, fades and falls away, and settles so
/// widget tests using pumpAndSettle still terminate.
class _CompletionBurst extends StatefulWidget {
  const _CompletionBurst();

  @override
  State<_CompletionBurst> createState() => _CompletionBurstState();
}

class _CompletionBurstState extends State<_CompletionBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _BurstPainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const palette = [
      AppColors.secondary,
      AppColors.primary,
      AppColors.warnBg,
      AppColors.successBg,
    ];
    for (var i = 0; i < 24; i++) {
      final angle = (i / 24) * 6.2832 + (i.isEven ? 0.2 : -0.2);
      final distance = progress * (80 + (i % 5) * 32);
      final center = Offset(size.width / 2, size.height * 0.3);
      // Fade out over the final stretch and drift down, so the pieces
      // leave the screen instead of hanging frozen in the air.
      final fade = ((1 - progress) / 0.35).clamp(0.0, 1.0);
      final fall = progress * progress * 48;
      final pos =
          center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance + fall);
      final paint = Paint()
        ..color = palette[i % palette.length].withValues(alpha: fade)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(progress * 6.2832 + i);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 8,
          height: (i % 2 == 0) ? 12 : 8,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// IntTween helper
// ---------------------------------------------------------------------------

class IntTween extends Tween<int> {
  IntTween({required int begin, required int end})
    : super(begin: begin, end: end);

  @override
  int lerp(double t) => (begin! + (end! - begin!) * t).round();
}

// ---------------------------------------------------------------------------
// Review screen: what the learner got right and wrong this run
// ---------------------------------------------------------------------------

class _ReviewScreen extends StatelessWidget {
  const _ReviewScreen({required this.results});

  final List<QuestionResult> results;

  @override
  Widget build(BuildContext context) {
    final correct = results.where((r) => r.isCorrect).length;
    return Scaffold(
      key: const Key('reviewScreen'),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Review answers',
          style: TextStyle(
            fontSize: TypeScale.title,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'NotoSans',
          ),
        ),
      ),
      body: ContentBox(
        child: results.isEmpty
            ? const Center(
                child: Text(
                  'Nothing to review yet.',
                  style: TextStyle(
                    fontSize: TypeScale.body,
                    color: AppColors.textSecondary,
                    fontFamily: 'NotoSans',
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$correct of ${results.length} correct',
                          style: const TextStyle(
                            fontSize: TypeScale.title,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'NotoSans',
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.m),
                      PropSpot(
                        key: const Key('reviewProp'),
                        name: PropArt
                            .names[math.Random().nextInt(PropArt.names.length)],
                        size: AvatarSizes.chat,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  for (var i = 0; i < results.length; i++)
                    _ReviewRow(key: Key('reviewRow_$i'), result: results[i]),
                ],
              ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({super.key, required this.result});

  final QuestionResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.s),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            result.isCorrect ? Icons.check : Icons.close,
            size: IconSizes.md,
            color: result.isCorrect ? AppColors.secondary : AppColors.error,
          ),
          const SizedBox(width: Spacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.prompt,
                  style: const TextStyle(
                    fontSize: TypeScale.body,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'NotoSans',
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'You: ${result.userAnswer}',
                  style: const TextStyle(
                    fontSize: TypeScale.bodySmall,
                    color: AppColors.textSecondary,
                    fontFamily: 'NotoSans',
                  ),
                ),
                if (!result.isCorrect) ...[
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Right: ${result.correctAnswer}',
                    style: const TextStyle(
                      fontSize: TypeScale.bodySmall,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
