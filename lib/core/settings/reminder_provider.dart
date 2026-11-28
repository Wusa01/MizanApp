import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/reminder_service.dart';

const _enabledKey = 'reminder_enabled';
const _hourKey = 'reminder_hour';
const _minuteKey = 'reminder_minute';

class ReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  // افتراضياً: معطّل، والوقت 9 مساءً.
  static const defaults = ReminderSettings(enabled: false, hour: 21, minute: 0);

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

Future<ReminderSettings> readReminderSettings() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    return ReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      hour: prefs.getInt(_hourKey) ?? 21,
      minute: prefs.getInt(_minuteKey) ?? 0,
    );
  } catch (_) {
    return ReminderSettings.defaults;
  }
}

Future<void> _save(ReminderSettings settings) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_hourKey, settings.hour);
    await prefs.setInt(_minuteKey, settings.minute);
  } catch (_) {
    // يبقى الإعداد ساري المفعول في الجلسة الحالية.
  }
}

class ReminderNotifier extends Notifier<ReminderSettings> {
  @override
  ReminderSettings build() {
    _load();
    return ReminderSettings.defaults;
  }

  Future<void> _load() async {
    final saved = await readReminderSettings();

    if (ref.mounted) state = saved;
  }

  /// يرجع false إذا رفض المستخدم إذن الإشعارات.
  Future<bool> setEnabled(bool value) async {
    final service = ReminderService.instance;

    if (value) {
      if (!await service.requestPermission()) return false;

      await service.scheduleDaily(hour: state.hour, minute: state.minute);
    } else {
      await service.cancel();
    }

    state = state.copyWith(enabled: value);
    await _save(state);

    return true;
  }

  Future<void> setTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    await _save(state);

    if (state.enabled) {
      await ReminderService.instance.scheduleDaily(
        hour: hour,
        minute: minute,
      );
    }
  }
}

final reminderProvider = NotifierProvider<ReminderNotifier, ReminderSettings>(
  ReminderNotifier.new,
);