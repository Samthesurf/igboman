import '../models/story.dart';
import 'stories/story_03.dart';
import 'stories/story_04.dart';
import 'stories/story_05.dart';
import 'stories/story_06.dart';
import 'stories/story_07.dart';
import 'stories/story_08.dart';
import 'stories/story_09.dart';

export 'stories/story_03.dart';
export 'stories/story_04.dart';
export 'stories/story_05.dart';
export 'stories/story_06.dart';
export 'stories/story_07.dart';
export 'stories/story_08.dart';
export 'stories/story_09.dart';

/// All graded stories, one per unit from unit 3 to unit 9.
const List<Story> stories = [
  story03,
  story04,
  story05,
  story06,
  story07,
  story08,
  story09,
];

/// Returns the story for a unit, or null when the unit has no story.
Story? storyForUnit(int unitId) {
  for (final story in stories) {
    if (story.unitId == unitId) {
      return story;
    }
  }
  return null;
}

/// Function words that are allowed in any story without appearing in the
/// unit vocabulary. Treated as lookup keys (already lowercased); verb
/// suffixes are matched as end-of-token rules, not members of this set.
const Set<String> storyStopWords = {
  'na',
  'nke',
  'a',
  'ahụ',
  'ebe',
  'mba',
  'ee',
  'dị',
  'bụ',
  'ka',
  'kwa',
  "n'",
  'na-',
  'm',
  'mụ',
  'ị',
  'ọ',
  'ya',
  'anyị',
  'unu',
  'ha',
  '-ra',
  '-la',
  '-rụ',
  '-lụ',
  '-ru',
  '-lu',
};

/// The recurring cast of the graded stories, glossed for readers so names
/// are tappable rather than flagged as unknown words.
const Map<String, String> storyCharacterGlosses = {
  'ada': 'a girl',
  'obi': 'a boy',
  'nna': 'father',
  'mama': 'mother',
  'mbe': 'tortoise',
};
