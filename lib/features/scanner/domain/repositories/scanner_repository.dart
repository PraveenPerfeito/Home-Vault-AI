import 'package:home_vault/features/scanner/domain/entities/scan_result.dart';

abstract class ScannerRepository {
  Future<ScanResult> processImage(String imagePath);
}
