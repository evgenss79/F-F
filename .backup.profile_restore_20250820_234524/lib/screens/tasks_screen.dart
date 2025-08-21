import 'package:flutter/material.dart';
import '../data/local_store.dart';
import '../notifications_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  Future<void> _addTask() async {
    final created = await Navigator.of(context).push<TaskItem>(
      MaterialPageRoute(builder: (_) => const _EditTaskScreen()),
    );
    if (created == null) return;
    setState(() {});
    if (created.deadline != null) {
      // именованные параметры (основной путь)
      await NotificationService.addNotification(
        context,
        id: created.id,
        title: 'Срок задачи',
        body: '«${created.title}» — срок наступил',
        when: created.deadline,
        type: 'task',
        taskId: created.id.toString(),
      );
      // совместимость: старая позиционная форма тоже поддерживается:
      // await NotificationService.addNotificationCompat(context, 'Срок задачи', '«${created.title}» — срок наступил', when: created.deadline, type: 'task', taskId: created.id.toString());
    }
  }

  Future<void> _editTask(TaskItem t) async {
    final changed = await Navigator.of(context).push<TaskItem>(
      MaterialPageRoute(builder: (_) => _EditTaskScreen(initial: t)),
    );
    if (changed == null) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tasks = LocalStore.instance.tasks;
    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 84),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final t = tasks[i];
          return Dismissible(
            key: ValueKey(t.id),
            background: Container(
              color: Colors.red.withOpacity(0.15),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete),
            ),
            secondaryBackground: Container(
              color: Colors.red.withOpacity(0.15),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete),
            ),
            onDismissed: (_) async {
              await LocalStore.instance.deleteTask(t.id);
              setState(() {});
            },
            child: ListTile(
              leading: Checkbox(
                value: t.isDone,
                onChanged: (v) async {
                  await LocalStore.instance.updateTask(t.copyWith(isDone: v ?? false));
                  setState(() {});
                },
              ),
              title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (t.notes?.isNotEmpty == true)
                    Text(t.notes!, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (t.deadline != null)
                    Text('Срок: ${t.deadline!.toLocal().toString().substring(0, 16)}'),
                ],
              ),
              trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _editTask(t)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        label: const Text('Добавить'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _EditTaskScreen extends StatefulWidget {
  final TaskItem? initial;
  const _EditTaskScreen({this.initial});

  @override
  State<_EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<_EditTaskScreen> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _title = TextEditingController(text: t?.title ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    _deadline = t?.deadline;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      initialDate: _deadline?.toLocal() ?? now,
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline?.toLocal() ?? now),
    );
    if (t == null) return;
    setState(() {
      _deadline = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название задачи')),
      );
      return;
    }
    final base = widget.initial;
    final item = (base ?? TaskItem.newEmpty()).copyWith(
      title: title,
      notes: _notes.text.trim(),
      deadline: _deadline,
    );
    if (base == null) {
      await LocalStore.instance.addTask(item);
    } else {
      await LocalStore.instance.updateTask(item);
    }
    if (!mounted) return;
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Новая задача' : 'Редактирование'),
        actions: [
          IconButton(onPressed: _pickDeadline, tooltip: 'Срок', icon: const Icon(Icons.event)),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _deadline == null
                        ? 'Срок не задан'
                        : 'Срок: ${_deadline!.toLocal().toString().substring(0, 16)}',
                  ),
                ),
                TextButton.icon(onPressed: _pickDeadline, icon: const Icon(Icons.schedule), label: const Text('Выбрать срок')),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Сохранить')),
          ],
        ),
      ),
    );
  }
}
