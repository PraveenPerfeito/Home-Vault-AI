import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_vault/core/theme/app_colors.dart';
import 'package:home_vault/features/notifications/presentation/providers/notification_providers.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledAsync = ref.watch(notificationsEnabledProvider);
    final permissionAsync = ref.watch(notificationPermissionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          // ── Enable toggle ───────────────────────────────────────────────────
          enabledAsync.when(
            loading: () => const SwitchListTile(
              title: Text('Expiry Reminders'),
              subtitle: Text('Get reminded before products expire'),
              value: false,
              onChanged: null,
            ),
            error: (_, __) => const ListTile(
              title: Text('Expiry Reminders'),
              trailing: Icon(Icons.error_outline, color: AppColors.error),
            ),
            data: (isEnabled) => SwitchListTile(
              title: const Text('Expiry Reminders'),
              subtitle:
                  const Text('Get reminded before products expire'),
              value: isEnabled,
              onChanged: (v) =>
                  ref.read(notificationsEnabledProvider.notifier).setEnabled(v),
              activeThumbColor: AppColors.primary,
            ),
          ),

          const Divider(height: 1),

          // ── Permission status ───────────────────────────────────────────────
          permissionAsync.when(
            loading: () => const ListTile(
              leading: Icon(Icons.security_outlined),
              title: Text('Notification Permission'),
              trailing: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const ListTile(
              leading: Icon(Icons.security_outlined),
              title: Text('Notification Permission'),
              subtitle: Text('Unable to check permission status'),
            ),
            data: (granted) => ListTile(
              leading: Icon(
                Icons.security_outlined,
                color: granted ? AppColors.success : AppColors.error,
              ),
              title: const Text('Notification Permission'),
              subtitle: Text(
                granted
                    ? 'Granted'
                    : 'Denied — tap to request permission',
              ),
              trailing: Icon(
                granted
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                color: granted ? AppColors.success : AppColors.error,
              ),
              onTap: granted
                  ? null
                  : () async {
                      final svc =
                          ref.read(notificationServiceProvider);
                      final result = await svc.requestPermission();
                      ref.invalidate(notificationPermissionProvider);
                      if (!result && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Permission denied. Enable notifications '
                              'in device Settings → Apps → Home Vault.',
                            ),
                          ),
                        );
                      }
                    },
            ),
          ),

          const Divider(height: 1),

          // ── Reminder schedule info ──────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Reminder Schedule',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const _ReminderRow(
            icon: Icons.calendar_today_outlined,
            color: AppColors.expirySoon30,
            label: '30 days before expiry',
          ),
          const _ReminderRow(
            icon: Icons.schedule_outlined,
            color: AppColors.expirySoon7,
            label: '7 days before expiry',
          ),
          const _ReminderRow(
            icon: Icons.alarm_outlined,
            color: AppColors.expirySoon7,
            label: '1 day before expiry',
          ),
          const _ReminderRow(
            icon: Icons.warning_amber_outlined,
            color: AppColors.expiryExpired,
            label: 'On expiry day',
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'All reminders are delivered at 9:00 AM on the reminder day.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey400,
                  ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _ReminderRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 20),
      title: Text(label),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
