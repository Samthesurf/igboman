# Igboman

Learn Igbo from zero, Duolingo style. Lessons climb from the 36-letter alphabet upward, with graded stories and a Gemini-powered tutor named Ada who chats with you in Igbo.

## Features

- 9 units, 45 lessons, 235 exercises: alphabet (underdots ị ọ ụ, nasal ṅ, digraphs), vowels and tones, greetings, numbers 0-20, pronouns and possessives, family, verbs, simple sentences, conversation.
- Exercise types: multiple choice (both directions), tap-pair matching, fill-in-the-blank, typed translation with an on-screen diacritic bar.
- Story mode: 7 graded readers (units 3-9) with a recurring cast (Ada, Obi, Nna, Mama, Mbe the tortoise). Every story word is checked against the learner's level by an automated lexical-control test.
- Avatar chat: talk to Ada, a patient Igbo tutor grounded in Standard Igbo (Igbo Izugbe), restricted to your learned vocabulary. The comic speech bubble expands live as she streams her reply.
- Progress: XP, daily streak (one grace day), unit unlocks, lesson/story completion. Stored locally as a single versioned JSON payload (shared_preferences).
- Offline: all lessons and stories work without internet. Chat and story talk need the API key.
- Flat design: light brown, green, cream palette, Material 3, Noto Sans (bundled), zero gradients, zero shadows, spacing enforced on a 4px grid by an analyzer-based audit test.

## Platforms

- Android (build on your machine with the Android SDK)
- Linux desktop
- The codebase is standard Flutter; Windows/macOS likely work but are untested.

## Run

The Gemini API key is never in the source. Resolution order: `--dart-define=GEMINI_API_KEY=...`, then `GEMINI_API_KEY`, then `GOOGLE_GENAI_API_KEY` environment variables.

Convenient way: keep the key in a `.env` file at the repo root (copy `.env.example` to `.env` and fill it in); `.env` is gitignored.

```bash
flutter run -d linux --dart-define-from-file=.env
flutter build apk --release --dart-define-from-file=.env
```

Linux:

```bash
export GEMINI_API_KEY=your_key
flutter run -d linux
# or a release build:
flutter build linux --release
# bundle: build/linux/x64/release/bundle/igboman
```

Android:

```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=your_key
```

A quick live check of the tutor service (uses the env key, prints only the tutor reply):

```bash
GEMINI_API_KEY=your_key dart run tool/smoke_gemini.dart
```

Headless smoke launch of the built Linux binary:

```bash
xvfb-run -a ./build/linux/x64/release/bundle/igboman --smoke-test
```

## Develop

```bash
flutter pub get
flutter analyze   # must be: No issues found
flutter test      # full suite (unit, widget, integrity, lexical control, design audit)
```

Notable tests:

- `test/curriculum_test.dart`: 36-letter alphabet, lesson/question integrity, no em/en dashes.
- `test/story_integrity_test.dart`: lexical control, every story word within the learner's level.
- `test/design_audit_test.dart`: spacing multiples of 4, zero gradients, zero shadows, token-only sizes.
- `test/chat_widget_test.dart`: chat flows against a fake tutor; no network in tests.

## Architecture

```
lib/
  api_config.dart              key resolution only (no secrets)
  app.dart  main.dart
  theme/  app_theme.dart  dimens.dart   palette + design tokens
  models/ lesson, unit, story, progress, chat message
  data/   alphabet.dart  curriculum.dart  units/ (1-9)  stories/ (3-9)
  services/ tutor_service, gemini_tutor_service, prompt_builder, progress_service, answer_checker
  state/  app_state.dart        XP, streak, unlocks, persistence
  screens/ home (unit map), lesson, chat, story
  widgets/ avatar_view, speech_bubble, diacritic_bar, tappable_text, flat_button, content_box, ...
tool/
  flatten_avatar.py            avatar art flatten pipeline (image QA)
  smoke_gemini.dart            live tutor smoke test
```

- Tutor model: `gemini-3.1-flash-lite` via the `googleai_dart` package (the official
  `google_generative_ai` Dart SDK is deprecated; `firebase_ai` has no Linux support). The
  `TutorService` interface is the seam if the SDK ever changes.
- The Gemini key is client-side by design for this personal app. Before any public release:
  move chat behind a proxy or Firebase AI Logic, and have a native Igbo speaker review the
  curriculum and stories. Sentence audio (TTS) is the planned next step.

## Colors

Primary brown `#A9744F`, green accent `#008751`, cream background `#FBF6EF`, white surfaces,
terracotta `#C75B39` for errors. Full token list in `lib/theme/dimens.dart` and
`lib/theme/app_theme.dart`.