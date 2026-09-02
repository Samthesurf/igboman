import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/dimens.dart';

/// Splits an Igbo sentence into word widgets. Words with a known gloss are
/// shown in bold green and tappable; every other word is tappable too and
/// reports a "New word!" hint. Only the *lookup* applies elision, progressive
/// and suffix rules; the displayed text always keeps the original token.
class TokenizedText extends StatelessWidget {
  const TokenizedText({
    super.key,
    required this.text,
    required this.glosses,
    required this.showGloss,
  });

  final String text;

  /// Lookup table: lowercased token to English gloss.
  final Map<String, String> glosses;

  /// Called with the displayed word and its gloss (null when unknown).
  final void Function(String word, String? gloss) showGloss;

  /// Normalizes one token for lookup: lowercase, strip surrounding
  /// punctuation, and combine base letters with combining diacritics
  /// (underdot and tone marks) into precomposed characters.
  static String normalizeToken(String token) {
    final lower = token.trim().toLowerCase();
    var stripped = lower;
    stripped = stripped.replaceAll(RegExp(r'^[.,!?;:()]+'), '');
    stripped = stripped.replaceAll(RegExp(r'[.,!?;:()]+$'), '');
    return _combineDiacritics(stripped);
  }

  /// The lookup key for a token: [normalizeToken] plus elision, progressive
  /// and verb-suffix splitting. Returns the base/rest form used when the
  /// exact token is not in the gloss map.
  static String lookupKey(String token) {
    var key = normalizeToken(token);
    if (key.isEmpty) return key;
    // Elided clitic and progressive forms are already inflected; the rest is
    // the complete lookup word. Verb-suffix splitting applies only to plain
    // stems (e.g. "gara" -> "ga"), not to "n'elu" -> "elu".
    if (key.startsWith("n'")) {
      return key.substring(2);
    }
    if (key.startsWith('na-')) {
      return key.substring(3);
    }
    for (final suffix in _verbSuffixes) {
      if (key.endsWith(suffix) && key.length > suffix.length) {
        return key.substring(0, key.length - suffix.length);
      }
    }
    return key;
  }

  /// Pure tokenizer used by the lexical-control test: maps a sentence to the
  /// lookup key of every word, in order.
  static List<String> tokenize(String sentence) {
    final keys = <String>[];
    for (final token in sentence.split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      final key = lookupKey(token);
      if (key.isNotEmpty) keys.add(key);
    }
    return keys;
  }

  /// The raw normalized word of every token in a sentence, without applying
  /// elision, progressive or suffix rules. Used by the lexical-control test
  /// to check each displayed word against the whitelist.
  static List<String> words(String sentence) {
    final out = <String>[];
    for (final token in sentence.split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      final word = normalizeToken(token);
      if (word.isNotEmpty) out.add(word);
    }
    return out;
  }

  // Verb inflection suffixes, stripped without the dash (the stop list
  // writes them with dashes as a linguistic convention).
  static const _verbSuffixes = ['ra', 'la', 'rụ', 'lụ', 'ru', 'lu'];

  static const _diacritics = <String, String>{
    // underdot
    'i\u0323': 'ị',
    'o\u0323': 'ọ',
    'u\u0323': 'ụ',
    // acute accents
    'a\u0301': 'á',
    'e\u0301': 'é',
    'i\u0301': 'í',
    'o\u0301': 'ó',
    'u\u0301': 'ú',
    'n\u0301': 'ń',
    // grave accents
    'a\u0300': 'à',
    'e\u0300': 'è',
    'i\u0300': 'ì',
    'o\u0300': 'ò',
    'u\u0300': 'ù',
    'n\u0300': 'ǹ',
    // n with dot above
    'n\u0307': 'ṅ',
  };

  /// Combines a base letter followed by one combining mark into the
  /// precomposed character (a small NFC-like table for Igbo diacritics).
  static String _combineDiacritics(String input) {
    final buffer = StringBuffer();
    var i = 0;
    while (i < input.length) {
      final ch = input[i];
      if (i + 1 < input.length) {
        final pair = '$ch${input[i + 1]}';
        final combined = _diacritics[pair];
        if (combined != null) {
          buffer.write(combined);
          i += 2;
          continue;
        }
      }
      buffer.write(ch);
      i++;
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = text
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    return Wrap(
      spacing: Spacing.xs,
      runSpacing: Spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [for (final token in tokens) _buildToken(token)],
    );
  }

  Widget _buildToken(String token) {
    final rawKey = normalizeToken(token);
    final lookup = lookupKey(token);
    final gloss = glosses[rawKey] ?? glosses[lookup];
    final display = token;

    final TextStyle style;
    if (gloss != null) {
      style = const TextStyle(
        fontSize: TypeScale.body,
        fontWeight: FontWeight.bold,
        color: AppColors.secondary,
        fontFamily: 'NotoSans',
      );
    } else {
      style = const TextStyle(
        fontSize: TypeScale.body,
        color: AppColors.textPrimary,
        fontFamily: 'NotoSans',
        decoration: TextDecoration.underline,
        decorationColor: AppColors.textSecondary,
      );
    }

    return GestureDetector(
      onTap: () => showGloss(display, gloss),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
        child: Text(display, style: style),
      ),
    );
  }
}
