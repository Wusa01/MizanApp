import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/mizan_app.dart';
import 'core/services/reminder_service.dart';
import 'core/settings/app_lock_provider.dart';
import 'core/settings/reminder_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final lockEnabled = await readInitialAppLock();

  // نعيد جدولة التذكير في كل تشغيل ليتكيف مع تغيّر توقيت الهاتف.
  try {
    final reminder = await readReminderSettings();

    if (reminder.enabled) {
      await ReminderService.instance.scheduleDaily(
        hour: reminder.hour,
        minute: reminder.minute,
      );
    }
  } catch (_) {
    // لا نمنع فتح التطبيق إذا تعذرت الإشعارات.
  }

  runApp(
    ProviderScope(
      overrides: [initialAppLockProvider.overrideWithValue(lockEnabled)],
      child: const MizanApp(),
    ),
  );
}