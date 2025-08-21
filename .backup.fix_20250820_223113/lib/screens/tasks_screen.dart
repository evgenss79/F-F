import 'package:flutter/material.dart';
import '../services/notify.dart'; // для уведомлений (файл notify.dart мы создавали ранее)

class Task {
  final String title;
  final String creator; // кто создал задачу
  final String? assignee; // назначенный исполнитель (null = общая)
  final DateTime createdAt;
  final DateTime deadline;
  bool isDone;

  Task({
    required this.title,
    required this.creator,
    this.assignee,
    required this.createdAt,
    required this.deadline,
    this.isDone = false,
  });
}

class TasksScreen extends StatefulWidget {
  final String currentUser; // текущий пользователь

  const TasksScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<Task> _tasks = [];

  void _addTask(String title, {String? assignee}) {
    final task = Task(
      title: title,
      creator: widget.currentUser,
      assignee: assignee,
      createdAt: DateTime.now(),
      deadline: DateTime.now().add(const Duration(days: 3)),
    );

    setState(() {
      _tasks.add(task);
    });

    if (task.assignee == null) {
      Notify.show(
        "Новая общая задача",
        "${task.title} (создал: ${task.creator})",
      );
    } else {
      Notify.show("Новая задача для ${task.assignee}", task.title);
    }
  }

  void _completeTask(Task task) {
    setState(() {
      task.isDone = true;
    });

    if (task.assignee == null) {
      Notify.show("Общая задача выполнена", task.title);
    } else {
      Notify.show("Задача выполнена", "${task.title} (${task.assignee})");
    }
  }

  void _deleteTask(Task task) {
    if (task.creator != widget.currentUser) {
      Notify.show("Ошибка", "Удалять задачу может только её создатель");
      return;
    }

    setState(() {
      _tasks.remove(task);
    });
  }

  @override
  Widget build(BuildContext context) {
    final generalTasks = _tasks.where((t) => t.assignee == null).toList();
    final personalTasks = _tasks.where((t) => t.assignee != null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Задачи")),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Общие задачи",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...generalTasks.map(
            (task) => ListTile(
              title: Text(task.title),
              subtitle: Text(
                "Создатель: ${task.creator}\nСоздана: ${task.createdAt}",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: task.isDone ? null : () => _completeTask(task),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTask(task),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Индивидуальные задачи",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...personalTasks.map(
            (task) => ListTile(
              title: Text(task.title),
              subtitle: Text(
                "Создатель: ${task.creator}\nИсполнитель: ${task.assignee}\nСоздана: ${task.createdAt}\nДедлайн: ${task.deadline}",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: task.isDone ? null : () => _completeTask(task),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTask(task),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _addTask("Пример задачи", assignee: null); // тестовая добавка
        },
      ),
    );
  }
}
