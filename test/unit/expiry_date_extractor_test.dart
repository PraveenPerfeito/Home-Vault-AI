import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault/features/scanner/domain/services/expiry_date_extractor.dart';

void main() {
  group('ExpiryDateExtractor', () {
    group('Pattern 1 — DD/MM/YYYY', () {
      test('slash separator', () {
        final result = ExpiryDateExtractor.extract('15/06/2027');
        expect(result, DateTime(2027, 6, 15));
      });

      test('dash separator', () {
        final result = ExpiryDateExtractor.extract('15-06-2027');
        expect(result, DateTime(2027, 6, 15));
      });

      test('dot separator', () {
        final result = ExpiryDateExtractor.extract('15.06.2027');
        expect(result, DateTime(2027, 6, 15));
      });

      test('invalid month > 12 rejected', () {
        final result = ExpiryDateExtractor.extract('15/13/2027');
        expect(result, isNull);
      });

      // Regression tests for span-tracking fix (Phase 3.6):
      // Invalid DD/MM/YYYY must reserve the span so MM/YYYY cannot re-match it.
      test('invalid day > 31 rejected — span reserved, MM/YYYY not extracted', () {
        final result = ExpiryDateExtractor.extract('32/06/2027');
        expect(result, isNull);
      });

      test('Feb 31 rejected — span reserved, MM/YYYY not extracted', () {
        final result = ExpiryDateExtractor.extract('31/02/2027');
        expect(result, isNull);
      });

      test('invalid day with surrounding context still rejected', () {
        final result = ExpiryDateExtractor.extract('Exp: 32/08/2027');
        expect(result, isNull);
      });

      test('Feb 28 accepted', () {
        final result = ExpiryDateExtractor.extract('28/02/2027');
        expect(result, DateTime(2027, 2, 28));
      });
    });

    group('Pattern 2 — MM/YYYY', () {
      test('slash separator', () {
        final result = ExpiryDateExtractor.extract('06/2027');
        expect(result, isNotNull);
        expect(result!.month, 6);
        expect(result.year, 2027);
      });

      test('dash separator', () {
        final result = ExpiryDateExtractor.extract('06-2027');
        expect(result, isNotNull);
        expect(result!.month, 6);
        expect(result.year, 2027);
      });

      test('invalid month 13 rejected', () {
        final result = ExpiryDateExtractor.extract('13/2027');
        expect(result, isNull);
      });

      test('span tracking: 15/06/2027 does NOT double-match as 06/2027', () {
        // When DD/MM/YYYY matches, the MM/YYYY portion of the same span is skipped
        final result = ExpiryDateExtractor.extract('15/06/2027');
        // Should return the full DD/MM/YYYY date, not a separate MM/YYYY match
        expect(result, DateTime(2027, 6, 15));
      });
    });

    group('Pattern 3 — MMM YYYY', () {
      test('space separator', () {
        final result = ExpiryDateExtractor.extract('Jun 2027');
        expect(result, isNotNull);
        expect(result!.month, 6);
        expect(result.year, 2027);
      });

      test('dash separator', () {
        final result = ExpiryDateExtractor.extract('Jun-2027');
        expect(result, isNotNull);
        expect(result!.month, 6);
        expect(result.year, 2027);
      });

      test('dot separator', () {
        final result = ExpiryDateExtractor.extract('Jun.2027');
        expect(result, isNotNull);
        expect(result!.month, 6);
        expect(result.year, 2027);
      });

      test('case insensitive — lowercase', () {
        final result = ExpiryDateExtractor.extract('jun 2027');
        expect(result, isNotNull);
        expect(result!.month, 6);
      });

      test('case insensitive — uppercase', () {
        final result = ExpiryDateExtractor.extract('JUN 2027');
        expect(result, isNotNull);
        expect(result!.month, 6);
      });

      test('all 12 abbreviated months are recognised', () {
        final months = {
          'Jan': 1,
          'Feb': 2,
          'Mar': 3,
          'Apr': 4,
          'May': 5,
          'Jun': 6,
          'Jul': 7,
          'Aug': 8,
          'Sep': 9,
          'Oct': 10,
          'Nov': 11,
          'Dec': 12,
        };
        for (final entry in months.entries) {
          final result = ExpiryDateExtractor.extract('${entry.key} 2027');
          expect(result, isNotNull,
              reason: '${entry.key} should be recognised');
          expect(result!.month, entry.value,
              reason: '${entry.key} should map to month ${entry.value}');
        }
      });

      test('full month name', () {
        final result = ExpiryDateExtractor.extract('June 2027');
        expect(result, isNotNull);
        expect(result!.month, 6);
        expect(result.year, 2027);
      });
    });

    group('Keywords', () {
      test('exp: prefix (lowercase)', () {
        final result = ExpiryDateExtractor.extract('exp: 15/06/2027');
        expect(result, DateTime(2027, 6, 15));
      });

      test('EXP: prefix (uppercase)', () {
        final result = ExpiryDateExtractor.extract('EXP: 15/06/2027');
        expect(result, DateTime(2027, 6, 15));
      });

      test('best before', () {
        final result =
            ExpiryDateExtractor.extract('best before 15/06/2027');
        expect(result, DateTime(2027, 6, 15));
      });

      test('use by', () {
        final result = ExpiryDateExtractor.extract('use by 15/06/2027');
        expect(result, DateTime(2027, 6, 15));
      });

      test('use before', () {
        final result =
            ExpiryDateExtractor.extract('use before 15/06/2027');
        expect(result, DateTime(2027, 6, 15));
      });

      test('b.b.d.', () {
        final result = ExpiryDateExtractor.extract('b.b.d. 15/06/2027');
        expect(result, DateTime(2027, 6, 15));
      });

      test('expires', () {
        final result = ExpiryDateExtractor.extract('expires 15/06/2027');
        expect(result, DateTime(2027, 6, 15));
      });

      test('keyword date preferred over non-keyword date in multiline text', () {
        // Two dates present; the keyword-tagged one should win
        const text = '''
manufactured: 01/01/2025
exp: 15/06/2027
''';
        final result = ExpiryDateExtractor.extract(text);
        expect(result, DateTime(2027, 6, 15));
      });
    });

    group('_bestDate selection', () {
      test('returns earliest future date when multiple future dates present', () {
        const text = '15/06/2027 15/06/2028';
        final result = ExpiryDateExtractor.extract(text);
        expect(result, isNotNull);
        expect(result!.year, 2027);
      });

      test('returns most recent past date when all dates are in the past', () {
        // Both past; 2024 is more recent than 2022
        const text = '15/06/2022 15/06/2024';
        final result = ExpiryDateExtractor.extract(text);
        expect(result, isNotNull);
        expect(result!.year, 2024);
      });

      test('dates outside plausible range (> 15 yr future) rejected', () {
        // 2026 + 15 = 2041, so 2042 is outside range
        final result = ExpiryDateExtractor.extract('15/06/2042');
        expect(result, isNull);
      });

      test('dates more than 2 years in the past rejected as implausible', () {
        // Current date 2026-06-21; 2023 is 3 years past → rejected
        final result = ExpiryDateExtractor.extract('15/06/2023');
        expect(result, isNull);
      });
    });

    group('Year bounds', () {
      test('year 2019 rejected (below _validYear lower bound 2020)', () {
        final result = ExpiryDateExtractor.extract('15/06/2019');
        expect(result, isNull);
      });

      test('year 2020 accepted (at _validYear lower bound)', () {
        // 2020 is in the past but within valid year range;
        // plausibility (within 2 yr past) determines final acceptance
        // 2020 is > 2 years before 2026, so expect null after plausibility check
        final result = ExpiryDateExtractor.extract('15/06/2020');
        expect(result, isNull);
      });

      test('year 2040 accepted (at _validYear upper bound)', () {
        final result = ExpiryDateExtractor.extract('15/06/2040');
        expect(result, isNotNull);
        expect(result!.year, 2040);
      });

      test('year 2041 rejected (above _validYear upper bound)', () {
        final result = ExpiryDateExtractor.extract('15/06/2041');
        expect(result, isNull);
      });
    });

    group('Edge cases', () {
      test('empty string returns null', () {
        final result = ExpiryDateExtractor.extract('');
        expect(result, isNull);
      });

      test('whitespace-only string returns null', () {
        final result = ExpiryDateExtractor.extract('   \n\t  ');
        expect(result, isNull);
      });

      test('text with no date returns null', () {
        final result =
            ExpiryDateExtractor.extract('Product Name: Organic Oats');
        expect(result, isNull);
      });

      test('noisy multiline OCR text extracts correct expiry date', () {
        const text = '''
ORGANIC OATS 500g
Lot No: A1234
Mfg: 01/2026
EXP: 01/2028
Net Wt: 500g
''';
        final result = ExpiryDateExtractor.extract(text);
        expect(result, isNotNull);
        expect(result!.year, 2028);
        expect(result.month, 1);
      });
    });
  });
}
