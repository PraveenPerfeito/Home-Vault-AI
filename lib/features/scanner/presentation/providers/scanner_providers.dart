import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_vault/features/scanner/data/datasources/scanner_datasource.dart';
import 'package:home_vault/features/scanner/data/repositories/scanner_repository_impl.dart';
import 'package:home_vault/features/scanner/domain/entities/scan_result.dart';
import 'package:home_vault/features/scanner/domain/repositories/scanner_repository.dart';

final _scannerDatasourceProvider = Provider<ScannerDatasource>(
  (_) => const ScannerDatasource(),
);

final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  return ScannerRepositoryImpl(ref.watch(_scannerDatasourceProvider));
});

final scanActionsProvider =
    AutoDisposeAsyncNotifierProvider<ScanActionsNotifier, ScanResult?>(
  ScanActionsNotifier.new,
);

class ScanActionsNotifier extends AutoDisposeAsyncNotifier<ScanResult?> {
  @override
  Future<ScanResult?> build() async => null;

  Future<void> scan(String imagePath) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(scannerRepositoryProvider).processImage(imagePath),
    );
  }

  void reset() => state = const AsyncData(null);
}
