import "package:flutter/material.dart";
// lib/notifications_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'notifications_db.dart';

class NotificationService {
  static final ValueNotifier<int> _unreadCount = ValueNotifier<int>(0);
  static int get unreadCount => _unreadCount.value;
  static ValueListenable<int> get unreadCountListenable => _unreadCount;

  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    _inited = true;
    await refresh();
  }

  static Future<void> refresh() async {
    try {
      final c = await NotificationsDB.unreadCount();
      _unreadCount.value = c;
      await _updateAppBadge();
    } catch (_) {}
  }

  static Future<void> addNotification(
    String message, {
    String title = 'Уведомление',
    String? type, // 'task' | 'system'
    DateTime? at,
    bool markRead = false,
  }) async {
    final now = at ?? DateTime.now();
    final effectiveType = type ?? _inferType(title, message);

    try {
      await NotificationsDB.insert(
        NotificationItem(
          title: title,
          body: message,
          timestamp: now.toIso8601String(),
          isRead: markRead,
          type: effectiveType,
        ),
      );

      if (!markRead) {
        _unreadCount.value = _unreadCount.value + 1;
        await _updateAppBadge();
      }
    } catch (_) {}
  }

  static Future<void> markAllRead() async {
    try {
      final db = await NotificationsDB.database;
      await db.update('notifications', {'isRead': 1}, where: 'isRead = 0');
      _unreadCount.value = 0;
      await _updateAppBadge();
    } catch (_) {}
  }

  static String _inferType(String title, String message) {
    final t = (title + ' ' + message).toLowerCase();
    if (t.contains('задач')) return 'task';
    return 'system';
  }

  static Future<void> _updateAppBadge() async {
    try {
      final c = _unreadCount.value;
      if (c > 0) {
        await FlutterAppBadger.updateBadgeCount(c);
      } else {
        await FlutterAppBadger.removeBadge();
      }
    } catch (_) {}
  }
}
