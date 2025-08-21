import 'dart:async';
import 'package:flutter/material.dart';
import 'data/local_store.dart';

class NotificationService {
  static final Map<int, Timer> _timers = {};
  static GlobalKey<NavigatorState>? _navKey;

  static void init({required GlobalKey<NavigatorState> navigatorKey}) {
    _navKey = navigatorKey;
    _restorePendingTimers();
  }

  // Основной «до-Firebase» вариант: контекст + именованные параметры.
  static Future<void> addNotification(
    BuildContext context, {
    required int id,
    required String title,
    required String body,
    DateTime? when,
    String type = 'general',
    String? taskId,
  }) async {
    final item = AppNotification(
      id: id,
      title: title,
      body: body,
      when: when ?? DateTime.now(),
      type: type,
      taskId: taskId,
    );
    await LocalStore.instance.addNotification(item);
    _scheduleIfFuture(item);
    _showSnackBar(context, title, body);
  }

  // Совместимость со старыми позиционными вызовами:
  static Future<void> addNotificationCompat(
    BuildContext context,
    String title,
    String body, {
    int? id,
    DateTime? when,
    String type = 'general',
    String? taskId,
  }) =>
      addNotification(
        context,
        id: id ?? DateTime.now().millisecondsSinceEpoch % 1000000000,
        title: title,
        body: body,
        when: when,
        type: type,
        taskId: taskId,
      );

  static void _showSnackBar(BuildContext context, String title, String body) {
    final text = body.isNotEmpty ? '$title\n$body' : title;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  static void _restorePendingTimers() {
    final now = DateTime.now();
    for (final n in LocalStore.instance.notifications) {
      if (n.when != null && n.when!.isAfter(now)) {
        _scheduleIfFuture(n);
      }
    }
  }

  static void _scheduleIfFuture(AppNotification n) {
    final when = n.when;
    if (when == null) return;
    final diff = when.difference(DateTime.now());
    if (diff.isNegative) return;

    _timers[n.id]?.cancel();
    _timers[n.id] = Timer(diff, () {
      final ctx = _navKey?.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(n.title), duration: const Duration(seconds: 2)),
        );
      }
    });
  }

  static void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }
}
