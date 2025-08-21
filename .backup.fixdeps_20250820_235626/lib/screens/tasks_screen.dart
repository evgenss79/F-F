import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:family_app/data/local_store.dart';
import 'package:family_app/notifications_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _store = LocalStore();
  List<TaskItem> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _store.load();
    setState(() {
      _tasks = [...all]
        ..sort((a, b) {
          final ad = a.deadline ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bd = b.deadline ?? DateTime.fromMillisecondsSinceEpoch(0);
          return ad.compareTo(bd);
        });
      _loading = false;
    });
  }

  Future<void> _create() async {
    final res = await Navigator.of(context).push<TaskItem>(
      MaterialPageRoute(builder: (_) => const _EditTaskScreen()),
    );
    if (res == null) return;
    await _store.upsert(res);
    await _maybeSchedule(res);
    await _load();
  }

  Future<void> _edit(TaskItem t) async {
    final res = await Navigator.of(context).push<TaskItem>(
      MaterialPageRoute(builder: (_) => _EditTaskScreen(initial: t)),
    );
    if (res == null) return;
    await _store.upsert(res);
    await _maybeSchedule(res);
    await _load();
  }

  Future<void> _delete(TaskItem t) async {
    await _store.delete(t.id);
    await _load();
  }

  Future<void> _toggleDone(TaskItem t) async {
    await _store.upsert(t.copyWith(done: !t.done));
    await _load();
  }

  Future<void> _maybeSchedule(TaskItem t) async {
    if (t.deadline == null) return;
    final now = DateTime.now();
    final d = t.deadline!;
    final oneHour = d.subtract(const Duration(hours: 1));
    final fifteen = d.subtract(const Duration(minutes: 15));

    Future<void> add(String title, DateTime when) async {
      if (when.isAfter(now)) {
        await NotificationService().addNotification(
          context,
          id: DateTime.now().millisecondsSinceEpoch % 1000000000,
          title: title,
          body: '«${t.title}»',
          when: when,
          type: 'task',
          taskId: t.id,
        );
      }
    }

    await add('Срок через 1 час', oneHour);
    await add('Срок через 15 минут', fifteen);
    await NotificationService().addNotification(
      context,
      id: DateTime.now().millisecondsSinceEpoch % 1000000000,
      title: 'Срок наступил',
      body: '«${t.title}»',
      when: d.isAfter(now) ? d : null,
      type: 'task',
      taskId: t.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Семейные задачи')),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: _tasks.isEmpty
          ? const Center(child: Text('Пока нет задач'))
          : ListView.separated(
              itemCount: _tasks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final t = _tasks[i];
                final dl = t.deadline != null
                    ? DateFormat(
                        'dd.MM.yyyy HH:mm',
                      ).format(t.deadline!.toLocal())
                    : null;
                return Dismissible(
                  key: ValueKey(t.id),
                  background: Container(color: Colors.redAccent),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _delete(t),
                  child: ListTile(
                    onTap: () => _edit(t),
                    leading: Checkbox(
                      value: t.done,
                      onChanged: (_) => _toggleDone(t),
                    ),
                    title: Text(
                      t.title,
                      style: t.done
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            )
                          : null,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((t.description ?? '').isNotEmpty)
                          Text(t.description!),
                        if (dl != null)
                          Text(
                            'Срок: $dl',
                            style: TextStyle(color: cs.secondary),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
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
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    if (t != null) {
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description ?? '';
      _deadline = t.deadline;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: (_deadline ?? now).toLocal(),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime((_deadline ?? now).toLocal()),
    );
    if (t == null) return;
    final picked = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() => _deadline = picked.toUtc());
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final id =
        widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final item = TaskItem(
      id: id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      deadline: _deadline,
      assignedBy: null,
      assignedTo: null,
      shared: false,
      done: widget.initial?.done ?? false,
    );
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final dl = _deadline != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(_deadline!.toLocal())
        : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Новая задача' : 'Редактирование'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Название'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Укажите название' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Описание'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Срок'),
              subtitle: Text(dl ?? 'не задан'),
              trailing: OutlinedButton(
                onPressed: _pickDeadline,
                child: const Text('Выбрать'),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Сохранить')),
          ],
        ),
      ),
    );
  }
}
