import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/task_item.dart';

class FamilyMember {
  final String id;
  final String name;
  FamilyMember({required this.id, required this.name});
}

class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  /// Текущий пользователь (создатель задач по умолчанию)
  /// При необходимости подменим в будущем на реальный профиль/авторизацию
  String get meId => _meId;
  String _meId = 'me';

  /// Отображаемое имя текущего пользователя
  String get meName => _meName;
  String _meName = 'Я';

  /// Список членов семьи для выпадающего списка исполнителей
  /// (примеры; в будущем наполним из профилей)
  final List<FamilyMember> members = [
    FamilyMember(id: 'me', name: 'Я'),
    FamilyMember(id: 'mom', name: 'Мама'),
    FamilyMember(id: 'dad', name: 'Папа'),
    FamilyMember(id: 'son', name: 'Сын'),
    FamilyMember(id: 'daughter', name: 'Дочь'),
  ];

  /// Хранилище задач
  List<TaskItem> _tasks = [];
  List<TaskItem> get tasks => List.unmodifiable(_tasks);

  Future<File> _file(String name) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$name');
  }

  Future<void> load() async {
    // me.json (простая шестерёнка для "кто я")
    try {
      final f = await _file('me.json');
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _meId = (j['id'] as String?) ?? 'me';
        _meName = (j['name'] as String?) ?? 'Я';
      }
    } catch (_) {}

    // tasks.json
    try {
      final f = await _file('tasks.json');
      if (await f.exists()) {
        final s = await f.readAsString();
        _tasks = TaskItem.decodeList(s);
      }
    } catch (_) {
      _tasks = [];
    }
  }

  Future<void> _saveTasks() async {
    final f = await _file('tasks.json');
    await f.writeAsString(TaskItem.encodeList(_tasks));
  }

  Future<void> addTask(TaskItem t) async {
    _tasks = [..._tasks, t];
    await _saveTasks();
  }

  Future<void> updateTask(TaskItem t) async {
    _tasks = _tasks.map((e) => e.id == t.id ? t : e).toList();
    await _saveTasks();
  }

  Future<void> deleteTask(String id) async {
    _tasks = _tasks.where((e) => e.id != id).toList();
    await _saveTasks();
  }

  Future<void> setMe({required String id, required String name}) async {
    _meId = id;
    _meName = name;
    final f = await _file('me.json');
    await f.writeAsString(jsonEncode({'id': id, 'name': name}));
  }

  FamilyMember? memberById(String? id) {
    if (id == null) return null;
    return members.firstWhere((m) => m.id == id,
        orElse: () => FamilyMember(id: id, name: id));
  }
}
