// lib/main.dart
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// Firebase (после flutterfire configure)
// Наши сервисы уведомлений
import 'notifications_service.dart';
import 'services/notify.dart';

// Экран списка уведомлений
import 'notifications_screen.dart';

// Локальное хранилище задач/профиля
import 'data/local_store.dart';
import 'data/profile_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Шрифты Google — не тянуть с сети на macOS
  GoogleFonts.config.allowRuntimeFetching = false;

  // Firebase
  // Локальные уведомления
  await Notify.init();
  await Notify.requestPermissions();

  // Локальный реестр уведомлений (колокольчик/список)
  await NotificationService.init();

  runApp(const FamilyApp());
}

class FamilyApp extends StatelessWidget {
  const FamilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6F61),
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(),
    );

    final dark = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6F61),
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FamilySpace',
      theme: light,
      darkTheme: dark,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    ChatScreen(),
    TasksScreen(),
    AlbumsScreen(),
    ProfileScreen(),
  ];

  List<Widget> _buildBellActions(BuildContext context, VoidCallback onReturn) {
    return [
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
          await NotificationService.refresh();
          onReturn();
          if (mounted) setState(() {});
        },
        tooltip: 'Уведомления',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _pages[_index],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.forum_outlined), label: 'Чат'),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outlined),
            label: 'Задачи',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_album_outlined),
            label: 'Альбомы',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

/// ----- Чат (заглушка) -----
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const _PageTemplate(
      title: 'Семейный чат',
      subtitle: 'Здесь будет общение семьи',
      icon: Icons.forum_outlined,
      actionsBuilder: null,
    );
  }
}

/// ----- Задачи (общие/индивидуальные + дедлайны + уведомления) -----
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _store = LocalStore();
  final _input = TextEditingController();

  List<TaskItem> _tasks = [];
  bool _loading = true;
  String _currentUserName = 'Я';

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isShared(TaskItem t) => (t.assignedTo == null || t.assignedTo!.isEmpty);

  Future<void> _load() async {
    final list = await _store.loadTasks();
    final profile = await ProfileStore().load();
    setState(() {
      _tasks = list;
      _currentUserName = (profile.name?.trim().isNotEmpty == true)
          ? profile.name!.trim()
          : 'Я';
      _loading = false;
    });
  }

  Future<void> _save() async => _store.saveTasks(_tasks);

  Future<void> _scheduleReminders(TaskItem t) async {
    if (t.deadline == null) return;
    final base = t.id.hashCode.abs();
    // Отменим прежние
    await Notify.cancel(base * 10 + 1);
    await Notify.cancel(base * 10 + 2);
    await Notify.cancel(base * 10 + 3);

    final now = DateTime.now();
    final deadline = t.deadline!;
    final oneHour = deadline.subtract(const Duration(hours: 1));
    final fifteen = deadline.subtract(const Duration(minutes: 15));

    if (oneHour.isAfter(now)) {
      await Notify.schedule(
        id: base * 10 + 1,
        title: 'Срок по задаче',
        body: '«${t.title}» через 1 час. Назначил: ${t.assignedBy ?? '—'}',
        when: oneHour,
      );
    }
    if (fifteen.isAfter(now)) {
      await Notify.schedule(
        id: base * 10 + 2,
        title: 'Срок по задаче скоро',
        body:
            '«${t.title}» через 15 минут. Исполнитель: ${t.assignedTo ?? 'не назначен'}',
        when: fifteen,
      );
    }
    if (deadline.isAfter(now)) {
      await Notify.schedule(
        id: base * 10 + 3,
        title: 'Наступил срок задачи',
        body: '«${t.title}» — срок наступил.',
        when: deadline,
      );
    }
  }

  Future<void> _addTask({TaskItem? edit}) async {
    final result = await Navigator.of(context).push<TaskItem>(
      MaterialPageRoute(
        builder: (_) =>
            _TaskEditor(currentUserName: _currentUserName, initial: edit),
      ),
    );
    if (result == null) return;
    setState(() {
      if (edit == null) {
        _tasks = [..._tasks, result];
      } else {
        _tasks = _tasks.map((e) => e.id == edit.id ? result : e).toList();
      }
    });
    await _save();

    // Лог в уведомления (внутренний список колокольчика)
    await NotificationService.addNotification(
      context,
      title: edit == null ? 'Новая задача' : 'Задача обновлена',
      body: result.title,
      type: 'task',
    );

    // Планируем локальные напоминания
    await _scheduleReminders(result);
  }

  Future<void> _toggleDone(TaskItem t, bool v) async {
    setState(() {
      _tasks = _tasks
          .map((e) => e.id == t.id ? e.copyWith(done: v) : e)
          .toList();
    });
    await _save();

    await NotificationService.addNotification(
      context,
      title: v ? 'Задача выполнена' : 'Задача снова активна',
      body: t.title,
      type: 'task',
    );
  }

  Future<void> _delete(TaskItem t) async {
    // Может удалить только назначивший
    if ((t.assignedBy ?? '') != _currentUserName) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Удалить может только назначивший задачу'),
        ),
      );
      return;
    }

    setState(() {
      _tasks = _tasks.where((e) => e.id != t.id).toList();
    });
    await _save();

    await NotificationService.addNotification(
      context,
      title: 'Задача удалена',
      body: t.title,
      type: 'task',
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = (BuildContext ctx) => <Widget>[
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        tooltip: 'Уведомления',
        onPressed: () async {
          await Navigator.of(ctx).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
          await NotificationService.refresh();
          if (mounted) setState(() {});
        },
      ),
    ];

    final shared = _tasks.where(_isShared).toList();
    final personal = _tasks.where((t) => !_isShared(t)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи семьи'),
        actions: actions(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTask(),
        label: const Text('Добавить'),
        icon: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 8),
                const _SectionHeader('Общие задачи'),
                if (shared.isEmpty)
                  const _HintText('Нет общих задач. Добавьте первую.'),
                ...shared.map(
                  (t) => _TaskTile(
                    task: t,
                    onToggle: (v) => _toggleDone(t, v),
                    onEdit: () => _addTask(edit: t),
                    onDelete: () => _delete(t),
                    isShared: true,
                  ),
                ),
                const Divider(height: 24),
                const _SectionHeader('Индивидуальные задачи'),
                if (personal.isEmpty)
                  const _HintText('Нет индивидуальных задач. Добавьте первую.'),
                ...personal.map(
                  (t) => _TaskTile(
                    task: t,
                    onToggle: (v) => _toggleDone(t, v),
                    onEdit: () => _addTask(edit: t),
                    onDelete: () => _delete(t),
                    isShared: false,
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  final String text;
  const _HintText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskItem task;
  final bool isShared;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.isShared,
    super.key,
  });

  String _assignedLine() {
    final created = task.createdAt != null
        ? 'создана ${task.createdAt!.toLocal().toString().substring(0, 16)}'
        : '';
    final deadline = task.deadline != null
        ? 'до ${task.deadline!.toLocal().toString().substring(0, 16)}'
        : '';
    final who = isShared
        ? 'назначил: ${task.assignedBy ?? '—'}'
        : 'исполнитель: ${task.assignedTo ?? '—'}, назначил: ${task.assignedBy ?? '—'}';
    final parts = [who, created, if (deadline.isNotEmpty) deadline];
    return parts.where((e) => e.isNotEmpty).join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // сами удалим, если правила разрешат
      },
      child: CheckboxListTile(
        value: task.done,
        title: Text(
          task.title,
          style: task.done
              ? const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                )
              : null,
        ),
        subtitle: Text(_assignedLine()),
        secondary: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
          tooltip: 'Редактировать',
        ),
        onChanged: (v) => onToggle(v ?? false),
      ),
    );
  }
}

/// ----- Альбомы (заглушка) -----
class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const _PageTemplate(
      title: 'Семейные альбомы',
      subtitle: 'Фото и видео семьи',
      icon: Icons.photo_album_outlined,
      actionsBuilder: null,
    );
  }
}

/// ----- Профиль (имя + аватар, кнопка редактировать) -----
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _store = ProfileStore();
  Profile _profile = const Profile();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _store.load();
    setState(() {
      _profile = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              await NotificationService.refresh();
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage:
                        (_profile.avatarPath != null &&
                            _profile.avatarPath!.isNotEmpty)
                        ? FileImage(File(_profile.avatarPath!))
                        : null,
                    child:
                        (_profile.avatarPath == null ||
                            _profile.avatarPath!.isEmpty)
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _profile.name?.isNotEmpty == true
                        ? _profile.name!
                        : 'Имя не указано',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final changed = await Navigator.push<Profile>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(initial: _profile),
                      ),
                    );
                    if (changed != null) {
                      await _store.save(changed);
                      if (mounted) setState(() => _profile = changed);
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Редактировать'),
                ),
              ],
            ),
    );
  }
}

/// ----- Экран редактирования профиля -----
class EditProfileScreen extends StatefulWidget {
  final Profile initial;
  const EditProfileScreen({super.key, required this.initial});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _instagram = TextEditingController();
  final _discord = TextEditingController();
  final _telegram = TextEditingController();
  final _otherSocial = TextEditingController();
  final _orgName = TextEditingController();
  final _orgAddress = TextEditingController();
  final _orgClassOrRole = TextEditingController();
  final _orgContactAddress = TextEditingController();
  final _orgContactPhone = TextEditingController();
  final _orgContactEmail = TextEditingController();
  final _bestFriends = TextEditingController();
  final _birthday = TextEditingController();
  final _interests = TextEditingController();
  final _lifeDream = TextEditingController();
  final _shortMidWishes = TextEditingController();

  String? _avatarPath;
  String? _extraPhotoPath;
  String _relation = 'сын';

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name.text = p.name ?? '';
    _phone.text = p.phone ?? '';
    _email.text = p.email ?? '';
    _instagram.text = p.instagram ?? '';
    _discord.text = p.discord ?? '';
    _telegram.text = p.telegram ?? '';
    _otherSocial.text = p.otherSocial ?? '';
    _orgName.text = p.orgName ?? '';
    _orgAddress.text = p.orgAddress ?? '';
    _orgClassOrRole.text = p.orgClassOrRole ?? '';
    _orgContactAddress.text = p.orgContactAddress ?? '';
    _orgContactPhone.text = p.orgContactPhone ?? '';
    _orgContactEmail.text = p.orgContactEmail ?? '';
    _bestFriends.text = p.bestFriends ?? '';
    _relation = p.relation ?? 'сын';
    _birthday.text = p.birthday ?? '';
    _interests.text = p.interests ?? '';
    _lifeDream.text = p.lifeDream ?? '';
    _shortMidWishes.text = p.shortMidWishes ?? '';
    _avatarPath = p.avatarPath;
    _extraPhotoPath = p.extraPhotoPath;
  }

  Future<void> _pickImage(bool isAvatar) async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (x != null) {
      setState(() {
        if (isAvatar) {
          _avatarPath = x.path;
        } else {
          _extraPhotoPath = x.path;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование профиля'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              await NotificationService.refresh();
            },
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: cs.primaryContainer,
                      backgroundImage:
                          (_avatarPath != null && _avatarPath!.isNotEmpty)
                          ? FileImage(File(_avatarPath!))
                          : null,
                      child: (_avatarPath == null || _avatarPath!.isEmpty)
                          ? const Icon(Icons.person, size: 36)
                          : null,
                    ),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: IconButton(
                        onPressed: () => _pickImage(true),
                        icon: const Icon(Icons.edit, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: cs.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Имя'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Контакты
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Номер телефона'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),

            const SizedBox(height: 12),
            // Соцсети
            Text(
              'Профили в соцсетях',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _instagram,
              decoration: const InputDecoration(labelText: 'Instagram'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _discord,
              decoration: const InputDecoration(labelText: 'Discord'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _telegram,
              decoration: const InputDecoration(labelText: 'Telegram'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _otherSocial,
              decoration: const InputDecoration(labelText: 'Другое'),
            ),

            const SizedBox(height: 12),
            // Учёба/Работа
            Text(
              'Учебное заведение / Работа',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _orgName,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _orgAddress,
              decoration: const InputDecoration(labelText: 'Адрес'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _orgClassOrRole,
              decoration: const InputDecoration(labelText: 'Класс / Должность'),
            ),

            const SizedBox(height: 12),
            // Контакты учебного/работы
            Text(
              'Контакты учебного заведения / работодателя',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _orgContactAddress,
              decoration: const InputDecoration(labelText: 'Адрес'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _orgContactPhone,
              decoration: const InputDecoration(labelText: 'Телефон'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _orgContactEmail,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),

            const SizedBox(height: 12),
            // Друзья
            TextFormField(
              controller: _bestFriends,
              decoration: const InputDecoration(
                labelText: 'Лучшие друзья и их контакты',
                hintText: 'Имя — телефон/email; по одному в строке',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 12),
            // Родственная связь
            DropdownButtonFormField<String>(
              value: _relation,
              decoration: const InputDecoration(labelText: 'Родственная связь'),
              items: const [
                DropdownMenuItem(value: 'сын', child: Text('Сын')),
                DropdownMenuItem(value: 'дочь', child: Text('Дочь')),
                DropdownMenuItem(value: 'мама', child: Text('Мама')),
                DropdownMenuItem(value: 'папа', child: Text('Папа')),
                DropdownMenuItem(value: 'племянник', child: Text('Племянник')),
                DropdownMenuItem(
                  value: 'племянница',
                  child: Text('Племянница'),
                ),
                DropdownMenuItem(value: 'дедушка', child: Text('Дедушка')),
                DropdownMenuItem(value: 'бабушка', child: Text('Бабушка')),
                DropdownMenuItem(value: 'другое', child: Text('Другое')),
              ],
              onChanged: (v) => setState(() => _relation = v ?? 'сын'),
            ),

            const SizedBox(height: 8),
            TextFormField(
              controller: _birthday,
              decoration: const InputDecoration(
                labelText: 'Дата рождения (YYYY-MM-DD)',
              ),
            ),

            const SizedBox(height: 12),
            TextFormField(
              controller: _interests,
              decoration: const InputDecoration(labelText: 'Интересы / хобби'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lifeDream,
              decoration: const InputDecoration(labelText: 'Мечта всей жизни'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _shortMidWishes,
              decoration: const InputDecoration(
                labelText: 'Желания на 6–12 месяцев',
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 12),
            // Доп. фото
            Text('Доп. фото', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child:
                      (_extraPhotoPath != null && _extraPhotoPath!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_extraPhotoPath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cs.outline),
                          ),
                          child: const Icon(Icons.photo, size: 32),
                        ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(false),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Выбрать фото'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final profile = Profile(
                  name: _name.text.trim(),
                  avatarPath: _avatarPath,
                  phone: _phone.text.trim(),
                  email: _email.text.trim(),
                  instagram: _instagram.text.trim(),
                  discord: _discord.text.trim(),
                  telegram: _telegram.text.trim(),
                  otherSocial: _otherSocial.text.trim(),
                  orgName: _orgName.text.trim(),
                  orgAddress: _orgAddress.text.trim(),
                  orgClassOrRole: _orgClassOrRole.text.trim(),
                  orgContactAddress: _orgContactAddress.text.trim(),
                  orgContactPhone: _orgContactPhone.text.trim(),
                  orgContactEmail: _orgContactEmail.text.trim(),
                  bestFriends: _bestFriends.text.trim(),
                  relation: _relation,
                  birthday: _birthday.text.trim(),
                  interests: _interests.text.trim(),
                  lifeDream: _lifeDream.text.trim(),
                  shortMidWishes: _shortMidWishes.text.trim(),
                  extraPhotoPath: _extraPhotoPath,
                );
                await ProfileStore().save(profile);
                if (mounted) Navigator.pop(context, profile);
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ----- Редактор задачи -----
class _TaskEditor extends StatefulWidget {
  final TaskItem? initial;
  final String currentUserName;
  const _TaskEditor({required this.currentUserName, this.initial});

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  final _title = TextEditingController();
  final _assignedTo = TextEditingController();
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _title.text = i.title;
      _assignedTo.text = i.assignedTo ?? '';
      _deadline = i.deadline;
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      initialDate: _deadline?.toLocal() ?? now,
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline?.toLocal() ?? now),
    );
    if (t == null) return;
    final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() => _deadline = dt);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактировать задачу' : 'Новая задача'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Название задачи',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _assignedTo,
            decoration: const InputDecoration(
              labelText: 'Исполнитель (оставьте пустым для «общей»)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDeadline,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _deadline == null
                        ? 'Выбрать срок'
                        : 'Срок: ${_deadline!.toLocal().toString().substring(0, 16)}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              final title = _title.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите название')),
                );
                return;
              }
              final id =
                  widget.initial?.id ??
                  '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
              final item = TaskItem(
                id: id,
                title: title,
                done: widget.initial?.done ?? false,
                createdAt: widget.initial?.createdAt ?? DateTime.now(),
                deadline: _deadline,
                assignedBy:
                    widget.initial?.assignedBy ?? widget.currentUserName,
                assignedTo: _assignedTo.text.trim().isEmpty
                    ? null
                    : _assignedTo.text.trim(),
              );
              Navigator.of(context).pop(item);
            },
            icon: const Icon(Icons.save_outlined),
            label: Text(isEdit ? 'Сохранить' : 'Добавить'),
          ),
        ],
      ),
    );
  }
}

/// Общий шаблон пустой страницы
class _PageTemplate extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> Function(BuildContext context)? actionsBuilder;

  const _PageTemplate({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionsBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actionsBuilder == null ? null : actionsBuilder!(context),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 56, color: cs.primary),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(subtitle, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
