import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../notifications_service.dart';

class TaskItem {
  String id;
  String title;
  String? description;
  DateTime? deadline;
  String? assignedBy;
  String? assignedTo;
  bool done;
  bool shared;
  TaskItem({
    required this.id,
    required this.title,
    this.description,
    this.deadline,
    this.assignedBy,
    this.assignedTo,
    this.done = false,
    this.shared = false,
  });
  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    String? assignedBy,
    String? assignedTo,
    bool? done,
    bool? shared,
  }) => TaskItem(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    deadline: deadline ?? this.deadline,
    assignedBy: assignedBy ?? this.assignedBy,
    assignedTo: assignedTo ?? this.assignedTo,
    done: done ?? this.done,
    shared: shared ?? this.shared,
  );
  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String?,
    deadline: j['deadline'] != null ? DateTime.tryParse(j['deadline']) : null,
    assignedBy: j['assignedBy'] as String?,
    assignedTo: j['assignedTo'] as String?,
    done: (j['done'] ?? false) as bool,
    shared: (j['shared'] ?? false) as bool,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'deadline': deadline?.toIso8601String(),
    'assignedBy': assignedBy,
    'assignedTo': assignedTo,
    'done': done,
    'shared': shared,
  };
}

class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();
  factory LocalStore() => instance;

  List<TaskItem> _tasks = [];
  List<TaskItem> get tasks => List.unmodifiable(_tasks);

  List<NotificationEntry> get notifications => NotificationService().items;

  Future<File> _tasksFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/tasks.json');
  }

  Future<void> load() async {
    try {
      final f = await _tasksFile();
      if (!await f.exists()) return;
      final data = jsonDecode(await f.readAsString()) as List;
      _tasks = data
          .map((e) => TaskItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {}
  }

  Future<void> save() async {
    try {
      final f = await _tasksFile();
      await f.create(recursive: true);
      await f.writeAsString(jsonEncode(_tasks.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> upsert(TaskItem t) async {
    final i = _tasks.indexWhere((e) => e.id == t.id);
    if (i >= 0) {
      _tasks[i] = t;
    } else {
      _tasks.add(t);
    }
    await save();
  }

  Future<void> remove(String id) async {
    _tasks.removeWhere((e) => e.id == id);
    await save();
  }

  Future<void> delete(String id) => remove(id);
}
