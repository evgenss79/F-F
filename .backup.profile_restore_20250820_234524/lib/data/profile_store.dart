import 'dart:convert';
import 'dart:io';

class Profile {
  final String name;
  final String? avatarUrl;
  final String? bio;

  const Profile({required this.name, this.avatarUrl, this.bio});

  Profile copyWith({String? name, String? avatarUrl, String? bio}) => Profile(
    name: name ?? this.name,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    bio: bio ?? this.bio,
  );

  Map<String, dynamic> toJson() => {'name': name, 'avatarUrl': avatarUrl, 'bio': bio};

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    name: j['name'] as String? ?? '',
    avatarUrl: j['avatarUrl'] as String?,
    bio: j['bio'] as String?,
  );
}

class ProfileStore {
  static final ProfileStore _i = ProfileStore._();
  factory ProfileStore() => _i;
  ProfileStore._();

  Profile? profile;
  late final File _file;

  Future<void> load() async {
    final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
    final dir = Directory('$home/Documents/family_app_data');
    if (!await dir.exists()) await dir.create(recursive: true);
    _file = File('${dir.path}/profile.json');

    if (await _file.exists()) {
      final raw = await _file.readAsString();
      profile = Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } else {
      profile = const Profile(name: '');
    }
  }

  Future<void> save(Profile p) async {
    profile = p;
    await _file.writeAsString(jsonEncode(p.toJson()));
  }
}
