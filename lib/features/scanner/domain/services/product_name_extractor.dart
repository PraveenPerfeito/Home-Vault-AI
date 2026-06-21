/// Extracts a product name from raw OCR text using scoring heuristics.
///
/// Heuristic: product names on packaging tend to be short (2–5 words),
/// mostly alphabetic, and often in ALL CAPS or Title Case.
class ProductNameExtractor {
  ProductNameExtractor._();

  // Lines containing these patterns are unlikely to be product names
  static final _skipPatterns = RegExp(
    r'(?:lot\s*(?:no\.?|#)|batch\s*(?:no\.?|#)|l[/\.]n\.?|mfg\.?|mfd\.?'
    r'|net\s*(?:weight|wt)|www\.|https?:|tel\s*:|ph\s*:'
    r'|manufactured\s*by|distributed\s*by|marketed\s*by|imported\s*by|packed\s*by)',
    caseSensitive: false,
  );

  // Lines that look like dates or labels are skipped
  static final _dateLike = RegExp(
    r'(?:\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}'
    r'|\d{1,2}[/\-]\d{4}'
    r'|(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*[\s\-]\d{4}'
    r'|(?:exp(?:iry)?|mfg|mfd|bb)\s*[:\.])',
    caseSensitive: false,
  );

  static String? extract(String rawText) {
    if (rawText.trim().isEmpty) return null;

    String? bestLine;
    double bestScore = 0;

    for (final line in rawText.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final score = _scoreLine(trimmed);
      if (score > bestScore) {
        bestScore = score;
        bestLine = trimmed;
      }
    }

    if (bestLine == null || bestScore < 0.3) return null;
    return bestLine.length > 100 ? bestLine.substring(0, 100).trim() : bestLine;
  }

  static double _scoreLine(String line) {
    if (line.length < 3 || line.length > 120) return 0;
    if (_skipPatterns.hasMatch(line)) return 0;
    // Pure date lines with no word context are skipped
    if (_dateLike.hasMatch(line) && !_hasEnoughWords(line)) return 0;

    final letters =
        line.split('').where((c) => RegExp(r'[a-zA-Z]').hasMatch(c)).length;
    final letterRatio = letters / line.length;
    if (letterRatio < 0.4) return 0; // too many digits / symbols

    final words =
        line.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final wordCount = words.length;

    final double wordScore;
    if (wordCount == 1) {
      wordScore = 0.4;
    } else if (wordCount <= 5)
      wordScore = 1.0;
    else if (wordCount <= 8)
      wordScore = 0.7;
    else
      wordScore = 0.3;

    final double lengthScore;
    if (line.length >= 6 && line.length <= 40) {
      lengthScore = 1.0;
    } else if (line.length < 6)
      lengthScore = 0.4;
    else if (line.length <= 80)
      lengthScore = 0.6;
    else
      lengthScore = 0.2;

    // Bonus for ALL-CAPS words (common on product labels)
    final uppercaseCount = words
        .where(
          (w) =>
              w.length > 1 &&
              w == w.toUpperCase() &&
              RegExp(r'[A-Z]').hasMatch(w),
        )
        .length;
    final double uppercaseBonus = (uppercaseCount * 0.15).clamp(0, 0.4);

    return (letterRatio * 0.3 +
            wordScore * 0.4 +
            lengthScore * 0.3 +
            uppercaseBonus)
        .clamp(0.0, 1.0);
  }

  static bool _hasEnoughWords(String line) {
    return line
            .trim()
            .split(RegExp(r'\s+'))
            .where((w) => RegExp(r'^[a-zA-Z]{3,}$').hasMatch(w))
            .length >=
        2;
  }
}
