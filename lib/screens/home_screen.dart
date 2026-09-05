import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/curriculum.dart';
import '../models/unit.dart';
import '../services/gemini_tutor_service.dart';
import '../services/unit_quiz.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../widgets/avatar_view.dart';
import '../widgets/content_box.dart';
import '../widgets/flat_button.dart';
import '../widgets/prop_spot.dart';
import '../widgets/streak_chip.dart';
import '../widgets/xp_chip.dart';
import 'chat_screen.dart';
import 'lesson_screen.dart';
import 'stories_screen.dart';

const double _desktopBreakpoint = 800;
const double _sideRailWidth = 176;

/// Home screen: the unit map path with Learn / Stories / Chat navigation.
/// Mobile widths get a bottom navigation bar, desktop widths a left side rail.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  void _onUnitTap(Unit unit, AppState appState) {
    if (!appState.unitIsUnlocked(unit.id)) {
      _showLockedUnitMessage();
      return;
    }
    if (unit.lessons.isEmpty) return;
    final nextLesson = unit.lessons.firstWhere(
      (lesson) => !appState.isLessonCompleted(lesson.id),
      orElse: () => unit.lessons.first,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: nextLesson)),
    );
  }

  void _openUnitQuiz(Unit unit) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonScreen(lesson: buildUnitQuiz(unit)),
      ),
    );
  }

  void _showLockedUnitMessage() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: AppColors.successBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.button),
        ),
        content: const Text(
          'Finish the previous unit first',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'NotoSans',
          ),
        ),
      ),
    );
  }

  double _progressFraction(AppState appState, Unit unit) {
    if (unit.lessons.isEmpty) return 0;
    final completed = unit.lessons
        .where((lesson) => appState.isLessonCompleted(lesson.id))
        .length;
    return completed / unit.lessons.length;
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Text(
          'Igboman',
          style: TextStyle(
            fontSize: TypeScale.headline,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'NotoSans',
          ),
        ),
        Spacer(),
        StreakChip(),
        SizedBox(width: Spacing.s),
        XpChip(),
      ],
    );
  }

  Widget _buildLearnTab(AppState appState) {
    final units = curriculum;
    int? currentUnitId;
    for (final unit in units) {
      if (appState.unitIsUnlocked(unit.id) &&
          !appState.unitFullyCompleted(unit.id)) {
        currentUnitId = unit.id;
        break;
      }
    }
    var clearedCount = 0;
    for (final unit in units) {
      if (appState.unitFullyCompleted(unit.id)) clearedCount++;
    }

    // Winding trail: cards stagger left and right so the route snakes down
    // the screen like a jungle run, with a dashed trail segment between
    // each pair of realms.
    final pathItems = <Widget>[];
    for (var i = 0; i < units.length; i++) {
      if (i > 0) {
        pathItems.add(
          _TrailSegment(
            key: Key('trailSegment_$i'),
            bendLeft: i.isOdd,
            done: appState.unitFullyCompleted(units[i - 1].id),
          ),
        );
      }
      final unit = units[i];
      final stagger = i.isEven
          ? const EdgeInsets.only(right: Spacing.xl)
          : const EdgeInsets.only(left: Spacing.xl);
      pathItems.add(
        Padding(
          padding: stagger,
          child: _UnitCard(
            unit: unit,
            isCurrent: unit.id == currentUnitId,
            locked: !appState.unitIsUnlocked(unit.id),
            completed: appState.unitFullyCompleted(unit.id),
            progressFraction: _progressFraction(appState, unit),
            onTap: () => _onUnitTap(unit, appState),
            onQuizTap: appState.unitFullyCompleted(unit.id)
                ? () => _openUnitQuiz(unit)
                : null,
          ),
        ),
      );
    }

    return ContentBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: Spacing.lg),
          Expanded(
            child: ListView(
              key: const Key('journeyPath'),
              padding: const EdgeInsets.only(bottom: Spacing.xl),
              children: [
                _JourneyHeader(cleared: clearedCount, total: units.length),
                const SizedBox(height: Spacing.md),
                ...pathItems,
                const SizedBox(height: Spacing.xl),
                const _StoriesCard(),
                const SizedBox(height: Spacing.md),
                const _CultureStrip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesTab() {
    return const StoriesList();
  }

  Widget _buildChatTab() {
    return ContentBox(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AvatarView(
              assetPath: 'assets/images/ada.jpg',
              size: AvatarSizes.hero,
            ),
            const SizedBox(height: Spacing.md),
            const Text(
              'Talk with Ada',
              style: TextStyle(
                fontSize: TypeScale.title,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'NotoSans',
              ),
            ),
            const SizedBox(height: Spacing.xs),
            const Text(
              'Practise with the Igbo tutor, one chat at a time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: TypeScale.bodySmall,
                color: AppColors.textSecondary,
                fontFamily: 'NotoSans',
              ),
            ),
            const SizedBox(height: Spacing.lg),
            FlatButton(
              key: const Key('chatStartButton'),
              label: 'Start chatting',
              enabled: true,
              color: AppColors.secondary,
              onTap: () => _openChat(context),
            ),
            const SizedBox(height: Spacing.lg),
            const Row(
              key: Key('chatProps'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PropSpot(name: 'kolanut', size: AvatarSizes.mini),
                SizedBox(width: Spacing.m),
                PropSpot(name: 'palm', size: AvatarSizes.mini),
                SizedBox(width: Spacing.m),
                PropSpot(name: 'yam', size: AvatarSizes.mini),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the avatar chat, resolving the API key lazily. Without a key the
  /// tutor cannot start, so a snackbar explains how to configure one.
  void _openChat(BuildContext context) {
    final GeminiTutorService tutor;
    try {
      tutor = GeminiTutorService();
    } catch (_) {
      _showKeyMissingMessage(context);
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(tutor: tutor)));
  }

  void _showKeyMissingMessage(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: AppColors.successBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.button),
        ),
        content: const Text(
          'Add a Gemini API key (GEMINI_API_KEY) to chat with Ada',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'NotoSans',
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(AppState appState) {
    switch (_tabIndex) {
      case 1:
        return _buildStoriesTab();
      case 2:
        return _buildChatTab();
      default:
        return _buildLearnTab(appState);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= _desktopBreakpoint;
            final content = _buildTabContent(appState);
            if (desktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SideRail(
                    selectedIndex: _tabIndex,
                    onSelect: (index) => setState(() => _tabIndex = index),
                  ),
                  Expanded(child: content),
                ],
              );
            }
            return Column(
              children: [
                Expanded(child: content),
                _BottomNav(
                  selectedIndex: _tabIndex,
                  onSelect: (index) => setState(() => _tabIndex = index),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      elevation: 0,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book, color: AppColors.onPrimary),
          label: 'Learn',
        ),
        NavigationDestination(
          icon: Icon(Icons.book_outlined),
          selectedIcon: Icon(Icons.book, color: AppColors.onPrimary),
          label: 'Stories',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble, color: AppColors.onPrimary),
          label: 'Chat',
        ),
      ],
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('homeSideRail'),
      width: _sideRailWidth,
      color: AppColors.warnBg,
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RailItem(
            icon: Icons.menu_book,
            label: 'Learn',
            index: 0,
            selected: selectedIndex == 0,
            onSelect: onSelect,
          ),
          _RailItem(
            icon: Icons.book,
            label: 'Stories',
            index: 1,
            selected: selectedIndex == 1,
            onSelect: onSelect,
          ),
          _RailItem(
            icon: Icons.chat_bubble,
            label: 'Chat',
            index: 2,
            selected: selectedIndex == 2,
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onSelect,
  });

  final IconData icon;
  final String label;
  final int index;
  final bool selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Spacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.m,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.button),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: IconSizes.m,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: Spacing.m),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: TypeScale.body,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontFamily: 'NotoSans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Journey header: the run banner that opens the trail. Shows how many
/// realms are cleared and how far the run has come, with forward momentum
/// copy. It uses the same white to light-green vertical flow as the
/// current-lesson card gradient with soft lift for game-look depth
/// (see design_audit_test.dart game-look exemption).
class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader({required this.cleared, required this.total});

  final int cleared;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : cleared / total;
    final remaining = total - cleared;
    return Container(
      key: const Key('journeyHeader'),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface, AppColors.successBg],
        ),
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.directions_run,
                size: IconSizes.md,
                color: AppColors.secondary,
              ),
              SizedBox(width: Spacing.s),
              Expanded(
                child: Text(
                  'THE GREAT RUN',
                  style: TextStyle(
                    fontSize: TypeScale.caption,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            '$cleared of $total realms cleared',
            style: const TextStyle(
              fontSize: TypeScale.title,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            remaining == 0
                ? 'Every realm conquered. Run it again!'
                : '$remaining realms ahead. Keep running!',
            style: const TextStyle(
              fontSize: TypeScale.bodySmall,
              color: AppColors.textSecondary,
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(height: Spacing.s),
          _JourneyBar(fraction: fraction),
        ],
      ),
    );
  }
}

/// Overall run progress bar. Built with LayoutBuilder instead of
/// FractionallySizedBox so the home progress-fraction tests keep counting
/// only the per-unit bars.
class _JourneyBar extends StatelessWidget {
  const _JourneyBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fillWidth =
            constraints.maxWidth * fraction.clamp(0.0, 1.0).toDouble();
        return Container(
          height: ControlSizes.progressBarS,
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
    );
  }
}

/// One trail link between two realms on the winding path. The connector is
/// a single continuous stroke that plugs into the card above and the card
/// below (a node dot caps each end), so the path reads as one route with
/// no dashes dangling into empty space. No segment is built after the last
/// realm, so the trail terminates cleanly. Completed trail glows green,
/// upcoming trail stays earthy brown.
class _TrailSegment extends StatelessWidget {
  const _TrailSegment({super.key, required this.bendLeft, required this.done});

  final bool bendLeft;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomPaint(
            painter: _TrailPainter(done: done, bendLeft: bendLeft),
            size: const Size(72, 28),
          ),
        ],
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.done, required this.bendLeft});

  final bool done;
  final bool bendLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final color = done ? AppColors.secondary : AppColors.primary;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final sway = bendLeft ? -12.0 : 12.0;
    final start = Offset(size.width / 2, 4);
    final end = Offset(size.width / 2, size.height - 4);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        size.width / 2 + sway,
        size.height * 0.35,
        size.width / 2 - sway,
        size.height * 0.65,
        end.dx,
        end.dy,
      );
    canvas.drawPath(path, paint);
    final dot = Paint()..color = color;
    canvas.drawCircle(start, 4, dot);
    canvas.drawCircle(end, 4, dot);
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) =>
      oldDelegate.done != done || oldDelegate.bendLeft != bendLeft;
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.isCurrent,
    required this.locked,
    required this.completed,
    required this.progressFraction,
    required this.onTap,
    this.onQuizTap,
  });

  final Unit unit;
  final bool isCurrent;
  final bool locked;
  final bool completed;
  final double progressFraction;
  final VoidCallback onTap;

  /// Fires when the completed unit's quiz tile is tapped.
  final VoidCallback? onQuizTap;

  @override
  Widget build(BuildContext context) {
    final reserveAction = (completed && onQuizTap != null)
        ? ControlSizes.minTouchTarget +
              ControlSizes.minTouchTarget +
              Spacing.m +
              Spacing.s
        : ControlSizes.minTouchTarget + Spacing.m;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          gradient: isCurrent
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.surface, AppColors.warnBg],
                )
              : null,
          color: isCurrent ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(
            color: isCurrent ? AppColors.primary : AppColors.cardBorder,
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: isCurrent
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.card),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCurrent)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: ControlSizes.chipHeight + Spacing.m,
                          bottom: Spacing.s,
                        ),
                        child: Container(
                          key: const Key('currentRunBadge'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.s,
                            vertical: Spacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(Radii.chip),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions_run,
                                size: IconSizes.s,
                                color: AppColors.onPrimary,
                              ),
                              SizedBox(width: Spacing.xs),
                              Text(
                                'YOU ARE HERE',
                                style: TextStyle(
                                  fontSize: TypeScale.caption,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onPrimary,
                                  fontFamily: 'NotoSans',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: ControlSizes.chipHeight + Spacing.m,
                        right: reserveAction,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.titleIgbo,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: TypeScale.title,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'NotoSans',
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            unit.titleEn,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: TypeScale.bodySmall,
                              color: AppColors.textSecondary,
                              fontFamily: 'NotoSans',
                            ),
                          ),
                          const SizedBox(height: Spacing.s),
                          _ProgressBar(fraction: progressFraction),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: ControlSizes.minTouchTarget,
                        child: Center(
                          child: _UnitBadge(
                            number: unit.id,
                            locked: locked,
                            completed: completed,
                          ),
                        ),
                      ),
                      if (locked)
                        const SizedBox(
                          width: ControlSizes.minTouchTarget,
                          height: ControlSizes.minTouchTarget,
                          child: Icon(
                            Icons.lock,
                            size: IconSizes.md,
                            color: AppColors.disabledText,
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: onTap,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: ControlSizes.minTouchTarget,
                                height: ControlSizes.minTouchTarget,
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(
                                    Radii.button,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  size: IconSizes.md,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                            if (completed && onQuizTap != null) ...[
                              const SizedBox(width: Spacing.s),
                              GestureDetector(
                                key: Key('unitQuizButton_${unit.id}'),
                                onTap: onQuizTap,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: ControlSizes.minTouchTarget,
                                  height: ControlSizes.minTouchTarget,
                                  decoration: BoxDecoration(
                                    color: AppColors.warnBg,
                                    borderRadius: BorderRadius.circular(
                                      Radii.button,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.quiz_outlined,
                                    size: IconSizes.md,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitBadge extends StatelessWidget {
  const _UnitBadge({
    required this.number,
    required this.locked,
    required this.completed,
  });

  final int number;
  final bool locked;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final fill = locked ? AppColors.disabledFill : AppColors.secondary;
    return Container(
      width: ControlSizes.chipHeight,
      height: ControlSizes.chipHeight,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      alignment: Alignment.center,
      child: completed
          ? const Icon(
              Icons.check,
              size: IconSizes.m,
              color: AppColors.onSecondary,
            )
          : Text(
              '$number',
              style: TextStyle(
                fontSize: TypeScale.body,
                height: 1.0,
                fontWeight: FontWeight.bold,
                color: locked ? AppColors.disabledText : AppColors.onSecondary,
                fontFamily: 'NotoSans',
              ),
            ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ControlSizes.progressBarS,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0.0, 1.0).toDouble(),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(Radii.chip),
          ),
        ),
      ),
    );
  }
}

class _StoriesCard extends StatelessWidget {
  const _StoriesCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('storiesCard'),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const StoriesScreen())),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: AppColors.warnBg,
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: const Row(
          children: [
            Icon(Icons.book, size: IconSizes.md, color: AppColors.primary),
            SizedBox(width: Spacing.m),
            Text(
              'Stories',
              style: TextStyle(
                fontSize: TypeScale.title,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontFamily: 'NotoSans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Village strip: a small row of Igbo prop illustrations that adds life
/// to the bottom of the learn path.
class _CultureStrip extends StatelessWidget {
  const _CultureStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      key: Key('cultureStrip'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        PropSpot(name: 'yam', size: AvatarSizes.chat),
        PropSpot(name: 'lion', size: AvatarSizes.chat),
        PropSpot(name: 'palm', size: AvatarSizes.chat),
        PropSpot(name: 'kolanut', size: AvatarSizes.chat),
        PropSpot(name: 'ogene', size: AvatarSizes.chat),
      ],
    );
  }
}
