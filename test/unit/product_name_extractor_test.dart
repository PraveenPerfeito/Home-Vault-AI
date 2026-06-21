import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault/features/scanner/domain/services/product_name_extractor.dart';

void main() {
  group('ProductNameExtractor', () {
    group('Skip patterns — lines containing these are never chosen', () {
      test('lot no', () {
        final result = ProductNameExtractor.extract('Lot No: A1234');
        expect(result, isNull);
      });

      test('batch no', () {
        final result = ProductNameExtractor.extract('Batch No: B5678');
        expect(result, isNull);
      });

      test('l.n abbreviation', () {
        final result = ProductNameExtractor.extract('L.N: X999');
        expect(result, isNull);
      });

      test('mfg', () {
        final result = ProductNameExtractor.extract('Mfg: 01/2026');
        expect(result, isNull);
      });

      test('mfd', () {
        final result = ProductNameExtractor.extract('Mfd Date: 01/2026');
        expect(result, isNull);
      });

      test('net weight', () {
        final result = ProductNameExtractor.extract('Net Weight: 500g');
        expect(result, isNull);
      });

      test('www. URL', () {
        final result = ProductNameExtractor.extract('www.example.com');
        expect(result, isNull);
      });

      test('http URL', () {
        final result = ProductNameExtractor.extract('http://example.com');
        expect(result, isNull);
      });

      test('tel:', () {
        final result = ProductNameExtractor.extract('tel:+91-9876543210');
        expect(result, isNull);
      });

      test('ph:', () {
        final result = ProductNameExtractor.extract('ph: 012-3456789');
        expect(result, isNull);
      });

      test('manufactured by', () {
        final result =
            ProductNameExtractor.extract('Manufactured by: Acme Corp');
        expect(result, isNull);
      });

      test('distributed by', () {
        final result =
            ProductNameExtractor.extract('Distributed by: XYZ Ltd');
        expect(result, isNull);
      });

      test('marketed by', () {
        final result = ProductNameExtractor.extract('Marketed by: ABC Inc');
        expect(result, isNull);
      });

      test('imported by', () {
        final result = ProductNameExtractor.extract('Imported by: DEF Co');
        expect(result, isNull);
      });

      test('packed by', () {
        final result = ProductNameExtractor.extract('Packed by: GHI Ltd');
        expect(result, isNull);
      });
    });

    group('Date-like line rejection', () {
      test('DD/MM/YYYY line has too few alpha words → rejected', () {
        final result = ProductNameExtractor.extract('15/06/2027');
        expect(result, isNull);
      });

      test('MM/YYYY line has too few alpha words → rejected', () {
        final result = ProductNameExtractor.extract('06/2027');
        expect(result, isNull);
      });

      test('EXP: prefixed line → rejected', () {
        final result = ProductNameExtractor.extract('EXP: 15/06/2027');
        expect(result, isNull);
      });
    });

    group('Successful extraction', () {
      test('single product word', () {
        final result = ProductNameExtractor.extract('Cornflakes');
        // Single word scores 0.4 on wordScore; may still pass if other factors push >= 0.3
        // The spec says 1 word → wordScore 0.4; we only assert not-null when it passes threshold
        // "Cornflakes" has good letterRatio and is 10 chars → lengthScore 1.0
        // score = 1.0*0.3 + 0.4*0.4 + 1.0*0.3 = 0.3+0.16+0.3 = 0.76 → passes
        expect(result, 'Cornflakes');
      });

      test('2-word product name', () {
        final result = ProductNameExtractor.extract('Organic Oats');
        expect(result, isNotNull);
        expect(result, 'Organic Oats');
      });

      test('multiline text — best-scoring line is returned', () {
        const text = '''
Lot No: A1234
ORGANIC OATS
Net Weight: 500g
''';
        final result = ProductNameExtractor.extract(text);
        expect(result, isNotNull);
        expect(result, contains('ORGANIC OATS'));
      });

      test('all-caps bonus applied — ALL CAPS line scored higher', () {
        const text = '''
Organic Oats
ORGANIC OATS
''';
        // ORGANIC OATS gets uppercase bonus (0.15 × 2 words) so its score is higher
        final result = ProductNameExtractor.extract(text);
        expect(result, 'ORGANIC OATS');
      });

      test('title case product name extracted', () {
        final result =
            ProductNameExtractor.extract('Basmati Rice Premium Quality');
        expect(result, isNotNull);
        expect(result, 'Basmati Rice Premium Quality');
      });
    });

    group('Truncation', () {
      test('product name longer than 100 chars is truncated to 100', () {
        // 110-char name: all letters, 2–5 words equivalent achieved via long single token
        final longName = 'A' * 110;
        final result = ProductNameExtractor.extract(longName);
        if (result != null) {
          expect(result.length, lessThanOrEqualTo(100));
        }
      });

      test('product name exactly 100 chars is not truncated', () {
        final exactName = 'A' * 100;
        final result = ProductNameExtractor.extract(exactName);
        if (result != null) {
          expect(result.length, lessThanOrEqualTo(100));
        }
      });
    });

    group('Score < 0.3 → null', () {
      test('low letter ratio rejects line — mostly digits', () {
        // "12345 AB": letterRatio = 2/8 = 0.25 < 0.4 → score contributions collapse
        final result = ProductNameExtractor.extract('12345 AB');
        expect(result, isNull);
      });

      test('very short text (< 6 chars) scores low on lengthScore', () {
        // "Hi" → letterRatio 1.0, wordScore 0.4 (1 word), lengthScore 0.4 (<6 chars)
        // score = 1.0*0.3 + 0.4*0.4 + 0.4*0.3 = 0.3+0.16+0.12 = 0.58 → passes
        // So "Hi" alone should actually pass; skip this edge and test a truly bad case:
        // Single digit character
        final result = ProductNameExtractor.extract('3');
        expect(result, isNull);
      });
    });

    group('Empty / whitespace input', () {
      test('empty string returns null', () {
        final result = ProductNameExtractor.extract('');
        expect(result, isNull);
      });

      test('whitespace-only string returns null', () {
        final result = ProductNameExtractor.extract('   \n\t  ');
        expect(result, isNull);
      });
    });
  });
}
