import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class NotificationEntry {
  int id;
  String title;
  String body;
  DateTime when;
  String type;
  String? taskId;

  NotificationEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    this.type = 'general',
    this.taskId,
  });

  factory NotificationEntry.fromJson(Map<String, dynamic> j) =>
      NotificationEntry(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        when: DateTime.tryParse(j['when'] as String? ?? '') ?? DateTime.now(),
        type: j['type'] as String? ?? 'general',
        taskId: j['taskId'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'when': when.toIso8601String(),
    'type': type,
    'taskId': taskId,
  };
}

class NotificationService {
  NotificationService._();
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;

  List<NotificationEntry> _items = [];
  List<NotificationEntry> get items => List.unmodifiable(_items);

  static Future<void> init() async {
    await NotificationService()._load();
  }

  static Future<void> refresh() async {
    await NotificationService()._load();
  }

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/notifications.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final data = jsonDecode(await f.readAsString()) as List;
      _items = data
          .map((e) => NotificationEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final f = await _file();
      await f.create(recursive: true);
      await f.writeAsString(jsonEncode(_items.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> addNotification(
    BuildContext context, {
    int? id,
    String? title,
    String? body,
    DateTime? when,
    String type = 'general',
    String? taskId,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch % 1000000000;
    final n = NotificationEntry(
      id: id ?? nowMs,
      title: title ?? 'Уведомление',
      body: body ?? '',
      when: when ?? DateTime.now(),
      type: type,
      taskId: taskId,
    );
    final svc = NotificationService();
    await svc._load();
    svc._items.add(n);
    await svc._save();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(n.title.isEmpty ? n.body : n.title)),
      );
    }
    if (kDebugMode) {}
  }
}
