import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/theme/dimens.dart';
import 'package:igboman/widgets/tappable_text.dart';

void main() {
  group('TokenizedText.tokenize', () {
    test('strips surrounding punctuation and lowercases', () {
      expect(TokenizedText.tokenize('Ndewo, Obi!'), ['ndewo', 'obi']);
      expect(TokenizedText.tokenize('Kedu ka ị mere?'), ['kedu', 'ka', 'ị', 'mere']);
      expect(TokenizedText.tokenize('(Ee) mba.'), ['ee', 'mba']);
    });

    test('splits elided clitic n-prime into the rest', () {
      expect(TokenizedText.tokenize("Mbe hụ nri n'elu."), ['mbe', 'hụ', 'nri', 'elu']);
    });

    test('splits progressive na- prefix into the rest', () {
      expect(TokenizedText.tokenize('na-eri'), ['eri']);
      expect(TokenizedText.lookupKey('na-aga'), 'aga');
      // plain "na" stays a plain word
      expect(TokenizedText.lookupKey('na'), 'na');
    });

    test('keeps exact entries and splits verb suffixes for lookup', () {
      // "rie" is its own vocab entry: no suffix rule matches, key is exact
      expect(TokenizedText.tokenize('rie'), ['rie']);
      expect(TokenizedText.lookupKey('rie'), 'rie');
      // suffix path: -ra strips to base
      expect(TokenizedText.lookupKey('gara'), 'ga');
      expect(TokenizedText.lookupKey('biara'), 'bia');
      // every listed suffix strips
      for (final suffix in ['la', 'rụ', 'lụ', 'ru', 'lu']) {
        expect(TokenizedText.lookupKey('ka$suffix'), 'ka',
            reason: 'suffix -$suffix should strip from kata');
      }
      expect(TokenizedText.lookupKey('ra'), 'ra'); // too short to strip
    });

    test('combines decomposed diacritics into precomposed lookup keys', () {
      // ị as i + combining underdot
      expect(TokenizedText.normalizeToken('i\u0323'), 'ị');
      // ọ as o + combining underdot
      expect(TokenizedText.normalizeToken('o\u0323'), 'ọ');
      // ụ as u + combining underdot
      expect(TokenizedText.normalizeToken('u\u0323'), 'ụ');
      // tone marks: á à é è í ì ó ò ú ù, ń ǹ, ṅ
      expect(TokenizedText.normalizeToken('a\u0301'), 'á');
      expect(TokenizedText.normalizeToken('a\u0300'), 'à');
      expect(TokenizedText.normalizeToken('n\u0301'), 'ń');
      expect(TokenizedText.normalizeToken('n\u0307'), 'ṅ');
      // same key as the precomposed spelling
      expect(TokenizedText.lookupKey('ada'), 'ada');
      expect(TokenizedText.normalizeToken('n\u0307n\u0323'), 'ṅn\u0323');
      expect(TokenizedText.tokenize('Ada h\u1ee5 mmiri'), ['ada', 'hụ', 'mmiri']);
    });

    test('words returns raw normalized tokens without rule splits', () {
      expect(TokenizedText.words("Ndewo, Obi!"), ['ndewo', 'obi']);
      expect(TokenizedText.words("n'ụlọ"), ["n'ụlọ"]);
      expect(TokenizedText.words('na-eri'), ['na-eri']);
    });
  });

  group('TokenizedText widget', () {
    testWidgets('glossed words are bold green and report gloss on tap',
        (tester) async {
      String? tappedWord;
      String? tappedGloss;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: TokenizedText(
              text: 'Mmiri dị',
              glosses: const {'mmiri': 'water', 'dị': 'is'},
              showGloss: (word, gloss) {
                tappedWord = word;
                tappedGloss = gloss;
              },
            ),
          ),
        ),
      ));

      expect(find.text('Mmiri'), findsOneWidget);
      await tester.tap(find.text('Mmiri'));
      expect(tappedWord, 'Mmiri');
      expect(tappedGloss, 'water');

      await tester.tap(find.text('dị'));
      expect(tappedWord, 'dị');
      expect(tappedGloss, 'is');
    });

    testWidgets('unknown words report a null gloss hint', (tester) async {
      String? tappedWord;
      String? tappedGloss;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: TokenizedText(
              text: 'Obi gaa',
              glosses: const {'gaa': 'go'},
              showGloss: (word, gloss) {
                tappedWord = word;
                tappedGloss = gloss;
              },
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Obi'));
      expect(tappedWord, 'Obi');
      expect(tappedGloss, isNull);
    });
  });
}