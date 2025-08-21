import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Profile {
  String id;
  String name;
  String? bio;
  String? avatarPath;
  List<String> photos;
  String? email;
  String? phone;
  DateTime? birthday;
  String? city;

  Profile({
    String? id,
    required this.name,
    this.bio,
    this.avatarPath,
    List<String>? photos,
    this.email,
    this.phone,
    this.birthday,
    this.city,
  }) : id = id ?? 'me',
       photos = photos ?? [];

  String? get avatarUrl => avatarPath;

  Profile copyWith({
    String? id,
    String? name,
    String? bio,
    String? avatarPath,
    List<String>? photos,
    String? email,
    String? phone,
    DateTime? birthday,
    String? city,
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    bio: bio ?? this.bio,
    avatarPath: avatarPath ?? this.avatarPath,
    photos: photos ?? List<String>.from(this.photos),
    email: email ?? this.email,
    phone: phone ?? this.phone,
    birthday: birthday ?? this.birthday,
    city: city ?? this.city,
  );

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    id: j['id'] as String?,
    name: j['name'] as String? ?? '',
    bio: j['bio'] as String?,
    avatarPath: j['avatarPath'] as String?,
    photos:
        (j['photos'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
    email: j['email'] as String?,
    phone: j['phone'] as String?,
    birthday: j['birthday'] != null ? DateTime.tryParse(j['birthday']) : null,
    city: j['city'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bio': bio,
    'avatarPath': avatarPath,
    'photos': photos,
    'email': email,
    'phone': phone,
    'birthday': birthday?.toIso8601String(),
    'city': city,
  };
}

class ProfileStore {
  ProfileStore._();
  static final ProfileStore _i = ProfileStore._();
  factory ProfileStore() => _i;

  Profile profile = Profile(name: '');

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/profile.json');
  }

  Future<Directory> _mediaDir() async {
    final dir = await getApplicationSupportDirectory();
    final d = Directory('${dir.path}/media');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<void> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final j = jsonDecode(await f.readAsString());
      profile = Profile.fromJson(Map<String, dynamic>.from(j));
    } catch (_) {}
  }

  Future<void> save(Profile p) async {
    profile = p;
    try {
      final f = await _file();
      await f.create(recursive: true);
      await f.writeAsString(jsonEncode(profile.toJson()));
    } catch (_) {}
  }

  Future<String?> importFile(String sourcePath) async {
    try {
      final src = File(sourcePath);
      if (!await src.exists()) return null;
      final dir = await _mediaDir();
      final name =
          DateTime.now().millisecondsSinceEpoch.toString() +
          '_' +
          src.uri.pathSegments.last;
      final dst = File('${dir.path}/$name');
      await src.copy(dst.path);
      return dst.path;
    } catch (_) {
      return null;
    }
  }
}
