import 'package:flutter/material.dart';
import 'package:home_vault/core/theme/app_colors.dart';
import 'package:home_vault/features/items/domain/entities/item.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final days = item.daysUntilExpiry;
    final statusColor = _expiryColor(days);
    final statusLabel = _expiryLabel(days);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Category emoji badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    item.category.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.category.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.grey400),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Expiry status badge
              if (item.expiryDate != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _shortDate(item.expiryDate!),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.grey400),
                    ),
                  ],
                ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.grey400,
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _expiryColor(int? days) {
    if (days == null) return AppColors.grey400;
    if (days < 0) return AppColors.expiryExpired;
    if (days <= 7) return AppColors.expirySoon7;
    if (days <= 30) return AppColors.expirySoon30;
    return AppColors.expiryGood;
  }

  String _expiryLabel(int? days) {
    if (days == null) return 'No expiry';
    if (days < 0) return 'Expired';
    if (days == 0) return 'Today!';
    if (days == 1) return '1 day';
    if (days <= 30) return '$days days';
    final months = (days / 30).round();
    return '$months mo';
  }

  String _shortDate(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}
