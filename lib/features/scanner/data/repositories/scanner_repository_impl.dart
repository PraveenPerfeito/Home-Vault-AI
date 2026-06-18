import 'package:home_vault/core/error/app_exception.dart';
import 'package:home_vault/features/scanner/data/datasources/scanner_datasource.dart';
import 'package:home_vault/features/scanner/domain/entities/scan_result.dart';
import 'package:home_vault/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:home_vault/features/scanner/domain/services/expiry_date_extractor.dart';
import 'package:home_vault/features/scanner/domain/services/product_name_extractor.dart';

class ScannerRepositoryImpl implements ScannerRepository {
  const ScannerRepositoryImpl(this._datasource);

  final ScannerDatasource _datasource;

  @override
  Future<ScanResult> processImage(String imagePath) async {
    try {
      final rawText = await _datasource.recogniseText(imagePath);
      if (rawText.trim().isEmpty) {
        throw const AppException(
          'No text detected. Try again with a clearer, well-lit photo.',
        );
      }
      return ScanResult(
        rawText: rawText,
        extractedName: ProductNameExtractor.extract(rawText),
        extractedExpiry: ExpiryDateExtractor.extract(rawText),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Could not read the label. Please try again.', cause: e);
    }
  }
}
