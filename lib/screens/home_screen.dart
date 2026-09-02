import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/curriculum.dart';
import '../models/unit.dart';
import '../services/gemini_tutor_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../widgets/avatar_view.dart';
import '../widgets/content_box.dart';
import '../widgets/flat_button.dart';
import '../widgets/streak_chip.dart';
import '../widgets/xp_chip.dart';
import 'chat_screen.dart';
import 'lesson_screen.dart';
import 'stories_screen.dart';

const double _desktopBreakpoint = 800;
const double _sideRailWidth = 176;
const double _connectorLineWidth = 2;

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

    final pathItems = <Widget>[];
    for (var i = 0; i < units.length; i++) {
      if (i > 0) {
        pathItems.add(const _UnitConnector());
      }
      final unit = units[i];
      pathItems.add(
        _UnitCard(
          unit: unit,
          isCurrent: unit.id == currentUnitId,
          locked: !appState.unitIsUnlocked(unit.id),
          completed: appState.unitFullyCompleted(unit.id),
          progressFraction: _progressFraction(appState, unit),
          onTap: () => _onUnitTap(unit, appState),
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
              padding: const EdgeInsets.only(bottom: Spacing.xl),
              children: [
                ...pathItems,
                const SizedBox(height: Spacing.xl),
                const _StoriesCard(),
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
              assetPath: 'assets/images/ada.png',
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
      indicatorColor: AppColors.warnBg,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'Learn',
        ),
        NavigationDestination(
          icon: Icon(Icons.book_outlined),
          selectedIcon: Icon(Icons.book),
          label: 'Stories',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
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

class _UnitConnector extends StatelessWidget {
  const _UnitConnector();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        left: Spacing.md + ControlSizes.chipHeight / 2 - 1,
      ),
      child: SizedBox(
        height: Spacing.m,
        child: SizedBox(
          width: _connectorLineWidth,
          height: Spacing.m,
          child: ColoredBox(color: AppColors.cardBorder),
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.isCurrent,
    required this.locked,
    required this.completed,
    required this.progressFraction,
    required this.onTap,
  });

  final Unit unit;
  final bool isCurrent;
  final bool locked;
  final bool completed;
  final double progressFraction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.card),
          child: Stack(
            children: [
              if (isCurrent)
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: 4,
                    child: ColoredBox(color: AppColors.primary),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  children: [
                    _UnitBadge(
                      number: unit.id,
                      locked: locked,
                      completed: completed,
                    ),
                    const SizedBox(width: Spacing.m),
                    Expanded(
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
                    const SizedBox(width: Spacing.m),
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
                      GestureDetector(
                        onTap: onTap,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: ControlSizes.minTouchTarget,
                          height: ControlSizes.minTouchTarget,
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(Radii.button),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            size: IconSizes.md,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
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
