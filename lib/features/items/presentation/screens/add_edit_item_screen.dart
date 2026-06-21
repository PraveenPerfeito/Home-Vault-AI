import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_vault/core/error/app_exception.dart';
import 'package:home_vault/core/theme/app_colors.dart';
import 'package:home_vault/features/items/domain/entities/item.dart';
import 'package:home_vault/features/items/presentation/providers/items_providers.dart';
import 'package:home_vault/features/items/presentation/widgets/category_chip.dart';
import 'package:home_vault/features/scanner/domain/entities/scan_result.dart';

class AddEditItemScreen extends ConsumerStatefulWidget {
  final Item? existingItem;
  final ScanResult? scanResult;

  const AddEditItemScreen({super.key, this.existingItem, this.scanResult});

  @override
  ConsumerState<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends ConsumerState<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late ItemCategory _category;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;

  // H3: tracks whether a save was explicitly initiated by the user.
  // The listener only acts on state changes that result from _save().
  bool _isSaving = false;
  late final ProviderSubscription<AsyncValue<void>> _actionsSubscription;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    final scan = widget.scanResult;
    // Pre-fill from OCR scan result when creating a new item (not editing)
    _nameController = TextEditingController(
      text: item?.name ?? scan?.extractedName ?? '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');
    _category = item?.category ?? ItemCategory.other;
    _purchaseDate = item?.purchaseDate;
    _expiryDate = item?.expiryDate ?? scan?.extractedExpiry;

    // H3: moved from build() to initState so the callback is registered once
    // and cannot trigger a spurious context.pop() on incidental widget rebuilds.
    _actionsSubscription = ref.listenManual<AsyncValue<void>>(
      itemActionsProvider,
      fireImmediately: false,
      (_, next) {
        if (!_isSaving) return;
        next.whenOrNull(
          data: (_) {
            _isSaving = false;
            if (mounted) context.pop();
          },
          error: (e, _) {
            _isSaving = false;
            if (!mounted) return;
            // H10: use sanitised message — never e.toString() which may
            // expose internal Firebase / Firestore error details.
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
    _actionsSubscription.close();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionsState = ref.watch(itemActionsProvider);
    final isLoading = actionsState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Item' : 'Add Item'),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _save,
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.scanResult != null && !_isEditing) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_fix_high_outlined,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Values pre-filled from label scan — please verify.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // H6: maxLength 100 prevents unbounded Firestore writes.
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                hintText: 'e.g. Paracetamol 500mg',
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length > 100) return 'Max 100 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Category
            Text('Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ItemCategory.values
                  .map((cat) => CategoryChip(
                        category: cat,
                        selected: _category == cat,
                        onTap: () => setState(() => _category = cat),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            // Expiry date
            _DateField(
              label: 'Expiry Date',
              date: _expiryDate,
              firstDate: DateTime(2000),
              onChanged: (d) => setState(() => _expiryDate = d),
            ),
            const SizedBox(height: 12),

            // Purchase date
            _DateField(
              label: 'Purchase Date (optional)',
              date: _purchaseDate,
              firstDate: DateTime(2000),
              onChanged: (d) => setState(() => _purchaseDate = d),
            ),
            const SizedBox(height: 20),

            // H7: maxLength 1000 prevents Firestore document size abuse.
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Keep refrigerated after opening',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    _isSaving = true;
    final notifier = ref.read(itemActionsProvider.notifier);
    final name = _nameController.text.trim();
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    if (_isEditing) {
      notifier.updateItem(widget.existingItem!.copyWith(
        name: name,
        category: _category,
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate,
        notes: notes,
      ));
    } else {
      notifier.createItem(
        name: name,
        category: _category,
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate,
        notes: notes,
      );
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateTime firstDate;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({
    required this.label,
    required this.date,
    required this.firstDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: firstDate,
          lastDate: DateTime(2099),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (date != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                  visualDensity: VisualDensity.compact,
                ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.calendar_today_outlined, size: 18),
              ),
            ],
          ),
        ),
        child: Text(
          date != null ? _format(date!) : 'Tap to select',
          style: date == null
              ? Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.grey400)
              : null,
        ),
      ),
    );
  }

  String _format(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}
