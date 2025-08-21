import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class TaskItem {
  final String id;
  final String title;
  final String? description;
  final DateTime? deadline;
  final String? assignedBy;
  final String? assignedTo;
  final bool shared;
  final bool done;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskItem({
    required this.id,
    required this.title,
    this.description,
    this.deadline,
    this.assignedBy,
    this.assignedTo,
    this.shared = false,
    this.done = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    String? assignedBy,
    String? assignedTo,
    bool? shared,
    bool? done,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedTo: assignedTo ?? this.assignedTo,
      shared: shared ?? this.shared,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'deadline': deadline?.toIso8601String(),
    'assignedBy': assignedBy,
    'assignedTo': assignedTo,
    'shared': shared,
    'done': done,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static TaskItem fromJson(Map<String, dynamic> m) => TaskItem(
    id: m['id'] as String,
    title: m['title'] as String,
    description: m['description'] as String?,
    deadline: m['deadline'] != null ? DateTime.parse(m['deadline']) : null,
    assignedBy: m['assignedBy'] as String?,
    assignedTo: m['assignedTo'] as String?,
    shared: (m['shared'] as bool?) ?? false,
    done: (m['done'] as bool?) ?? false,
    createdAt: DateTime.parse(m['createdAt']),
    updatedAt: DateTime.parse(m['updatedAt']),
  );
}

class LocalStore {
  static final LocalStore _i = LocalStore._();
  factory LocalStore() => _i;
  LocalStore._();

  List<TaskItem> _cache = [];

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    final dataDir = Directory('${dir.path}/family_app_data');
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return File('${dataDir.path}/tasks.json');
  }

  Future<List<TaskItem>> load() async {
    if (_cache.isNotEmpty) return _cache;
    final f = await _file();
    if (!await f.exists()) return _cache;
    final raw = await f.readAsString();
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _cache = list.map(TaskItem.fromJson).toList();
    return _cache;
  }

  Future<void> _persist() async {
    final f = await _file();
    final data = jsonEncode(_cache.map((e) => e.toJson()).toList());
    await f.writeAsString(data);
  }

  Future<void> upsert(TaskItem t) async {
    await load();
    final idx = _cache.indexWhere((e) => e.id == t.id);
    if (idx >= 0) {
      _cache[idx] = t.copyWith(updatedAt: DateTime.now());
    } else {
      _cache.add(t.copyWith(updatedAt: DateTime.now()));
    }
    await _persist();
  }

  Future<void> delete(String id) async {
    await load();
    _cache.removeWhere((e) => e.id == id);
    await _persist();
  }
}
