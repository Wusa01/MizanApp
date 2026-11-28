import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/services/reminder_service.dart';
import '../../../../core/settings/reminder_provider.dart';

class ReminderSettingsTiles extends ConsumerWidget {
  const ReminderSettingsTiles({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final ok = await ref.read(reminderProvider.notifier).setEnabled(value);

      if (!ok) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'لم يُمنح إذن الإشعارات. فعّله من إعدادات الهاتف ثم أعد المحاولة.',
            ),
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذر ضبط التذكير')),
      );
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    ReminderSettings settings,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
    );

    if (picked == null) return;

    await ref
        .read(reminderProvider.notifier)
        .setTime(picked.hour, picked.minute);
  }

  Future<void> _test(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final service = ReminderService.instance;

      if (!await service.requestPermission()) {
        messenger.showSnackBar(
          const SnackBar(content: Text('لم يُمنح إذن الإشعارات')),
        );
        return;
      }

      await service.showTest();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذر إرسال الإشعار')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderProvider);

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_active_outlined),
          title: const Text('تذكير يومي'),
          subtitle: const Text('إشعار آخر اليوم لمراجعة حساباتك'),
          value: settings.enabled,
          onChanged: (value) => _toggle(context, ref, value),
        ),
        ListTile(
          enabled: settings.enabled,
          leading: const Icon(Icons.schedule),
          title: const Text('وقت التذكير'),
          trailing: Text(
            settings.timeLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          onTap: settings.enabled
              ? () => _pickTime(context, ref, settings)
              : null,
        ),
        ListTile(
          leading: const Icon(Icons.notification_add_outlined),
          title: const Text('إشعار تجريبي'),
          subtitle: const Text('للتأكد أن الإشعارات تعمل على هاتفك'),
          onTap: () => _test(context),
        ),
      ],
    );
  }
}