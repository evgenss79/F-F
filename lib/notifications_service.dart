import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'models/app_notification.dart';

/// Сервис уведомлений (локальная история + бейдж непрочитанных)
class NotificationService {
  NotificationService._();

  static final ValueNotifier<List<AppNotification>> _list =
      ValueNotifier<List<AppNotification>>(<AppNotification>[]);
  static final ValueNotifier<int> _unread = ValueNotifier<int>(0);

  static ValueListenable<List<AppNotification>> get list => _list;
  static ValueListenable<int> get unreadCount => _unread;

  static late File _storeFile;
  static bool _inited = false;

  /// Инициализация: загрузка истории из файла
  static Future<void> init() async {
    if (_inited) return;
    final dir = await getApplicationSupportDirectory();
    _storeFile = File('${dir.path}/notifications.json');
    if (await _storeFile.exists()) {
      try {
        final txt = await _storeFile.readAsString();
        _list.value = AppNotification.listFromJson(txt);
      } catch (_) {
        _list.value = <AppNotification>[];
      }
    } else {
      _list.value = <AppNotification>[];
      await _persist();
    }
    _recalcUnread();
    _inited = true;
  }

  static Future<void> _persist() async {
    try {
      await _storeFile.writeAsString(AppNotification.listToJson(_list.value));
    } catch (_) {}
  }

  static void _recalcUnread() {
    _unread.value = _list.value.where((n) => !n.read).length;
  }

  /// Добавить уведомление
  static Future<void> add({
    required String title,
    String? body,
    AppNotificationType type = AppNotificationType.general,
    String? taskId,
    String? assigneeId,
    String? assigneeName,
    Map<String, dynamic>? meta,
    DateTime? createdAt,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch;
    final n = AppNotification(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt ?? DateTime.now(),
      type: type,
      taskId: taskId,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      meta: meta,
      read: false,
    );
    final next = [..._list.value, n];
    next.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _list.value = next;
    _recalcUnread();
    await _persist();
  }

  static Future<void> markRead(int id) async {
    _list.value = _list.value
        .map((e) => e.id == id ? e.copyWith(read: true) : e)
        .toList();
    _recalcUnread();
    await _persist();
  }

  static Future<void> markAllRead() async {
    _list.value = _list.value.map((e) => e.copyWith(read: true)).toList();
    _recalcUnread();
    await _persist();
  }

  static Future<void> delete(int id) async {
    _list.value = _list.value.where((e) => e.id != id).toList();
    _recalcUnread();
    await _persist();
  }

  static Future<void> clear() async {
    _list.value = <AppNotification>[];
    _recalcUnread();
    await _persist();
  }

  // ----- Хелперы для задач (совместим с текущими вызовами) -----

  /// Создана задача
  static Future<void> taskCreated(dynamic task, {BuildContext? context}) async {
    await add(
      title: 'Новая задача',
      body: _taskSummary(task),
      type: AppNotificationType.taskCreated,
      taskId: _taskId(task),
      assigneeId: _assigneeId(task),
      assigneeName: _assigneeName(task),
      meta: {'dueAt': _dueAtIso(task)},
    );
  }

  /// Обновлена задача
  static Future<void> taskUpdated(dynamic task, {BuildContext? context}) async {
    await add(
      title: 'Задача обновлена',
      body: _taskSummary(task),
      type: AppNotificationType.taskUpdated,
      taskId: _taskId(task),
      assigneeId: _assigneeId(task),
      assigneeName: _assigneeName(task),
      meta: {'dueAt': _dueAtIso(task)},
    );
  }

  /// Завершена задача
  static Future<void> taskDone(dynamic task, {BuildContext? context}) async {
    await add(
      title: 'Задача выполнена',
      body: _taskSummary(task),
      type: AppNotificationType.taskDone,
      taskId: _taskId(task),
      assigneeId: _assigneeId(task),
      assigneeName: _assigneeName(task),
      meta: {'dueAt': _dueAtIso(task)},
    );
  }

  /// Удалена задача
  static Future<void> taskDeleted(dynamic task, {BuildContext? context}) async {
    await add(
      title: 'Задача удалена',
      body: _taskSummary(task),
      type: AppNotificationType.taskDeleted,
      taskId: _taskId(task),
      assigneeId: _assigneeId(task),
      assigneeName: _assigneeName(task),
      meta: {'dueAt': _dueAtIso(task)},
    );
  }

  /// Возможно просрочена задача
  static Future<void> maybeOverdue(dynamic task,
      {BuildContext? context}) async {
    await add(
      title: 'Срок задачи истёк',
      body: _taskSummary(task),
      type: AppNotificationType.taskOverdue,
      taskId: _taskId(task),
      assigneeId: _assigneeId(task),
      assigneeName: _assigneeName(task),
      meta: {'dueAt': _dueAtIso(task)},
    );
  }

  // ----- приватные утилиты распаковки task из разных форматов -----

  static String _taskId(dynamic t) {
    try {
      if (t is Map) return '${t['id'] ?? ''}';
      // объект с полем id
      // ignore: avoid_dynamic_calls
      return '${t.id}';
    } catch (_) {
      return '';
    }
  }

  static String? _assigneeId(dynamic t) {
    try {
      if (t is Map) return t['assigneeId'] as String?;
      // ignore: avoid_dynamic_calls
      return t.assigneeId as String?;
    } catch (_) {
      return null;
    }
  }

  static String? _assigneeName(dynamic t) {
    try {
      if (t is Map) return t['assigneeName'] as String?;
      // ignore: avoid_dynamic_calls
      return t.assigneeName as String?;
    } catch (_) {
      return null;
    }
  }

  static DateTime? _dueAt(dynamic t) {
    try {
      if (t is Map) {
        final v = t['dueAt'];
        if (v is String) return DateTime.tryParse(v);
        if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
        if (v is DateTime) return v;
        return null;
      }
      // ignore: avoid_dynamic_calls
      final v = t.dueAt;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return null;
    } catch (_) {
      return null;
    }
  }

  static String? _dueAtIso(dynamic t) => _dueAt(t)?.toIso8601String();

  static String _taskSummary(dynamic t) {
    try {
      String title = '';
      String? assignee;
      DateTime? due = _dueAt(t);

      if (t is Map) {
        title = '${t['title'] ?? t['name'] ?? 'Без названия'}';
        assignee = (t['assigneeName'] ?? t['assignee'] ?? '') as String?;
      } else {
        // ignore: avoid_dynamic_calls
        title = '${t.title ?? t.name ?? 'Без названия'}';
        try {
          // ignore: avoid_dynamic_calls
          assignee = t.assigneeName as String?;
        } catch (_) {}
      }

      final parts = <String>[];
      parts.add(title);
      if (assignee != null && assignee!.trim().isNotEmpty)
        parts.add('→ $assignee');
      if (due != null) parts.add('до ${_fmtDate(due)}');
      return parts.join('  •  ');
    } catch (_) {
      return 'Задача';
    }
  }

  static String _fmtDate(DateTime d) {
    final two = (int x) => x.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
    // при желании можно подключить intl и локализовать подсказку
  }
}
