// lib/notifications_screen.dart
import 'package:flutter/material.dart';
import 'notifications_db.dart';
import 'notifications_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filter = 'all';
  List<NotificationItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await NotificationsDB.getAll(type: _filter == 'all' ? null : _filter);
    setState(() => _items = data);
    await NotificationService.refresh(); // синхронизируем бейдж
  }

  Future<void> _clearAll() async {
    await NotificationsDB.clearAll();
    await _load();
  }

  Future<void> _markRead(NotificationItem n) async {
    if (!n.isRead && n.id != null) {
      await NotificationsDB.markAsRead(n.id!);
      await _load();
    }
  }

  Future<void> _delete(NotificationItem n) async {
    if (n.id != null) {
      await NotificationsDB.deleteById(n.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<NotificationItem>>{};
    for (final n in _items) {
      grouped.putIfAbsent(n.type, () => []).add(n);
    }
    final typesOrder = ['task', 'system'];
    final sections = [
      ...typesOrder.where((t) => grouped.containsKey(t)).map((t) => MapEntry(t, grouped[t]!)),
      ...grouped.entries.where((e) => !typesOrder.contains(e.key)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Очистить все',
            onPressed: _items.isEmpty ? null : _clearAll,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Все'),
                selected: _filter == 'all',
                onSelected: (_) => setState(() {
                  _filter = 'all';
                  _load();
                }),
              ),
              ChoiceChip(
                label: const Text('Задачи'),
                selected: _filter == 'task',
                onSelected: (_) => setState(() {
                  _filter = 'task';
                  _load();
                }),
              ),
              ChoiceChip(
                label: const Text('Системные'),
                selected: _filter == 'system',
                onSelected: (_) => setState(() {
                  _filter = 'system';
                  _load();
                }),
              ),
            ],
          ),
          const Divider(height: 16),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Нет уведомлений'))
                : ListView(
                    children: sections.expand((entry) sync* {
                      final type = entry.key;
                      final list = entry.value;
                      final title = type == 'task'
                          ? 'Задачи'
                          : (type == 'system' ? 'Системные' : type);
                      yield Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      );
                      for (final n in list) {
                        yield Dismissible(
                          key: ValueKey('n_${n.id}_${n.timestamp}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _delete(n),
                          child: ListTile(
                            title: Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w700,
                              ),
                            ),
                            subtitle: Text('${n.body}\n${n.timestamp}'),
                            isThreeLine: true,
                            onTap: () => _markRead(n),
                          ),
                        );
                      }
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
