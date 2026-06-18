import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_vault/core/error/app_exception.dart';
import 'package:home_vault/core/router/app_router.dart';
import 'package:home_vault/core/theme/app_colors.dart';
import 'package:home_vault/features/scanner/domain/entities/scan_result.dart';
import 'package:home_vault/features/scanner/presentation/providers/scanner_providers.dart';
import 'package:home_vault/features/scanner/presentation/widgets/scan_result_card.dart';
import 'package:image_picker/image_picker.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  late final ProviderSubscription<AsyncValue<ScanResult?>> _scanSubscription;

  @override
  void initState() {
    super.initState();
    // Project pattern: ref.listenManual in initState for error snackbars.
    _scanSubscription = ref.listenManual<AsyncValue<ScanResult?>>(
      scanActionsProvider,
      fireImmediately: false,
      (_, next) {
        next.whenOrNull(
          error: (e, _) {
            if (!mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(
                  e is AppException
                      ? e.message
                      : 'An error occurred. Please try again.',
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ));
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scanSubscription.close();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    if (file == null || !mounted) return;
    await ref.read(scanActionsProvider.notifier).scan(file.path);
  }

  void _reset() => ref.read(scanActionsProvider.notifier).reset();

  void _useValues(ScanResult result) =>
      context.push(AppRoutes.addItem, extra: result);

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanActionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Product')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: scanState.when(
            loading: () => const _ScanningView(),
            error: (_, __) => _PickerView(onPick: _pick),
            data: (result) => result == null
                ? _PickerView(onPick: _pick)
                : ScanResultCard(
                    result: result,
                    onUseValues: () => _useValues(result),
                    onScanAgain: _reset,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Picker view ─────────────────────────────────────────────────────────────

class _PickerView extends StatelessWidget {
  final Future<void> Function(ImageSource) onPick;
  const _PickerView({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'Point your camera at the expiry date label or choose a photo.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.grey400),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _SourceCard(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () => onPick(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SourceCard(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () => onPick(ImageSource.gallery),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Scanning / loading view ─────────────────────────────────────────────────

class _ScanningView extends StatelessWidget {
  const _ScanningView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Reading label…'),
        ],
      ),
    );
  }
}
