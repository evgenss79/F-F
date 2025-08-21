import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:family_app/data/profile_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ProfileStore().load();
    setState(() {
      _profile = p ?? const Profile(id: 'me', name: 'Я');
      _loading = false;
    });
  }

  Future<void> _pickAvatar() async {
    final typeGroup = const XTypeGroup(
      label: 'images',
      extensions: ['png', 'jpg', 'jpeg', 'webp', 'heic', 'gif'],
    );
    final xfile = await openFile(acceptedTypeGroups: [typeGroup]);
    if (xfile == null) return;
    final imported = await ProfileStore().importFile(
      File(xfile.path),
      basename: 'profile_avatar${p.extension(xfile.path)}',
    );
    final updated = _profile!.copyWith(avatarPath: imported);
    await ProfileStore().save(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  Future<void> _addPhoto() async {
    final typeGroup = const XTypeGroup(
      label: 'images',
      extensions: ['png', 'jpg', 'jpeg', 'webp', 'heic', 'gif'],
    );
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty) return;
    final store = ProfileStore();
    final List<String> added = [];
    for (final f in files) {
      final name =
          'gallery_${DateTime.now().millisecondsSinceEpoch}${p.extension(f.path)}';
      final saved = await store.importFile(File(f.path), basename: name);
      added.add(saved);
    }
    final updated = _profile!.copyWith(photos: [..._profile!.photos, ...added]);
    await store.save(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  Future<void> _removePhoto(String path) async {
    final updated = _profile!.copyWith(
      photos: _profile!.photos.where((e) => e != path).toList(),
    );
    await ProfileStore().save(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final p = _profile!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            tooltip: 'Добавить фото',
            onPressed: _addPhoto,
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: cs.secondaryContainer,
                  backgroundImage:
                      (p.avatarPath != null && File(p.avatarPath!).existsSync())
                      ? FileImage(File(p.avatarPath!))
                      : null,
                  child:
                      (p.avatarPath == null ||
                          !File(p.avatarPath!).existsSync())
                      ? Text(
                          p.name.isNotEmpty
                              ? p.name.characters.first.toUpperCase()
                              : '🙂',
                          style: const TextStyle(fontSize: 28),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  p.name.isEmpty ? 'Без имени' : p.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Фотографии', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (p.photos.isEmpty)
            const Text('Пока нет фото. Нажми «плюс» вверху, чтобы добавить.'),
          if (p.photos.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: p.photos.map((path) {
                final exists = File(path).existsSync();
                return Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: cs.surfaceVariant,
                      ),
                      child: exists
                          ? Image.file(File(path), fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                'файл\nне найден',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _removePhoto(path),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
