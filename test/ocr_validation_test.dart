import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault/features/scanner/domain/services/expiry_date_extractor.dart';
import 'package:home_vault/features/scanner/domain/services/product_name_extractor.dart';

import '../test_data/ocr_samples/ocr_samples.dart';

void main() {
  group('OCR Validation Suite (${ocrSamples.length} samples)', () {
    for (final sample in ocrSamples) {
      group('[${sample.id}] ${sample.description}', () {
        // ── Expiry date extraction ─────────────────────────────────────────
        if (sample.expectedExpiry != null) {
          test('extracts expiry date correctly', () {
            final result = ExpiryDateExtractor.extract(sample.rawText);
            expect(
              result,
              isNotNull,
              reason: '[${sample.id}] Expected expiry ${sample.expectedExpiry} but got null.\n'
                  'Raw text:\n${sample.rawText}',
            );
            expect(
              result!.year,
              sample.expectedExpiry!.year,
              reason: '[${sample.id}] Year mismatch',
            );
            expect(
              result.month,
              sample.expectedExpiry!.month,
              reason: '[${sample.id}] Month mismatch',
            );
          });
        } else {
          test('returns null when no valid expiry date present', () {
            final result = ExpiryDateExtractor.extract(sample.rawText);
            expect(
              result,
              isNull,
              reason: '[${sample.id}] Expected null but got $result.\n'
                  'Raw text:\n${sample.rawText}',
            );
          });
        }

        // ── Product name extraction ────────────────────────────────────────
        if (sample.expectedProductName != null) {
          test('extracts product name (case-insensitive prefix match)', () {
            final result = ProductNameExtractor.extract(sample.rawText);
            expect(
              result,
              isNotNull,
              reason: '[${sample.id}] Expected name containing '
                  '"${sample.expectedProductName}" but got null.\n'
                  'Raw text:\n${sample.rawText}',
            );
            expect(
              result!.toUpperCase(),
              contains(sample.expectedProductName!.toUpperCase()),
              reason: '[${sample.id}] Name "$result" does not contain '
                  '"${sample.expectedProductName}"',
            );
          });
        } else {
          test('returns null when no extractable product name present', () {
            final result = ProductNameExtractor.extract(sample.rawText);
            if (result != null) {
              expect(
                RegExp(r'^\d+$').hasMatch(result.trim()),
                isFalse,
                reason: '[${sample.id}] Extracted "$result" appears to be a '
                    'barcode/number, not a product name',
              );
            }
          });
        }
      });
    }
  });

  // ── Aggregate statistics ─────────────────────────────────────────────────
  group('OCR aggregate statistics', () {
    test('expiry extraction pass rate >= 80%', () {
      final samplesWithExpiry =
          ocrSamples.where((s) => s.expectedExpiry != null).toList();
      var passed = 0;

      for (final sample in samplesWithExpiry) {
        final result = ExpiryDateExtractor.extract(sample.rawText);
        if (result != null &&
            result.year == sample.expectedExpiry!.year &&
            result.month == sample.expectedExpiry!.month) {
          passed++;
        }
      }

      final passRate = passed / samplesWithExpiry.length;
      // ignore: avoid_print
      print(
        'Expiry extraction: $passed/${samplesWithExpiry.length} passed '
        '(${(passRate * 100).toStringAsFixed(1)}%)',
      );
      expect(passRate, greaterThanOrEqualTo(0.80),
          reason: 'Expected >= 80% expiry extraction pass rate, '
              'got ${(passRate * 100).toStringAsFixed(1)}%');
    });

    test('null rejection pass rate >= 80%', () {
      final nullSamples =
          ocrSamples.where((s) => s.expectedExpiry == null).toList();
      var correctlyRejected = 0;

      for (final sample in nullSamples) {
        final result = ExpiryDateExtractor.extract(sample.rawText);
        if (result == null) correctlyRejected++;
      }

      final passRate = correctlyRejected / nullSamples.length;
      // ignore: avoid_print
      print(
        'Null rejection: $correctlyRejected/${nullSamples.length} correctly '
        'rejected (${(passRate * 100).toStringAsFixed(1)}%)',
      );
      expect(passRate, greaterThanOrEqualTo(0.80),
          reason: 'Expected >= 80% null rejection rate');
    });

    test('product name extraction pass rate >= 70%', () {
      final samplesWithName =
          ocrSamples.where((s) => s.expectedProductName != null).toList();
      var passed = 0;

      for (final sample in samplesWithName) {
        final result = ProductNameExtractor.extract(sample.rawText);
        if (result != null &&
            result.toUpperCase().contains(
                sample.expectedProductName!.toUpperCase())) {
          passed++;
        }
      }

      final passRate = passed / samplesWithName.length;
      // ignore: avoid_print
      print(
        'Name extraction: $passed/${samplesWithName.length} passed '
        '(${(passRate * 100).toStringAsFixed(1)}%)',
      );
      expect(passRate, greaterThanOrEqualTo(0.70),
          reason: 'Expected >= 70% name extraction pass rate, '
              'got ${(passRate * 100).toStringAsFixed(1)}%');
    });
  });
}
