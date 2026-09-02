import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/curriculum.dart';
import '../services/prompt_builder.dart';
import '../services/tutor_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../widgets/avatar_view.dart';
import '../widgets/diacritic_bar.dart';
import '../widgets/flat_button.dart';
import '../widgets/speech_bubble.dart';

/// Avatar chat screen where the learner talks with Ada, the Igbo tutor.
///
/// Layout (top to bottom): a pinned "talking" [SpeechBubble] above Ada's
/// avatar (tail pointing down toward the avatar), the settled transcript,
/// and the input row with a diacritic-bar toggle and send button.
///
/// The greeting is shown immediately from local state (no API call); only
/// exchanges typed by the learner call [TutorService.chat]. The live bubble
/// auto-expands as chunks stream in, and settles each reply into the
/// transcript when the stream ends.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.tutor,
    this.contextBuilder,
    this.storyContext,
    this.maxExchanges = 6,
  });

  final TutorService tutor;

  /// Optional override for building the [TutorContext]. When null, the
  /// context is built from [AppState] plus [storyContext].
  final TutorContext Function()? contextBuilder;

  /// Optional story context to discuss during the session.
  final String? storyContext;

  /// Session ends after this many settled tutor replies.
  final int maxExchanges;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  AppState? _appState;
  bool _greetingReady = false;
  bool _diacriticOpen = false;

  /// Displayed turns: the local greeting plus every settled exchange.
  final List<TutorTurn> _transcript = [];

  /// API history: only the exchanges after the greeting (greeting is UI-only).
  final List<TutorTurn> _history = [];

  int _exchanges = 0;
  bool _isStreaming = false;
  String _pinnedText = '';
  String? _error;
  bool _sessionEnded = false;
  bool _xpAwarded = false;
  bool _streamFailed = false;

  StreamSubscription<String>? _chatSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _appState = context.read<AppState>();
    } catch (_) {
      _appState = null;
    }
    if (!_greetingReady) {
      _greetingReady = true;
      _transcript.add(
        TutorTurn(role: 'tutor', text: buildSessionGreeting(_buildContext())),
      );
    }
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Context + streaming
  // -------------------------------------------------------------------------

  TutorContext _buildContext() {
    final builder = widget.contextBuilder;
    if (builder != null) {
      return builder();
    }
    final appState = _appState;
    if (appState == null) {
      return TutorContext(
        learnerName: 'you',
        completedUnits: 0,
        whitelistVocab: const [],
        storyContext: widget.storyContext,
      );
    }
    final completedUnits = curriculum
        .where((u) => appState.unitFullyCompleted(u.id))
        .length;
    final firstIncomplete = curriculum.firstWhere(
      (u) => !appState.unitFullyCompleted(u.id),
      orElse: () => curriculum.last,
    );
    final vocabLimit = math.max(1, firstIncomplete.id);
    final vocab = curriculum
        .where((u) => u.id <= vocabLimit)
        .expand((u) => u.vocab)
        .toList(growable: false);
    return TutorContext(
      learnerName: 'you',
      completedUnits: completedUnits,
      whitelistVocab: vocab,
      storyContext: widget.storyContext,
    );
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty || _isStreaming || _sessionEnded) {
      return;
    }
    _input.clear();
    setState(() => _error = null);
    final turn = TutorTurn(role: 'user', text: text);
    _transcript.add(turn);
    _history.add(turn);
    _startStream();
  }

  void _retry() {
    if (_isStreaming || _sessionEnded || _history.isEmpty) {
      return;
    }
    _startStream();
  }

  void _startStream() {
    setState(() {
      _isStreaming = true;
      _pinnedText = '';
      _error = null;
      _streamFailed = false;
    });
    _chatSub?.cancel();
    final stream = widget.tutor.chat(
      history: List.of(_history),
      context: _buildContext(),
    );
    _chatSub = stream.listen(
      (chunk) {
        if (!mounted) return;
        setState(() => _pinnedText += chunk);
        _scheduleScroll();
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _isStreaming = false;
          _pinnedText = '';
          _streamFailed = true;
          _error = e is TutorException
              ? e.userMessage
              : 'Something went wrong. Biko try again.';
        });
        _scheduleScroll();
      },
      onDone: () {
        if (!mounted || _streamFailed) return;
        final settled = _pinnedText.trim();
        setState(() {
          _isStreaming = false;
          _pinnedText = '';
          _error = null;
          if (settled.isNotEmpty) {
            final turn = TutorTurn(role: 'tutor', text: settled);
            _transcript.add(turn);
            _history.add(turn);
            _exchanges += 1;
            _maybeEndSession();
          }
        });
        _scheduleScroll();
      },
    );
  }

  void _maybeEndSession() {
    if (_exchanges >= widget.maxExchanges) {
      _sessionEnded = true;
      if (!_xpAwarded) {
        _xpAwarded = true;
        _appState?.awardXp(20);
      }
    }
  }

  void _practiceAgain() {
    _chatSub?.cancel();
    setState(() {
      _transcript.clear();
      _history.clear();
      _exchanges = 0;
      _isStreaming = false;
      _pinnedText = '';
      _error = null;
      _sessionEnded = false;
      _input.clear();
    });
    setState(() {
      _transcript.add(
        TutorTurn(role: 'tutor', text: buildSessionGreeting(_buildContext())),
      );
    });
    _scheduleScroll();
  }

  void _done() {
    Navigator.of(context).maybePop();
  }

  void _scheduleScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      if (position.maxScrollExtent > 0) {
        position.animateTo(
          position.maxScrollExtent,
          duration: kFastAnim,
          curve: Curves.easeOut,
        );
      }
    });
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ControlSizes.contentMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  Expanded(child: _buildConversation(context)),
                  _buildInputArea(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.s, bottom: Spacing.m),
      child: Row(
        children: [
          IconButton(
            key: const Key('chatBackButton'),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
              size: IconSizes.md,
            ),
          ),
          const AvatarView(
            assetPath: 'assets/images/ada.png',
            initial: 'A',
            size: AvatarSizes.chat,
            borderRadius: Radii.button,
          ),
          const SizedBox(width: Spacing.m),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ada',
                  style: TextStyle(
                    fontSize: TypeScale.title,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'NotoSans',
                  ),
                ),
                Text(
                  'Nkụzi',
                  style: TextStyle(
                    fontSize: TypeScale.bodySmall,
                    color: AppColors.textSecondary,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ],
            ),
          ),
          _buildProgressChip(),
        ],
      ),
    );
  }

  Widget _buildProgressChip() {
    return Container(
      key: const Key('chatProgressChip'),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: Text(
        '$_exchanges/${widget.maxExchanges}',
        style: const TextStyle(
          fontSize: TypeScale.caption,
          fontWeight: FontWeight.bold,
          color: AppColors.secondary,
          fontFamily: 'NotoSans',
        ),
      ),
    );
  }

  Widget _buildConversation(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth = constraints.maxWidth * 0.75;
        return SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(vertical: Spacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPinned(),
              const SizedBox(height: Spacing.lg),
              for (final turn in _transcript) _buildTurn(turn, maxBubbleWidth),
            ],
          ),
        );
      },
    );
  }

  /// The live "talking" bubble above Ada's avatar. Hidden when idle.
  Widget _buildPinned() {
    if (_isStreaming) {
      return Column(
        key: const Key('chatPinned'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpeechBubble(
            key: const Key('chatPinnedBubble'),
            text: _pinnedText,
            waiting: true,
          ),
          const SizedBox(height: Spacing.s),
          const AvatarView(
            assetPath: 'assets/images/ada.png',
            initial: 'A',
            size: AvatarSizes.chat,
            borderRadius: Radii.button,
          ),
        ],
      );
    }
    if (_error != null) {
      return Column(
        key: const Key('chatPinned'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildErrorBubble(),
          const SizedBox(height: Spacing.s),
          const AvatarView(
            assetPath: 'assets/images/ada.png',
            initial: 'A',
            size: AvatarSizes.chat,
            borderRadius: Radii.button,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildErrorBubble() {
    return Container(
      key: const Key('chatErrorBubble'),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.chip),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _error!,
            style: const TextStyle(
              fontSize: TypeScale.body,
              color: AppColors.error,
              fontFamily: 'NotoSans',
              height: TypeScale.bodyLineHeight,
            ),
          ),
          const SizedBox(height: Spacing.s),
          TextButton(
            key: const Key('chatRetryButton'),
            onPressed: _retry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, ControlSizes.minTouchTarget),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: TypeScale.body,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurn(TutorTurn turn, double maxBubbleWidth) {
    final isUser = turn.role == 'user';
    final child = Padding(
      padding: const EdgeInsets.only(bottom: Spacing.m),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            isUser ? 'You' : 'Ada',
            style: const TextStyle(
              fontSize: TypeScale.caption,
              color: AppColors.textSecondary,
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Container(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.s,
            ),
            decoration: BoxDecoration(
              color: isUser ? AppColors.successBg : AppColors.surface,
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              turn.text,
              style: const TextStyle(
                fontSize: TypeScale.body,
                color: AppColors.textPrimary,
                fontFamily: 'NotoSans',
                height: TypeScale.bodyLineHeight,
              ),
            ),
          ),
        ],
      ),
    );
    // User bubbles hug the right edge of the screen.
    if (isUser) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }

  Widget _buildInputArea() {
    if (_sessionEnded) {
      return _buildEndButtons();
    }
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.s, bottom: Spacing.md),
      child: Column(
        children: [
          if (_diacriticOpen) ...[
            DiacriticBar(controller: _input),
            const SizedBox(height: Spacing.s),
          ],
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(Radii.chip),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: TextField(
                    key: const Key('chatInput'),
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: const TextStyle(
                      fontSize: TypeScale.body,
                      color: AppColors.textPrimary,
                      fontFamily: 'NotoSans',
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: Spacing.m,
                        vertical: Spacing.m,
                      ),
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'NotoSans',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.s),
              _buildDiacriticToggle(),
              const SizedBox(width: Spacing.s),
              _buildSendButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiacriticToggle() {
    return IconButton(
      key: const Key('chatDiacriticToggle'),
      onPressed: () => setState(() => _diacriticOpen = !_diacriticOpen),
      tooltip: 'Diacritics',
      icon: Icon(
        Icons.keyboard_alt,
        size: IconSizes.m,
        color: _diacriticOpen ? AppColors.secondary : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildSendButton() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _input,
      builder: (context, value, _) {
        final enabled =
            !_isStreaming && !_sessionEnded && value.text.trim().isNotEmpty;
        return IconButton(
          key: const Key('chatSendButton'),
          onPressed: enabled ? _send : null,
          tooltip: 'Send',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.secondary,
            disabledBackgroundColor: AppColors.disabledFill,
            foregroundColor: AppColors.onSecondary,
            disabledForegroundColor: AppColors.disabledText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.button),
            ),
            minimumSize: const Size(
              ControlSizes.buttonHeight,
              ControlSizes.buttonHeight,
            ),
            maximumSize: const Size(
              ControlSizes.buttonHeight,
              ControlSizes.buttonHeight,
            ),
          ),
          icon: const Icon(Icons.send, size: IconSizes.md),
        );
      },
    );
  }

  Widget _buildEndButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.s, bottom: Spacing.md),
      child: Row(
        children: [
          Expanded(
            child: FlatButton(
              key: const Key('chatPracticeAgain'),
              label: 'Practice again',
              enabled: true,
              color: AppColors.secondary,
              onTap: _practiceAgain,
            ),
          ),
          const SizedBox(width: Spacing.m),
          Expanded(
            child: FlatButton(
              key: const Key('chatDoneButton'),
              label: 'Done',
              enabled: true,
              color: AppColors.primary,
              onTap: _done,
            ),
          ),
        ],
      ),
    );
  }
}
