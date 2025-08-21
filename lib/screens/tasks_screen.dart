import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/local_store.dart';
import '../models/task_item.dart';
import '../widgets/notif_bell_action.dart';
import '../notifications_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _store = LocalStore.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _store.load();
    setState(() => _loading = false);
  }

  Future<void> _toggleDone(TaskItem t, bool v) async {
    final updated = t.copyWith(done: v);
    await _store.updateTask(updated);
    if (!mounted) return;
    setState(() {});
    if (v) await NotificationService.taskDone(updated);
  }

  Future<void> _delete(TaskItem t) async {
    // удалять может только создатель
    if (t.creatorId != _store.meId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Удалить может только создатель задачи')),
      );
      return;
    }
    await _store.deleteTask(t.id);
    if (!mounted) return;
    setState(() {});
    await NotificationService.taskDeleted(t);
  }

  Future<void> _createOrEdit({TaskItem? initial}) async {
    final result = await showDialog<TaskItem>(
      context: context,
      builder: (_) => _TaskEditor(initial: initial),
    );
    if (result == null) return;

    if (initial == null) {
      await _store.addTask(result);
      if (!mounted) return;
      setState(() {});
      await NotificationService.taskCreated(result);
    } else {
      await _store.updateTask(result);
      if (!mounted) return;
      setState(() {});
      await NotificationService.taskUpdated(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _store.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи'),
        actions: const [NotifBellAction(), SizedBox(width: 8)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createOrEdit(),
        icon: const Icon(Icons.add_task),
        label: const Text('Новая задача'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(child: Text('Задач пока нет'))
              : ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, i) {
                    final t = tasks[i];
                    final overdue = t.dueAt != null &&
                        !t.done &&
                        t.dueAt!.isBefore(DateTime.now());
                    final subtitleParts = <String>[];
                    if (t.assigneeName != null && t.assigneeName!.isNotEmpty) {
                      subtitleParts.add('Исп.: ${t.assigneeName}');
                    }
                    if (t.dueAt != null) {
                      subtitleParts.add(
                          'Срок: ${DateFormat('dd.MM.yyyy HH:mm').format(t.dueAt!)}');
                    }
                    if (t.comment != null && t.comment!.isNotEmpty) {
                      subtitleParts.add('Комментарий: ${t.comment}');
                    }

                    return Dismissible(
                      key: ValueKey(t.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        // ограничение удаления
                        if (t.creatorId != _store.meId) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Удалить может только создатель задачи')),
                          );
                          return false;
                        }
                        return true;
                      },
                      onDismissed: (_) => _delete(t),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: CheckboxListTile(
                        value: t.done,
                        onChanged: (v) => _toggleDone(t, v ?? false),
                        title: Text(
                          t.title,
                          style: TextStyle(
                            color: overdue ? Colors.red : null,
                            decoration:
                                t.done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: subtitleParts.isEmpty
                            ? null
                            : Text(subtitleParts.join(' • ')),
                        secondary: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _createOrEdit(initial: t),
                          tooltip: 'Редактировать',
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _TaskEditor extends StatefulWidget {
  final TaskItem? initial;
  const _TaskEditor({required this.initial});
  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  final _title = TextEditingController();
  final _comment = TextEditingController();
  String? _assigneeId;
  DateTime? _dueAt;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    if (t != null) {
      _title.text = t.title;
      _comment.text = t.comment ?? '';
      _assigneeId = t.assigneeId;
      _dueAt = t.dueAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    return AlertDialog(
      title: Text(
          widget.initial == null ? 'Новая задача' : 'Редактирование задачи'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Заголовок'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _assigneeId,
              decoration: const InputDecoration(labelText: 'Исполнитель'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('— Не назначен —')),
                ...store.members.map(
                  (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
                ),
              ],
              onChanged: (v) => setState(() => _assigneeId = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Срок'),
                    child: Text(
                      _dueAt == null
                          ? 'Не задан'
                          : DateFormat('dd.MM.yyyy HH:mm').format(_dueAt!),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 5),
                      initialDate: _dueAt ?? now,
                    );
                    if (d == null) return;
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_dueAt ?? now),
                    );
                    setState(() {
                      _dueAt = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        t?.hour ?? 9,
                        t?.minute ?? 0,
                      );
                    });
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Выбрать'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comment,
              decoration: const InputDecoration(labelText: 'Комментарий'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена')),
        FilledButton(
          onPressed: () {
            final title = _title.text.trim();
            if (title.isEmpty) return;

            final assignee = store.memberById(_assigneeId);
            final meId = store.meId;

            final result = (widget.initial == null)
                ? TaskItem.create(
                    title: title,
                    creatorId: meId,
                    assigneeId: assignee?.id,
                    assigneeName: assignee?.name,
                    dueAt: _dueAt,
                    comment: _comment.text.trim().isEmpty
                        ? null
                        : _comment.text.trim(),
                  )
                : widget.initial!.copyWith(
                    title: title,
                    assigneeId: assignee?.id,
                    assigneeName: assignee?.name,
                    dueAt: _dueAt,
                    comment: _comment.text.trim().isEmpty
                        ? null
                        : _comment.text.trim(),
                  );

            Navigator.pop(context, result);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
