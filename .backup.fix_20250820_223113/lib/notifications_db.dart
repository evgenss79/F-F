// lib/notifications_db.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class NotificationItem {
  final int? id;
  final String title;
  final String body;
  final String timestamp; // ISO8601
  final bool isRead;
  final String type; // 'task' | 'system' | другое

  NotificationItem({
    this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.type = 'system',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp,
      'isRead': isRead ? 1 : 0,
      'type': type,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      timestamp: map['timestamp'] as String? ?? '',
      isRead: (map['isRead'] ?? 0) == 1,
      type: (map['type'] as String?) ?? 'system',
    );
  }
}

class NotificationsDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'notifications.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notifications(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            body TEXT,
            timestamp TEXT,
            isRead INTEGER,
            type TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // добавим колонку type, по умолчанию 'system'
          await db.execute(
            "ALTER TABLE notifications ADD COLUMN type TEXT DEFAULT 'system'",
          );
        }
      },
    );
  }

  static Future<void> insert(NotificationItem item) async {
    final db = await database;
    await db.insert(
      'notifications',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<NotificationItem>> getAll({String? type}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (type == null || type == 'all') {
      maps = await db.query('notifications', orderBy: 'id DESC');
    } else {
      maps = await db.query(
        'notifications',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'id DESC',
      );
    }
    return List.generate(maps.length, (i) => NotificationItem.fromMap(maps[i]));
  }

  static Future<void> markAsRead(int id) async {
    final db = await database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('notifications');
  }

  static Future<int> unreadCount() async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM notifications WHERE isRead = 0',
    );
    return (res.isNotEmpty ? (res.first['c'] as int?) : 0) ?? 0;
  }
}
