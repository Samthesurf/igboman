import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/curriculum.dart';
import '../data/stories.dart';
import '../models/lesson.dart';
import '../models/story.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../widgets/content_box.dart';
import '../widgets/flat_button.dart';
import '../widgets/tappable_text.dart';

/// Story reader with three phases: new words, reading with tappable glosses,
/// and comprehension questions. First completion awards 40 XP once.
class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key, required this.story});

  final Story story;

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

enum _StoryPhase { newWords, read, questions, complete }

class _StoryScreenState extends State<StoryScreen> {
  _StoryPhase _phase = _StoryPhase.newWords;

  // Reading phase state
  String? _glossWord;
  String? _glossMeaning;

  // Question phase state
  int _questionIndex = 0;
  String? _selectedOption;
  String? _correctOption;
  bool _answeredCorrect = false;
  bool _revealed = false;

  bool _completionReported = false;

  static const _dialogueNames = ['Ada', 'Obi', 'Nna', 'Mama', 'Mbe'];

  static const _kStoryXp = 40;

  /// Gloss lookup: every curriculum word up to the story unit, the story's
  /// own new words, and the recurring character names.
  Map<String, String> _buildGlosses() {
    final map = <String, String>{};
    for (final unit in curriculum) {
      if (unit.id > widget.story.unitId) {
        break;
      }
      for (final entry in unit.vocab) {
        final meaning = entry.en;
        for (final word in entry.igbo.split(' ')) {
          map.putIfAbsent(word.toLowerCase(), () => meaning);
        }
      }
    }
    for (final newWord in widget.story.newWords) {
      map[newWord.igbo.toLowerCase()] = newWord.en;
    }
    map.addAll(storyCharacterGlosses);
    return map;
  }

  String? _dialogueName(String sentence) {
    for (final name in _dialogueNames) {
      if (sentence.startsWith('$name:')) {
        return name;
      }
    }
    return null;
  }

  void _onGlossTap(String word, String? gloss) {
    setState(() {
      _glossWord = word;
      _glossMeaning = gloss;
    });
  }

  void _dismissGloss() {
    setState(() {
      _glossWord = null;
      _glossMeaning = null;
    });
  }

  LessonQuestion get _currentQuestion => widget.story.questions[_questionIndex];

  void _selectOption(String option) {
    if (_revealed) return;
    setState(() => _selectedOption = option);
  }

  void _checkAnswer() {
    final question = _currentQuestion;
    final selected = _selectedOption;
    if (selected == null) return;
    final correct =
        selected == question.answer ||
        (question.acceptedAnswers.isNotEmpty &&
            question.acceptedAnswers.contains(selected));
    setState(() {
      _answeredCorrect = correct;
      if (!correct) {
        _correctOption =
            question.answer ?? question.acceptedAnswers.firstOrNull;
      }
      _revealed = true;
    });
  }

  void _continueQuestion() {
    setState(() {
      _questionIndex++;
      _selectedOption = null;
      _correctOption = null;
      _answeredCorrect = false;
      _revealed = false;
    });
    if (_questionIndex >= widget.story.questions.length) {
      setState(() => _phase = _StoryPhase.complete);
    }
  }

  void _reportCompletion() {
    if (_completionReported || !mounted) return;
    _completionReported = true;
    final appState = context.read<AppState>();
    if (!appState.isStoryCompleted(widget.story.id)) {
      appState.awardXp(_kStoryXp);
      appState.completeStory(widget.story.id);
    }
  }

  void _showTalkSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.card)),
      ),
      builder: (context) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(Spacing.md),
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Story talk',
                style: TextStyle(
                  fontSize: TypeScale.title,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoSans',
                ),
              ),
              const SizedBox(height: Spacing.s),
              const Text(
                'Story talk comes with the chat update',
                style: TextStyle(
                  fontSize: TypeScale.body,
                  color: AppColors.textSecondary,
                  fontFamily: 'NotoSans',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.story.titleEn,
          style: const TextStyle(
            fontSize: TypeScale.title,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'NotoSans',
          ),
        ),
      ),
      body: switch (_phase) {
        _StoryPhase.newWords => _buildNewWords(),
        _StoryPhase.read => _buildReading(),
        _StoryPhase.questions => _buildQuestions(),
        _StoryPhase.complete => _buildComplete(),
      },
    );
  }

  // -------------------------------------------------------------------------
  // Phase 1: new words
  // -------------------------------------------------------------------------

  Widget _buildNewWords() {
    return ContentBox(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New words',
              style: TextStyle(
                fontSize: TypeScale.headline,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'NotoSans',
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Tap any word in the story to see its meaning.',
              style: const TextStyle(
                fontSize: TypeScale.body,
                color: AppColors.textSecondary,
                fontFamily: 'NotoSans',
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Wrap(
              spacing: Spacing.s,
              runSpacing: Spacing.s,
              children: [
                for (final newWord in widget.story.newWords)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.m,
                      vertical: Spacing.s,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(Radii.chip),
                    ),
                    child: Text(
                      newWord.igbo,
                      style: const TextStyle(
                        fontSize: TypeScale.body,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                        fontFamily: 'NotoSans',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            for (final newWord in widget.story.newWords)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.s),
                child: Text(
                  '${newWord.igbo} (${newWord.en})',
                  style: const TextStyle(
                    fontSize: TypeScale.body,
                    color: AppColors.textSecondary,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ),
            const SizedBox(height: Spacing.lg),
            FlatButton(
              label: 'Start reading',
              enabled: true,
              color: AppColors.secondary,
              onTap: () => setState(() => _phase = _StoryPhase.read),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Phase 2: reading
  // -------------------------------------------------------------------------

  Widget _buildReading() {
    final glosses = _buildGlosses();
    return Column(
      children: [
        Expanded(
          child: ContentBox(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final sentence in widget.story.sentences)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.lg),
                      child: _buildSentence(sentence, glosses),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_glossWord != null) _buildGlossCard(),
        ContentBox(
          child: Padding(
            padding: const EdgeInsets.only(top: Spacing.s, bottom: Spacing.md),
            child: FlatButton(
              label: 'Continue',
              enabled: true,
              color: AppColors.secondary,
              onTap: () => setState(() => _phase = _StoryPhase.questions),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSentence(String sentence, Map<String, String> glosses) {
    final name = _dialogueName(sentence);
    if (name == null) {
      return TokenizedText(
        text: sentence,
        glosses: glosses,
        showGloss: _onGlossTap,
      );
    }
    final rest = sentence.substring(name.length + 1).trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$name:',
          style: const TextStyle(
            fontSize: TypeScale.body,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontFamily: 'NotoSans',
          ),
        ),
        const SizedBox(width: Spacing.s),
        Expanded(
          child: TokenizedText(
            text: rest,
            glosses: glosses,
            showGloss: _onGlossTap,
          ),
        ),
      ],
    );
  }

  Widget _buildGlossCard() {
    return ContentBox(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.s,
        ),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Row(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: kFastAnim,
                child: Text(
                  _glossMeaning == null
                      ? '$_glossWord: New word!'
                      : '$_glossWord = $_glossMeaning',
                  key: ValueKey('$_glossWord$_glossMeaning'),
                  style: const TextStyle(
                    fontSize: TypeScale.body,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _dismissGloss,
              child: const Padding(
                padding: EdgeInsets.all(Spacing.xs),
                child: Icon(
                  Icons.close,
                  size: IconSizes.m,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Phase 3: comprehension questions
  // -------------------------------------------------------------------------

  Widget _buildQuestions() {
    final question = _currentQuestion;
    return Column(
      children: [
        Expanded(
          child: ContentBox(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_questionIndex + 1} of '
                    '${widget.story.questions.length}',
                    style: const TextStyle(
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
                  for (final option in question.options)
                    _buildOptionCard(question, option),
                ],
              ),
            ),
          ),
        ),
        if (_revealed) _buildFeedbackStrip(),
        ContentBox(
          child: Padding(
            padding: const EdgeInsets.only(top: Spacing.s, bottom: Spacing.md),
            child: _revealed
                ? FlatButton(
                    label: 'Continue',
                    enabled: true,
                    color: _answeredCorrect
                        ? AppColors.secondary
                        : AppColors.primary,
                    onTap: _continueQuestion,
                  )
                : FlatButton(
                    label: 'Check',
                    enabled: _selectedOption != null,
                    color: AppColors.secondary,
                    onTap: _selectedOption != null ? _checkAnswer : null,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(LessonQuestion question, String option) {
    final isSelected = _selectedOption == option;
    final isCorrectReveal = _correctOption == option;
    final isWrongPick = _revealed && !_answeredCorrect && isSelected;

    Color borderColor = AppColors.cardBorder;
    Color bgColor = AppColors.surface;
    Color textColor = AppColors.textPrimary;
    Widget? trailingIcon;

    if (_revealed) {
      if (isCorrectReveal || (_answeredCorrect && isSelected)) {
        borderColor = AppColors.secondary;
        bgColor = AppColors.successBg;
        textColor = AppColors.secondary;
        trailingIcon = const Icon(
          Icons.check,
          color: AppColors.secondary,
          size: IconSizes.md,
        );
      } else if (isWrongPick) {
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
        onTap: () => _selectOption(option),
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
                  option,
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
  }

  Widget _buildFeedbackStrip() {
    return Container(
      width: double.infinity,
      color: _answeredCorrect
          ? AppColors.successBg
          : AppColors.error.withAlpha(30),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.s,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _answeredCorrect ? 'Correct!' : 'Not quite',
                  style: TextStyle(
                    fontSize: TypeScale.body,
                    fontWeight: FontWeight.bold,
                    color: _answeredCorrect
                        ? AppColors.secondary
                        : AppColors.error,
                    fontFamily: 'NotoSans',
                  ),
                ),
                if (!_answeredCorrect && _correctOption != null)
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
            _answeredCorrect ? Icons.check_circle_outline : Icons.close,
            color: _answeredCorrect ? AppColors.secondary : AppColors.error,
            size: IconSizes.lg,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Completion
  // -------------------------------------------------------------------------

  Widget _buildComplete() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportCompletion();
    });

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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Squircle check badge
              Container(
                width: AvatarSizes.hero,
                height: AvatarSizes.hero,
                alignment: Alignment.center,
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
              const Text(
                'Akụkọ!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: TypeScale.headline,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoSans',
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                widget.story.titleEn,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: TypeScale.body,
                  color: AppColors.textSecondary,
                  fontFamily: 'NotoSans',
                ),
              ),
              const SizedBox(height: Spacing.md),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: totalXp),
                duration: kMedAnim,
                builder: (context, value, child) {
                  return Text(
                    '$value XP',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: TypeScale.headline,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                      fontFamily: 'NotoSans',
                    ),
                  );
                },
              ),
              const SizedBox(height: Spacing.lg),
              FlatButton(
                label: 'Talk about it',
                enabled: true,
                color: AppColors.secondary,
                onTap: _showTalkSheet,
              ),
              const SizedBox(height: Spacing.s),
              FlatButton(
                label: 'Back',
                enabled: true,
                color: AppColors.primary,
                onTap: () => Navigator.of(context).pop(),
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
