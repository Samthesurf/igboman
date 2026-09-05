import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/stories.dart';
import '../models/story.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../widgets/avatar_view.dart';
import '../widgets/content_box.dart';
import '../widgets/story_card.dart';
import 'story_screen.dart';

/// Full-screen list of all graded stories, one per unit from unit 3 to 9.
///
/// Stories stay locked until their unit is unlocked. Tapping an unlocked
/// story opens the [StoryScreen] reader; locked cards are inert.
class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Stories',
          style: TextStyle(
            fontSize: TypeScale.title,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'NotoSans',
          ),
        ),
      ),
      body: const StoriesList(),
    );
  }
}

/// The story list body, shared by the Stories tab on the home screen and the
/// full-screen [StoriesScreen].
class StoriesList extends StatelessWidget {
  const StoriesList({super.key});

  void _openStory(BuildContext context, Story story) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => StoryScreen(story: story)));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return ContentBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.m),
          const Text(
            'Akụkọ',
            style: TextStyle(
              fontSize: TypeScale.headline,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(height: Spacing.xs),
          const Text(
            'Short Igbo stories that grow with your vocabulary.',
            style: TextStyle(
              fontSize: TypeScale.bodySmall,
              color: AppColors.textSecondary,
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(height: Spacing.m),
          const _FamilyStrip(),
          const SizedBox(height: Spacing.m),
          const SizedBox(height: Spacing.lg),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: Spacing.xl),
              children: [
                for (final story in stories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.s),
                    child: StoryCard(
                      story: story,
                      unlocked: appState.unitIsUnlocked(story.unitId),
                      onTap: () {
                        if (appState.unitIsUnlocked(story.unitId)) {
                          _openStory(context, story);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The story cast: Ada, the kid, Nna, Mama and Mbe in one strip above
/// the story list.
class _FamilyStrip extends StatelessWidget {
  const _FamilyStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      key: Key('familyStrip'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        AvatarView(assetPath: 'assets/images/ada.jpg', initial: 'A'),
        AvatarView(assetPath: 'assets/images/kid.jpg', initial: 'O'),
        AvatarView(assetPath: 'assets/images/nna.jpg', initial: 'N'),
        AvatarView(assetPath: 'assets/images/mama.jpg', initial: 'M'),
        AvatarView(assetPath: 'assets/images/mbe.jpg', initial: 'M'),
      ],
    );
  }
}
