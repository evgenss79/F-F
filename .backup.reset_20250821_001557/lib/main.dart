import 'dart:async';
import 'package:flutter/material.dart';

import 'data/local_store.dart';
import 'data/profile_store.dart';
import 'notifications_service.dart';
import 'screens/tasks_screen.dart';

final navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.instance.load();
  await ProfileStore().load();
  NotificationService.init(colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6F61),
        brightness: Brightness.light,
      ),
      textTheme: Typography.blackCupertino,
    );
    final dark = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6F61),
        brightness: Brightness.dark,
      ),
      textTheme: Typography.whiteCupertino,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Family App',
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

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _PageTemplate(
        title: 'Семейный чат',
        subtitle: 'Здесь будет общение семьи',
        icon: Icons.forum,
      ),
      const TasksScreen(),
      const _PageTemplate(
        title: 'Семейные альбомы',
        subtitle: 'Фото и видео семьи',
        icon: Icons.photo_library,
      ),
      const ProfileScreen(),
      const NotificationsInbox(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Family App')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.forum), label: 'Чат'),
          NavigationDestination(
            icon: Icon(Icons.check_circle),
            label: 'Задачи',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library),
            label: 'Альбомы',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Профиль'),
          NavigationDestination(
            icon: Icon(Icons.notifications),
            label: 'Уведомления',
          ),
        ],
      ),
    );
  }
}

class _PageTemplate extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _PageTemplate({
    required this.title,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: cs.primary),
                const SizedBox(height: 12),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(subtitle, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final p = ProfileStore().profile;
    _name = TextEditingController(text: p?.name ?? '');
    _bio = TextEditingController(text: p?.bio ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final p = Profile(
      name: _name.text.trim(),
      bio: _bio.text.trim(),
      avatarUrl: ProfileStore().profile?.avatarUrl,
    );
    await ProfileStore().save(p);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Профиль сохранён')));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = ProfileStore().profile;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(
              (p?.name.isNotEmpty == true ? p!.name[0] : '🙂'),
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Имя',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bio,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'О себе',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

class NotificationsInbox extends StatefulWidget {
  const NotificationsInbox({super.key});
  @override
  State<NotificationsInbox> createState() => _NotificationsInboxState();
}

class _NotificationsInboxState extends State<NotificationsInbox> {
  @override
  Widget build(BuildContext context) {
    final items = LocalStore.instance.notifications.reversed.toList();
    if (items.isEmpty) {
      return const Center(child: Text('Пока нет уведомлений'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final n = items[i];
        return ListTile(
          leading: const Icon(Icons.notifications),
          title: Text(n.title),
          subtitle: Text(
            '${n.body.isNotEmpty ? '${n.body}\n' : ''}'
            'Когда: ${n.when?.toLocal() ?? DateTime.now().toLocal()}',
          ),
          dense: true,
        );
      },
    );
  }
}
