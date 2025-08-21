import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _avatar;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('profile_name');
    final avatarBase64 = prefs.getString('profile_avatar');
    if (name != null) _nameController.text = name;
    if (avatarBase64 != null) {
      final bytes = base64Decode(avatarBase64);
      final tempFile = File('${Directory.systemTemp.path}/avatar.png');
      await tempFile.writeAsBytes(bytes);
      setState(() => _avatar = tempFile);
    }
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text);
    if (_avatar != null) {
      final bytes = await _avatar!.readAsBytes();
      await prefs.setString('profile_avatar', base64Encode(bytes));
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _avatar = File(picked.path));
      _saveProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Профиль")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _avatar != null ? FileImage(_avatar!) : null,
                child: _avatar == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Имя"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _saveProfile();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Профиль сохранён")),
                );
              },
              child: const Text("Сохранить"),
            ),
          ],
        ),
      ),
    );
  }
}
