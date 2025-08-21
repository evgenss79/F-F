import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TaskItem {
  final String id;
  final String title;
  final String description;
  final bool done;
  final String assignedBy;     // кто назначил
  final String? assignedTo;    // исполнитель (null = общая)
  final DateTime createdAt;    // дата создания
  final DateTime? deadline;    // дедлайн (может быть null)

  TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.done,
    required this.assignedBy,
    this.assignedTo,
    required this.createdAt,
    this.deadline,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? done,
    String? assignedBy,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? deadline,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      done: done ?? this.done,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'done': done,
        'assignedBy': assignedBy,
        'assignedTo': assignedTo,
        'createdAt': createdAt.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
      };

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        done: j['done'] as bool? ?? false,
        assignedBy: j['assignedBy'] as String? ?? 'Неизвестно',
        assignedTo: j['assignedTo'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        deadline: j['deadline'] != null
            ? DateTime.tryParse(j['deadline'])
            : null,
      );
}

class LocalStore {
  static const _key = 'tasks_v2';

  Future<List<TaskItem>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> saveTasks(List<TaskItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
