import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../notifications_service.dart';
import '../widgets/notification_bell.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  AppNotificationType? _typeFilter;
  String? _assigneeFilter; // id исполнителя (если надо фильтровать по человеку)
  bool _onlyUnread = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: NotificationService.unreadCount,
            builder: (_, c, __) => NotificationBell(
              count: c,
              onTap: () {}, // уже на экране уведомлений
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _FiltersBar(
            type: _typeFilter,
            onlyUnread: _onlyUnread,
            assigneeId: _assigneeFilter,
            onChangeType: (t) => setState(() => _typeFilter = t),
            onToggleUnread: (v) => setState(() => _onlyUnread = v),
            onChangeAssignee: (id) => setState(() => _assigneeFilter = id),
          ),
          const Divider(height: 0),
          Expanded(
            child: ValueListenableBuilder<List<AppNotification>>(
              valueListenable: NotificationService.list,
              builder: (context, all, _) {
                final items = all.where((n) {
                  if (_onlyUnread && n.read) return false;
                  if (_typeFilter != null && n.type != _typeFilter)
                    return false;
                  if (_assigneeFilter != null &&
                      _assigneeFilter!.isNotEmpty &&
                      n.assigneeId != _assigneeFilter) {
                    return false;
                  }
                  return true;
                }).toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (items.isEmpty) {
                  return const Center(child: Text('Пока нет уведомлений'));
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    final overdue = n.type == AppNotificationType.taskOverdue;

                    final titleStyle =
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  n.read ? FontWeight.w500 : FontWeight.w800,
                              color: overdue ? cs.error : null,
                            );

                    final when = _fmtDateTime(n.createdAt);

                    return ListTile(
                      leading: Icon(
                        _iconFor(n.type),
                        color: overdue ? cs.error : cs.primary,
                      ),

                      // 🔹 Заголовок = название задачи (body). Если пусто — fallback на title.
                      title: Text(
                        (n.body ?? '').isNotEmpty ? n.body! : n.title,
                        style: titleStyle,
                      ),

                      // 🔹 Подзаголовок = служебные детали (время, исполнитель).
                      subtitle: Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: cs.outline),
                          const SizedBox(width: 4),
                          Text(
                            when,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: overdue ? cs.error : null,
                                ),
                          ),
                          if ((n.assigneeName ?? '').isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.person, size: 14, color: cs.outline),
                            const SizedBox(width: 4),
                            Text(
                              n.assigneeName!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: overdue ? cs.error : null,
                                  ),
                            ),
                          ],
                        ],
                      ),

                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'read') {
                            await NotificationService.markRead(n.id);
                          } else if (v == 'delete') {
                            await NotificationService.delete(n.id);
                          }
                        },
                        itemBuilder: (_) => [
                          if (!n.read)
                            const PopupMenuItem(
                              value: 'read',
                              child: Text('Отметить прочитанным'),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Удалить'),
                          ),
                        ],
                      ),
                      onTap: () async {
                        if (!n.read) await NotificationService.markRead(n.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActions(),
    );
  }

  static IconData _iconFor(AppNotificationType t) {
    switch (t) {
      case AppNotificationType.general:
        return Icons.notifications;
      case AppNotificationType.system:
        return Icons.settings;
      case AppNotificationType.taskCreated:
        return Icons.add_task;
      case AppNotificationType.taskUpdated:
        return Icons.edit;
      case AppNotificationType.taskDone:
        return Icons.check_circle;
      case AppNotificationType.taskDeleted:
        return Icons.delete;
      case AppNotificationType.taskOverdue:
        return Icons.warning_amber_rounded;
    }
  }

  static String _fmtDateTime(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _FiltersBar extends StatelessWidget {
  final AppNotificationType? type;
  final bool onlyUnread;
  final String? assigneeId;
  final ValueChanged<AppNotificationType?> onChangeType;
  final ValueChanged<bool> onToggleUnread;
  final ValueChanged<String?> onChangeAssignee;

  const _FiltersBar({
    required this.type,
    required this.onlyUnread,
    required this.assigneeId,
    required this.onChangeType,
    required this.onToggleUnread,
    required this.onChangeAssignee,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            FilterChip(
              selected: onlyUnread,
              label: const Text('Непрочитанные'),
              onSelected: (v) => onToggleUnread(v),
            ),
            _chip(context, 'Все', null),
            _chip(context, 'Системные', AppNotificationType.system),
            _chip(context, 'Созданы', AppNotificationType.taskCreated),
            _chip(context, 'Обновлены', AppNotificationType.taskUpdated),
            _chip(context, 'Выполнены', AppNotificationType.taskDone),
            _chip(context, 'Удалены', AppNotificationType.taskDeleted),
            _chip(context, 'Просрочены', AppNotificationType.taskOverdue),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String text, AppNotificationType? t) {
    final selected = type == t;
    return FilterChip(
      selected: selected,
      label: Text(text),
      onSelected: (_) => onChangeType(selected ? null : t),
    );
  }
}

class _BottomActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => NotificationService.markAllRead(),
                icon: const Icon(Icons.mark_email_read_outlined),
                label: const Text('Все прочитаны'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => NotificationService.clear(),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Очистить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
