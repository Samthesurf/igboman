import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson.dart';
import '../services/answer_checker.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../widgets/avatar_view.dart';
import '../widgets/content_box.dart';
import '../widgets/diacritic_bar.dart';
import '../widgets/flat_button.dart';

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
  bool _isReplay = false;

  void _onQuestionDone(int xpEarned) {
    setState(() {
      _earnedXp += xpEarned;
      _questionIndex++;
    });
  }

  void _onLessonComplete(BuildContext context) async {
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
      _isReplay = true;
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
            )
          : _QuestionPage(
              key: ValueKey('q_${_questionIndex}_${widget.lesson.id}'),
              question: questions[_questionIndex],
              questionNumber: _questionIndex + 1,
              totalQuestions: questions.length,
              isReplay: _isReplay,
              onDone: _onQuestionDone,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar with flat progress bar
// ---------------------------------------------------------------------------

class _LessonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _LessonAppBar({required this.title, required this.progress});

  final String title;
  final double progress;

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

class _QuestionPage extends StatefulWidget {
  const _QuestionPage({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.isReplay,
    required this.onDone,
  });

  final LessonQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final bool isReplay;
  final void Function(int xpEarned) onDone;

  @override
  State<_QuestionPage> createState() => _QuestionPageState();
}

enum _AnswerState { idle, correct, correctToneNote, wrong }

class _QuestionPageState extends State<_QuestionPage>
    with SingleTickerProviderStateMixin {
  _AnswerState _answerState = _AnswerState.idle;
  late AnimationController _animController;
  late Animation<double> _shakeAnim;
  late Animation<double> _scaleAnim;

  // Per-type state
  String? _selectedOption; // MCQ
  String? _correctOption; // MCQ correct reveal
  List<_PairAttempt> _pairAttempts = []; // matchPairs
  String? _selectedLeft; // matchPairs pending
  List<String> _filledSlots = []; // fillBlank
  final _translateController = TextEditingController(); // translate

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: kFastAnim);
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 25),
    ]).animate(_animController);
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
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
      setState(() {
        _answerState = result.toneNote
            ? _AnswerState.correctToneNote
            : _AnswerState.correct;
      });
      _animController.forward(from: 0);
    } else {
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
    widget.onDone(_computeXp());
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
        setState(() => _answerState = _AnswerState.correct);
        _animController.forward(from: 0);
      }
    } else {
      // Wrong pair: shake and deselect
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
        double offsetX = 0;
        double scale = 1.0;
        if (_answerState == _AnswerState.wrong) {
          offsetX = _shakeAnim.value;
        } else if (isCorrect) {
          scale = _scaleAnim.value;
        }

        return Transform.translate(
          offset: Offset(offsetX, 0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: _buildBody(isCorrect),
    );
  }

  Widget _buildBody(bool isCorrect) {
    return Column(
      children: [
        Expanded(
          child: ContentBox(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              child: _buildQuestionContent(),
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
      child: Row(
        children: [
          AvatarView(
            assetPath: isCorrect ? 'assets/images/ada.png' : null,
            size: AvatarSizes.card,
          ),
          const SizedBox(width: Spacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCorrect ? 'Correct!' : 'Not quite',
                  style: TextStyle(
                    fontSize: TypeScale.body,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? AppColors.secondary : AppColors.error,
                    fontFamily: 'NotoSans',
                  ),
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
    );
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
  });

  final int earnedXp;
  final String lessonId;
  final VoidCallback onContinue;
  final VoidCallback onPracticeAgain;
  final VoidCallback onFirstCompletion;
  final bool isReplay;

  @override
  State<_CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<_CompletionScreen> {
  bool _completionReported = false;

  @override
  void initState() {
    super.initState();
    // Report completion once on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_completionReported && mounted) {
        _completionReported = true;
        widget.onFirstCompletion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final totalXp = appState.xp;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ControlSizes.contentMaxWidth,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Check badge
              Container(
                width: AvatarSizes.hero,
                height: AvatarSizes.hero,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(Radii.hero),
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.onSecondary,
                  size: IconSizes.lg * 2,
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Ada avatar cheering
              const AvatarView(
                assetPath: 'assets/images/ada.png',
                size: AvatarSizes.card,
              ),
              const SizedBox(height: Spacing.s),

              const Text(
                'Excellent!',
                style: TextStyle(
                  fontSize: TypeScale.headline,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoSans',
                ),
              ),
              const SizedBox(height: Spacing.xs),

              // XP count-up
              if (!widget.isReplay)
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: totalXp),
                  duration: kMedAnim,
                  builder: (context, value, child) {
                    return Text(
                      '$value XP',
                      style: const TextStyle(
                        fontSize: TypeScale.headline,
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
                    fontSize: TypeScale.body,
                    color: AppColors.textSecondary,
                    fontFamily: 'NotoSans',
                  ),
                ),

              const SizedBox(height: Spacing.lg),

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
            ],
          ),
        ),
      ),
    );
  }
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
