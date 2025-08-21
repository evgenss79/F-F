import 'dart:convert';
import 'dart:io';

class TaskItem {
  final int id;
  final String title;
  final String? notes;
  final DateTime? deadline;
  final bool isDone;

  TaskItem({
    required this.id,
    required this.title,
    this.notes,
    this.deadline,
    required this.isDone,
  });

  factory TaskItem.newEmpty() => TaskItem(
    id: DateTime.now().millisecondsSinceEpoch % 1000000000,
    title: '',
    notes: '',
    deadline: null,
    isDone: false,
  );

  TaskItem copyWith({
    int? id,
    String? title,
    String? notes,
    DateTime? deadline,
    bool? isDone,
  }) => TaskItem(
    id: id ?? this.id,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    deadline: deadline ?? this.deadline,
    isDone: isDone ?? this.isDone,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    'deadline': deadline?.toIso8601String(),
    'isDone': isDone,
  };

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
    id: j['id'] as int,
    title: j['title'] as String? ?? '',
    notes: j['notes'] as String?,
    deadline: j['deadline'] != null ? DateTime.parse(j['deadline']) : null,
    isDone: j['isDone'] as bool? ?? false,
  );
}

class AppNotification {
  final int id;
  final String title;
  final String body;
  final DateTime? when;
  final String type;
  final String? taskId;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.when,
    this.type = 'general',
    this.taskId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'when': when?.toIso8601String(),
    'type': type,
    'taskId': taskId,
  };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as int,
    title: j['title'] as String? ?? '',
    body: j['body'] as String? ?? '',
    when: j['when'] != null ? DateTime.parse(j['when']) : null,
    type: j['type'] as String? ?? 'general',
    taskId: j['taskId'] as String?,
  );
}

class LocalStore {
  LocalStore._();
  static final instance = LocalStore._();

  final List<TaskItem> tasks = [];
  final List<AppNotification> notifications = [];

  late final Directory _dir;
  late final File _tasksFile;
  late final File _notifFile;

  Future<void> load() async {
    final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
    _dir = Directory('$home/Documents/family_app_data');
    if (!await _dir.exists()) {
      await _dir.create(recursive: true);
    }
    _tasksFile = File('${_dir.path}/tasks.json');
    _notifFile = File('${_dir.path}/notifications.json');

    if (await _tasksFile.exists()) {
      final raw = await _tasksFile.readAsString();
      final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      tasks
        ..clear()
        ..addAll(data.map(TaskItem.fromJson));
    }
    if (await _notifFile.exists()) {
      final raw = await _notifFile.readAsString();
      final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      notifications
        ..clear()
        ..addAll(data.map(AppNotification.fromJson));
    }
  }

  Future<void> _saveTasks() async {
    final raw = jsonEncode(tasks.map((e) => e.toJson()).toList());
    await _tasksFile.writeAsString(raw);
  }

  Future<void> _saveNotif() async {
    final raw = jsonEncode(notifications.map((e) => e.toJson()).toList());
    await _notifFile.writeAsString(raw);
  }

  Future<void> addTask(TaskItem t) async {
    tasks.add(t);
    tasks.sort((a, b) {
      final ad = a.deadline?.millisecondsSinceEpoch ?? 0x7fffffffffffffff;
      final bd = b.deadline?.millisecondsSinceEpoch ?? 0x7fffffffffffffff;
      final byDeadline = ad.compareTo(bd);
      if (byDeadline != 0) return byDeadline;
      return a.id.compareTo(b.id);
    });
    await _saveTasks();
  }

  Future<void> updateTask(TaskItem t) async {
    final i = tasks.indexWhere((e) => e.id == t.id);
    if (i >= 0) {
      tasks[i] = t;
      await _saveTasks();
    }
  }

  Future<void> deleteTask(int id) async {
    tasks.removeWhere((e) => e.id == id);
    await _saveTasks();
  }

  Future<void> addNotification(AppNotification n) async {
    notifications.add(n);
    notifications.sort((a, b) {
      final ad = a.when?.millisecondsSinceEpoch ?? 0;
      final bd = b.when?.millisecondsSinceEpoch ?? 0;
      return bd.compareTo(ad);
    });
    await _saveNotif();
  }
}
