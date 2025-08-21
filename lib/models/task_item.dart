import 'dart:convert';

class TaskItem {
  final String id;
  final String title;
  final bool done;

  /// id исполнителя (член семьи)
  final String? assigneeId;

  /// отображаемое имя исполнителя (кэш, чтобы не искать каждый раз)
  final String? assigneeName;

  /// id создателя задачи
  final String creatorId;

  /// срок выполнения
  final DateTime? dueAt;

  /// произвольный комментарий к задаче
  final String? comment;

  TaskItem({
    required this.id,
    required this.title,
    required this.creatorId,
    this.done = false,
    this.assigneeId,
    this.assigneeName,
    this.dueAt,
    this.comment,
  });

  /// Удобное создание с автогенерацией id
  static TaskItem create({
    required String title,
    required String creatorId,
    String? assigneeId,
    String? assigneeName,
    DateTime? dueAt,
    String? comment,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return TaskItem(
      id: id,
      title: title,
      creatorId: creatorId,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      dueAt: dueAt,
      comment: comment,
      done: false,
    );
  }

  TaskItem copyWith({
    String? id,
    String? title,
    bool? done,
    String? assigneeId,
    String? assigneeName,
    String? creatorId,
    DateTime? dueAt,
    String? comment,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      creatorId: creatorId ?? this.creatorId,
      done: done ?? this.done,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      dueAt: dueAt ?? this.dueAt,
      comment: comment ?? this.comment,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'done': done,
        'assigneeId': assigneeId,
        'assigneeName': assigneeName,
        'creatorId': creatorId,
        'dueAt': dueAt?.toIso8601String(),
        'comment': comment,
      };

  static TaskItem fromJson(Map<String, dynamic> j) {
    return TaskItem(
      id: j['id'] as String,
      title: j['title'] as String,
      done: (j['done'] as bool?) ?? false,
      assigneeId: j['assigneeId'] as String?,
      assigneeName: j['assigneeName'] as String?,
      creatorId: j['creatorId'] as String? ?? 'me',
      dueAt:
          j['dueAt'] != null ? DateTime.tryParse(j['dueAt'] as String) : null,
      comment: j['comment'] as String?,
    );
  }

  static String encodeList(List<TaskItem> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<TaskItem> decodeList(String src) {
    final raw = jsonDecode(src) as List<dynamic>;
    return raw
        .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
