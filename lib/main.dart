import 'package:flutter/material.dart';
import 'data/local_store.dart';
import 'notifications_service.dart';
import 'widgets/notification_bell.dart';
import 'screens/notifications_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/notif_bell_action.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.instance.load();
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
    );

    final dark = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6F61),
        brightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Family App',
      theme: light,
      darkTheme: dark,
      home: const HomeShell(),
      routes: {
        '/notifications': (_) => const NotificationsScreen(),
      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: _pages[_index],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.forum_outlined), label: 'Чат'),
          NavigationDestination(
              icon: Icon(Icons.check_circle_outlined), label: 'Задачи'),
          NavigationDestination(
              icon: Icon(Icons.photo_album_outlined), label: 'Альбомы'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Профиль'),
        ],
      ),
    );
  }
}

PreferredSizeWidget buildAppBar(BuildContext context, String title) {
  return AppBar(
    title: Text(title),
    actions: const [
      NotifBellAction(),
      SizedBox(width: 8),
    ],
  );
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Семейный чат'),
      body: const Center(child: Text('Здесь будет чат')),
    );
  }
}

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Семейные альбомы'),
      body: const Center(child: Text('Здесь будут альбомы')),
    );
  }
}
