import 'package:flutter/material.dart';
import 'package:home_vault/core/theme/app_colors.dart';
import 'package:home_vault/features/scanner/domain/entities/scan_result.dart';

class ScanResultCard extends StatefulWidget {
  final ScanResult result;
  final VoidCallback onUseValues;
  final VoidCallback onScanAgain;

  const ScanResultCard({
    super.key,
    required this.result,
    required this.onUseValues,
    required this.onScanAgain,
  });

  @override
  State<ScanResultCard> createState() => _ScanResultCardState();
}

class _ScanResultCardState extends State<ScanResultCard> {
  bool _showRawText = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(hasData: result.hasAnyData),
                  const Divider(height: 24),
                  _ResultRow(
                    icon: Icons.label_outline,
                    label: 'Product Name',
                    value: result.extractedName ?? 'Not detected',
                    found: result.hasName,
                  ),
                  const SizedBox(height: 12),
                  _ResultRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Expiry Date',
                    value: result.hasExpiry
                        ? _formatDate(result.extractedExpiry!)
                        : 'Not detected',
                    found: result.hasExpiry,
                  ),
                  if (result.rawText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showRawText = !_showRawText),
                      icon: Icon(
                        _showRawText ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                      ),
                      label: Text(
                        _showRawText ? 'Hide raw text' : 'Show raw text',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.grey400,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    if (_showRawText)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Text(
                          result.rawText.length > 300
                              ? '${result.rawText.substring(0, 300)}…'
                              : result.rawText,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey600,
                                    height: 1.5,
                                  ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onScanAgain,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Scan Again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.onUseValues,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _Header extends StatelessWidget {
  final bool hasData;
  const _Header({required this.hasData});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          hasData ? Icons.check_circle_outline : Icons.info_outline,
          color: hasData ? AppColors.success : AppColors.warning,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          hasData ? 'Label scanned' : 'Text found — no dates detected',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool found;

  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.found,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: found ? AppColors.primary : AppColors.grey400,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.grey400),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: found ? null : AppColors.grey400,
                      fontStyle: found ? null : FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
