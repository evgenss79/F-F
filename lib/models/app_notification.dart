import 'dart:convert';

/// Типы уведомлений в приложении
enum AppNotificationType {
  general,
  system,
  taskCreated,
  taskUpdated,
  taskDone,
  taskDeleted,
  taskOverdue,
}

class AppNotification {
  final int id; // уникальный id
  final String title; // заголовок
  final String? body; // текст
  final DateTime createdAt; // время создания
  final bool read; // прочитано?
  final AppNotificationType type; // тип
  final String? taskId; // связанная задача (если есть)
  final String? assigneeId; // назначенный исполнитель (если есть)
  final String? assigneeName; // имя исполнителя (если есть)
  final Map<String, dynamic>? meta; // доп. данные

  const AppNotification({
    required this.id,
    required this.title,
    this.body,
    required this.createdAt,
    this.read = false,
    this.type = AppNotificationType.general,
    this.taskId,
    this.assigneeId,
    this.assigneeName,
    this.meta,
  });

  /// Совместимость: где-то в коде могли обращаться к `message`
  String? get message => body;

  AppNotification copyWith({
    bool? read,
    String? title,
    String? body,
  }) {
    return AppNotification(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      read: read ?? this.read,
      type: type,
      taskId: taskId,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      meta: meta == null ? null : Map<String, dynamic>.from(meta!),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'type': type.name,
        'taskId': taskId,
        'assigneeId': assigneeId,
        'assigneeName': assigneeName,
        'meta': meta,
      };

  static AppNotification fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ??
              DateTime.now().millisecondsSinceEpoch,
      title: (json['title'] ?? '') as String,
      body: json['body'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      read: (json['read'] ?? false) as bool,
      type: _parseType(json['type']),
      taskId: json['taskId'] as String?,
      assigneeId: json['assigneeId'] as String?,
      assigneeName: json['assigneeName'] as String?,
      meta: (json['meta'] is Map)
          ? Map<String, dynamic>.from(json['meta'] as Map)
          : null,
    );
  }

  static AppNotificationType _parseType(dynamic v) {
    final s = (v ?? '').toString();
    for (final t in AppNotificationType.values) {
      if (t.name == s) return t;
    }
    return AppNotificationType.general;
  }

  static List<AppNotification> listFromJson(String src) {
    if (src.trim().isEmpty) return [];
    final raw = jsonDecode(src);
    if (raw is! List) return [];
    return raw
        .map((e) =>
            AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static String listToJson(List<AppNotification> list) {
    return jsonEncode(list.map((e) => e.toJson()).toList());
  }
}
