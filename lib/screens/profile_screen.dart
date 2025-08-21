import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/notification_bell.dart';
import '../widgets/notif_bell_action.dart';

// ⬇️ ваши существующие импорты ниже
import '../data/profile_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _store = ProfileStore();
  late Profile _p;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _store.load();
    setState(() {
      _p = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: const [
          NotifBellAction(),
          SizedBox(width: 8),
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
                    backgroundImage: (_p.avatarPath != null &&
                            _p.avatarPath!.isNotEmpty &&
                            File(_p.avatarPath!).existsSync())
                        ? FileImage(File(_p.avatarPath!))
                        : null,
                    child: (_p.avatarPath == null || _p.avatarPath!.isEmpty)
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _p.name?.isNotEmpty == true ? _p.name! : 'Имя не указано',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // ——— ваши карточки с полями (как у вас было) ———
                _tile('Телефон', _p.phone),
                _tile('E-mail', _p.email),

                const SizedBox(height: 8),
                Text('Соцсети', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _tile('Instagram', _p.instagram),
                _tile('Discord', _p.discord),
                _tile('Telegram', _p.telegram),
                _tile('Другое', _p.otherSocial),

                const SizedBox(height: 12),
                Text('Учёба / Работа',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _tile('Название', _p.orgName),
                _tile('Адрес', _p.orgAddress),
                _tile('Класс / Должность', _p.orgClassOrRole),

                const SizedBox(height: 12),
                Text('Контакты организации',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _tile('Адрес', _p.orgContactAddress),
                _tile('Телефон', _p.orgContactPhone),
                _tile('E-mail', _p.orgContactEmail),

                const SizedBox(height: 12),
                _tile('Лучшие друзья', _p.bestFriends),
                _tile('Родственная связь', _p.relation),
                _tile('Дата рождения', _p.birthday),

                const SizedBox(height: 12),
                _tile('Интересы', _p.interests),
                _tile('Мечта всей жизни', _p.lifeDream),
                _tile('Желания на 6–12 месяцев', _p.shortMidWishes),

                const SizedBox(height: 12),
                if ((_p.extraPhotoPath ?? '').isNotEmpty &&
                    File(_p.extraPhotoPath!).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_p.extraPhotoPath!),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    final updated = await Navigator.of(context)
                        .pushNamed<Profile>('/editProfile', arguments: _p);
                    if (!mounted) return;
                    if (updated != null) {
                      await _store.save(updated);
                      setState(() => _p = updated);
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Редактировать'),
                ),
              ],
            ),
    );
  }

  Widget _tile(String title, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
      ),
    );
    // если у вас были свои виджеты отображения — можете заменить этот helper
  }
}
