import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_vault/core/router/app_router.dart';
import 'package:home_vault/core/theme/app_colors.dart';
import 'package:home_vault/features/auth/presentation/providers/auth_providers.dart';
import 'package:home_vault/features/items/domain/entities/item.dart';
import 'package:home_vault/features/items/presentation/providers/items_providers.dart';
import 'package:home_vault/features/items/presentation/widgets/item_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(itemsStreamProvider);
    try {
      await ref
          .read(itemsStreamProvider.future)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // timeout or network error — refresh indicator still dismisses
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final itemsAsync = ref.watch(itemsStreamProvider);
    final dashboard = ref.watch(expiryDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notification settings',
            onPressed: () => context.push(AppRoutes.notificationSettings),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authActionsProvider.notifier).signOut();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      user?.isAnonymous == true ? 'Exit Guest' : 'Sign Out',
                    ),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  _initials(user?.nameOrEmail),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(onRetry: _onRefresh),
          data: (_) => dashboard.isEmpty
              ? _EmptyDashboard(onAddItem: () => _showAddOptions(context))
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // ── Summary cards ──────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: _SummaryRow(dashboard: dashboard),
                        ),
                      ),

                      // ── Expired ────────────────────────────────────────
                      ..._section(
                        context: context,
                        title: 'Expired',
                        icon: Icons.warning_rounded,
                        color: AppColors.expiryExpired,
                        items: dashboard.expired,
                      ),

                      // ── Expiring Today ─────────────────────────────────
                      ..._section(
                        context: context,
                        title: 'Expiring Today',
                        icon: Icons.alarm_rounded,
                        color: AppColors.expirySoon7,
                        items: dashboard.expiringToday,
                      ),

                      // ── Within 7 Days ──────────────────────────────────
                      ..._section(
                        context: context,
                        title: 'Expiring Within 7 Days',
                        icon: Icons.schedule_outlined,
                        color: AppColors.expirySoon7,
                        items: dashboard.expiringWeek,
                      ),

                      // ── Within 30 Days ─────────────────────────────────
                      ..._section(
                        context: context,
                        title: 'Expiring Within 30 Days',
                        icon: Icons.calendar_month_outlined,
                        color: AppColors.expirySoon30,
                        items: dashboard.expiringMonth,
                      ),

                      // ── Recently Added ─────────────────────────────────
                      ..._section(
                        context: context,
                        title: 'Recently Added',
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.primary,
                        items: dashboard.recentlyAdded,
                      ),

                      // Bottom padding so FAB doesn't cover last item
                      const SliverToBoxAdapter(child: SizedBox(height: 88)),
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Builds a section header + item list. Returns an empty iterable when
  /// [items] is empty so no header is rendered for empty sections.
  Iterable<Widget> _section({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required List<Item> items,
  }) {
    if (items.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: _SectionHeader(
          title: title,
          icon: icon,
          color: color,
          count: items.length,
        ),
      ),
      SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ItemCard(
            item: items[i],
            onTap: () => context.push(
              AppRoutes.editItem(items[i].id),
              extra: items[i],
            ),
            onDelete: () => _confirmDelete(context, items[i]),
          ),
        ),
      ),
    ];
  }

  void _confirmDelete(BuildContext context, Item item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Remove "${item.name}" from your vault?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(itemActionsProvider.notifier).deleteItem(item);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.document_scanner_outlined),
            title: const Text('Scan Product'),
            subtitle: const Text('Auto-read expiry date from a photo'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.scanner);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_note_outlined),
            title: const Text('Add Manually'),
            subtitle: const Text('Enter product details by hand'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.addItem);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final ExpiryDashboardData dashboard;

  const _SummaryRow({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryCard(
          label: 'Total',
          value: '${dashboard.totalCount}',
          icon: Icons.inventory_2_outlined,
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        _SummaryCard(
          label: 'Expiring Soon',
          value: '${dashboard.expiringSoonCount}',
          icon: Icons.schedule_outlined,
          color: AppColors.warning,
        ),
        const SizedBox(width: 10),
        _SummaryCard(
          label: 'Expired',
          value: '${dashboard.expiredCount}',
          icon: Icons.warning_amber_outlined,
          color: AppColors.error,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _EmptyDashboard extends StatelessWidget {
  final VoidCallback onAddItem;

  const _EmptyDashboard({required this.onAddItem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: AppColors.grey200,
            ),
            const SizedBox(height: 16),
            Text(
              'Your vault is empty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.grey400,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking expiry dates by scanning\na product label or adding items manually.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey400,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add),
              label: const Text('Add First Item'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: AppColors.grey200),
            const SizedBox(height: 16),
            Text(
              'Failed to load items',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.grey400),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
