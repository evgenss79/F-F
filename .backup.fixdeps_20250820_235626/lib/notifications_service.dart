import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class AppNotification {
  final int id;
  final String title;
  final String body;
  final String type;
  final String? taskId;
  final DateTime createdAt;
  final DateTime? scheduledAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.taskId,
    DateTime? createdAt,
    this.scheduledAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    'taskId': taskId,
    'createdAt': createdAt.toIso8601String(),
    'scheduledAt': scheduledAt?.toIso8601String(),
  };

  static AppNotification fromJson(Map<String, dynamic> m) => AppNotification(
    id: m['id'] as int,
    title: m['title'] as String,
    body: m['body'] as String,
    type: m['type'] as String,
    taskId: m['taskId'] as String?,
    createdAt: DateTime.parse(m['createdAt']),
    scheduledAt: m['scheduledAt'] != null
        ? DateTime.parse(m['scheduledAt'])
        : null,
  );
}

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final List<Timer> _timers = [];

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    final dataDir = Directory('${dir.path}/family_app_data');
    if (!await dataDir.exists()) await dataDir.create(recursive: true);
    return File('${dataDir.path}/notifications.json');
  }

  Future<List<AppNotification>> load() async {
    final f = await _file();
    if (!await f.exists()) return [];
    final raw = await f.readAsString();
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(AppNotification.fromJson).toList();
  }

  Future<void> _save(List<AppNotification> items) async {
    final f = await _file();
    await f.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> addNotification(
    BuildContext context, {
    required int id,
    required String title,
    required String body,
    DateTime? when,
    String type = 'general',
    String? taskId,
  }) async {
    final existing = await load();
    final n = AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      taskId: taskId,
      scheduledAt: when,
    );
    await _save([...existing, n]);

    void showNow() {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.showSnackBar(SnackBar(content: Text('$title — $body')));
      }
    }

    if (when == null || when.isBefore(DateTime.now())) {
      showNow();
    } else {
      final d = when.difference(DateTime.now());
      _timers.add(Timer(d, showNow));
    }
  }

  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }
}
