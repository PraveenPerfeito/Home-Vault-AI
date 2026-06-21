/// Extracts expiry dates from raw OCR text.
///
/// Supported formats (per Phase 3 spec):
///   MM/YYYY   MM-YYYY
///   DD/MM/YYYY  DD-MM-YYYY
///   AUG 2027  AUG-2027  (abbreviated or full month names)
class ExpiryDateExtractor {
  ExpiryDateExtractor._();

  // DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
  static final _ddmmyyyy = RegExp(
    r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})(?!\d)',
  );

  // MM/YYYY or MM-YYYY  (processed AFTER DD/MM/YYYY to avoid double-counting)
  static final _mmyyyy = RegExp(
    r'(\d{1,2})[/\-](\d{4})(?!\d)',
  );

  // MMM YYYY, MMM-YYYY, MMM.YYYY — abbreviated or full month names
  static final _mmmyyyy = RegExp(
    r'(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)[.\- ](\d{4})\b',
    caseSensitive: false,
  );

  // Keywords that identify expiry-date lines
  static final _expiryKeyword = RegExp(
    r'(?:exp(?:iry|ires)?|best\s*before|b\.?b\.?d?\.?|use\s*by|use\s*before)\b',
    caseSensitive: false,
  );

  static const _monthMap = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  static DateTime? extract(String text) {
    if (text.trim().isEmpty) return null;

    // Priority 1: lines that contain an expiry keyword
    for (final line in text.split('\n')) {
      if (_expiryKeyword.hasMatch(line)) {
        final dates = _datesFromText(line);
        if (dates.isNotEmpty) return _bestDate(dates);
      }
    }

    // Priority 2: any date anywhere in the text
    return _bestDate(_datesFromText(text));
  }

  static List<DateTime> _datesFromText(String text) {
    final results = <DateTime>[];
    // Track spans consumed by DD/MM/YYYY so MM/YYYY doesn't double-match
    final ddmmSpans = <(int, int)>[];

    // Pattern 1 — DD/MM/YYYY (most specific, process first)
    for (final m in _ddmmyyyy.allMatches(text)) {
      // Reserve span unconditionally so MM/YYYY (Pattern 2) never re-matches
      // the sub-token MM/YYYY inside a rejected DD/MM/YYYY string.
      ddmmSpans.add((m.start, m.end));
      final d = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      final y = int.tryParse(m.group(3)!);
      if (d == null || mo == null || y == null) continue;
      if (d < 1 || d > 31 || mo < 1 || mo > 12 || !_validYear(y)) continue;
      try {
        final date = DateTime(y, mo, d);
        // date.day == d validates calendar: Feb 31 normalises → mismatch rejected
        if (date.day == d) results.add(date);
      } catch (_) {}
    }

    // Pattern 2 — MM/YYYY (skip character ranges already consumed above)
    for (final m in _mmyyyy.allMatches(text)) {
      final overlaps = ddmmSpans.any((s) => m.start < s.$2 && m.end > s.$1);
      if (overlaps) continue;
      final mo = int.tryParse(m.group(1)!);
      final y = int.tryParse(m.group(2)!);
      if (mo == null || y == null) continue;
      if (mo < 1 || mo > 12 || !_validYear(y)) continue;
      results.add(DateTime(y, mo));
    }

    // Pattern 3 — MMM YYYY / MMM-YYYY (no numeric overlap possible)
    for (final m in _mmmyyyy.allMatches(text)) {
      final monthKey = m.group(1)!.toLowerCase().substring(0, 3);
      final mo = _monthMap[monthKey];
      final y = int.tryParse(m.group(2)!);
      if (mo == null || y == null || !_validYear(y)) continue;
      results.add(DateTime(y, mo));
    }

    return results;
  }

  static bool _validYear(int y) => y >= 2020 && y <= 2040;

  static DateTime? _bestDate(List<DateTime> dates) {
    if (dates.isEmpty) return null;
    final now = DateTime.now();

    // Keep only plausible dates (2 years past → 15 years future)
    final plausible = dates.where((d) {
      final diffYears = d.year - now.year;
      return diffYears >= -2 && diffYears <= 15;
    }).toList();

    if (plausible.isEmpty) return null;

    // Prefer the earliest future date (soonest expiry)
    final future = plausible.where((d) => d.isAfter(now)).toList()..sort();
    if (future.isNotEmpty) return future.first;

    // All plausible dates are in the past — return the most recent one
    plausible.sort((a, b) => b.compareTo(a));
    return plausible.first;
  }
}
