import 'package:equatable/equatable.dart';

class ScanResult extends Equatable {
  final String rawText;
  final String? extractedName;
  final DateTime? extractedExpiry;

  const ScanResult({
    required this.rawText,
    this.extractedName,
    this.extractedExpiry,
  });

  bool get hasName => extractedName != null && extractedName!.isNotEmpty;
  bool get hasExpiry => extractedExpiry != null;
  bool get hasAnyData => hasName || hasExpiry;

  @override
  List<Object?> get props => [rawText, extractedName, extractedExpiry];
}
