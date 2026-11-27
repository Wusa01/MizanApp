import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _appLockKey = 'app_lock_enabled';

/// القيمة الابتدائية تُقرأ في main() قبل رسم أول شاشة،
/// حتى لا يظهر محتوى التطبيق للحظة قبل القفل.
final initialAppLockProvider = Provider<bool>((ref) => false);

Future<bool> readInitialAppLock() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_appLockKey) ?? false;
  } catch (_) {
    return false;
  }
}

class AppLockNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(initialAppLockProvider);

  Future<void> setEnabled(bool value) async {
    state = value;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_appLockKey, value);
    } catch (_) {
      // يبقى الإعداد ساري المفعول في الجلسة الحالية.
    }
  }
}

final appLockProvider = NotifierProvider<AppLockNotifier, bool>(
  AppLockNotifier.new,
);