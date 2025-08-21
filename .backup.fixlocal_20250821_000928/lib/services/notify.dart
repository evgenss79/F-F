import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Сервис локальных уведомлений
class Notify {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _inited = false;

  /// Инициализация
  static Future<void> init() async {
    if (_inited) return;
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (resp) {
        // обработка нажатия по уведомлению (payload) — опционально
      },
    );

    _inited = true;
  }

  /// Запросить системные разрешения (iOS/macOS)
  static Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Мгновенное уведомление
  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel',
        'Основные уведомления',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.show(id, title, body, details);
  }

  /// Запланированное уведомление (одноразовое)
  static Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'scheduled_channel',
        'Запланированные уведомления',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      details,
      // Обязательный параметр для новых версий на Android.
      // Под macOS не влияет, но требование сигнатуры соблюдено.
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: null,
    );
  }

  /// Отмена уведомления
  static Future<void> cancel(int id) => _plugin.cancel(id);

  /// Отмена всех уведомлений
  static Future<void> cancelAll() => _plugin.cancelAll();
}
