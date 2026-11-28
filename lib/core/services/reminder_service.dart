import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  static const _reminderId = 1001;
  static const _testId = 1002;
  static const _title = 'ميزان';
  static const _body = 'حان وقت مراجعة حساباتك. سجّل عمليات اليوم قبل أن تنساها.';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminder',
      'التذكير اليومي',
      channelDescription: 'تذكير بمراجعة الحسابات آخر اليوم',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    _initialized = true;
  }

  /// يطلب إذن الإشعارات (أندرويد 13 فأحدث). يرجع false إذا رُفض.
  Future<bool> requestPermission() async {
    await init();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    return await android?.requestNotificationsPermission() ?? true;
  }

  /// جدولة إشعار يتكرر يومياً في الوقت المحدد (بتوقيت الهاتف).
  ///
  /// نمرّر اللحظة المطلوبة بتوقيت UTC لأن الحزمة تكرر الإشعار على نفس
  /// الساعة يومياً. ونعيد الجدولة عند كل تشغيل للتطبيق ليتكيف مع تغيّر
  /// توقيت الهاتف. الدقة قد تتأخر دقائق لأننا نستخدم جدولة غير دقيقة
  /// (لا تحتاج إذن المنبهات الدقيقة).
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    await init();

    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);

    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _reminderId,
      title: _title,
      body: _body,
      scheduledDate: tz.TZDateTime.from(next, tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() async {
    await init();
    await _plugin.cancel(id: _reminderId);
  }

  /// إشعار فوري للتأكد أن الإشعارات تعمل على الهاتف.
  Future<void> showTest() async {
    await init();

    await _plugin.show(
      id: _testId,
      title: _title,
      body: 'الإشعارات تعمل بشكل صحيح ✅',
      notificationDetails: _details,
    );
  }
}