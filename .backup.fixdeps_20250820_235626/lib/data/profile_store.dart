import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Profile {
  final String id;
  final String name;
  final String? avatarPath;
  final List<String> photos;

  const Profile({
    required this.id,
    required this.name,
    this.avatarPath,
    this.photos = const [],
  });

  Profile copyWith({
    String? id,
    String? name,
    String? avatarPath,
    List<String>? photos,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      photos: photos ?? this.photos,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarPath': avatarPath,
    'photos': photos,
  };

  static Profile fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    name: json['name'] as String,
    avatarPath: json['avatarPath'] as String?,
    photos: (json['photos'] as List?)?.cast<String>() ?? const [],
  );
}

class ProfileStore {
  static final ProfileStore _i = ProfileStore._();
  factory ProfileStore() => _i;
  ProfileStore._();

  Profile? _cached;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    final dataDir = Directory('${dir.path}/family_app_data');
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return File('${dataDir.path}/profile.json');
  }

  Future<Profile?> load() async {
    if (_cached != null) return _cached;
    final f = await _file();
    if (!await f.exists()) return null;
    final map = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    _cached = Profile.fromJson(map);
    return _cached;
  }

  Future<void> save(Profile p) async {
    _cached = p;
    final f = await _file();
    await f.writeAsString(jsonEncode(p.toJson()));
  }

  Future<String> importFile(File src, {required String basename}) async {
    final dir = await getApplicationSupportDirectory();
    final dataDir = Directory('${dir.path}/family_app_data');
    if (!await dataDir.exists()) await dataDir.create(recursive: true);
    final dst = File('${dataDir.path}/$basename');
    await src.copy(dst.path);
    return dst.path;
  }
}
