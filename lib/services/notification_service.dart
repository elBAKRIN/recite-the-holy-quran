import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _pluginAvailable = true;

  // أيقونة شريط الإشعارات لأندرويد Oreo+ يجب أن تكون رمزاً أحادي اللون
  // (silhouette) لأن النظام يستخدم قناة alpha فقط؛ أي أيقونة ملوّنة كاملة
  // تظهر كدائرة بيضاء على بعض الأجهزة. ic_launcher_monochrome.png متوفر
  // في كل مجلدات الكثافة (drawable-mdpi إلى xxxhdpi).
  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'khatma_daily_channel',
        'تذكيرات الختمة',
        channelDescription: 'تذكيرات يومية مرتبطة بخطط الختمة',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_launcher_monochrome',
        color: Color(0xFFD4A373),
        colorized: true,
      );

  static const DarwinNotificationDetails _iosDetails =
      DarwinNotificationDetails();

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  Future<void> initialize() async {
    if (_initialized || !_pluginAvailable) return;

    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    try {
      await _plugin.initialize(settings: initializationSettings);
      await _requestPermissions();
      _initialized = true;
    } on MissingPluginException {
      _pluginAvailable = false;
    }
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();
    if (!_pluginAvailable) return;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  Future<void> scheduleKhatmaReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    await initialize();
    if (!_pluginAvailable) return;
    if (scheduledAt.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelKhatmaNotifications(String khatmaId) async {
    await initialize();
    if (!_pluginAvailable) return;
    for (final id in notificationIdsForKhatma(khatmaId)) {
      await _plugin.cancel(id: id);
    }
  }

  /// مجموعة معرّفات إشعارات محجوزة لكل ختمة. كل خانة في المصفوفة تمثّل
  /// إشعاراً محتملاً (وقت مختلف خلال اليوم). نُلغي كل هذه المعرّفات
  /// عند إعادة الجدولة لضمان عدم بقاء إشعار قديم لم يعد المستخدم بحاجته.
  static const int maxNotificationsPerKhatma = 16;

  List<int> notificationIdsForKhatma(String khatmaId) {
    final base = khatmaId.hashCode.abs() % 100000;
    return List<int>.generate(
      maxNotificationsPerKhatma,
      (index) => base + index + 1,
    );
  }
}
