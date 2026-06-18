import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:home_vault/core/error/app_exception.dart';

/// Wraps Google ML Kit TextRecognizer to return raw OCR text.
///
/// The recognizer is created and closed per call so there is no leaked
/// native resource across scans.
class ScannerDatasource {
  const ScannerDatasource();

  Future<String> recogniseText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);
      return result.text;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'Could not read the label. Please try again with a clearer photo.',
        cause: e,
      );
    } finally {
      await recognizer.close();
    }
  }
}
