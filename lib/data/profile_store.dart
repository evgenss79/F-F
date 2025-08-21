import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class Profile {
  final String name;
  final String? avatarPath;
  final String? extraPhotoPath;

  final String? phone;
  final String? email;

  final String? instagram;
  final String? discord;
  final String? telegram;
  final String? otherSocial;

  final String? orgName;
  final String? orgAddress;
  final String? orgClassOrRole;

  final String? orgContactAddress;
  final String? orgContactPhone;
  final String? orgContactEmail;

  final String? bestFriends; // список в свободной форме (по строке на друга)
  final String? relation; // сын/дочь/мама/папа/... (строка)
  final String? birthday; // YYYY-MM-DD (строка для простоты)

  final String? interests;
  final String? lifeDream;
  final String? shortMidWishes;

  const Profile({
    required this.name,
    this.avatarPath,
    this.extraPhotoPath,
    this.phone,
    this.email,
    this.instagram,
    this.discord,
    this.telegram,
    this.otherSocial,
    this.orgName,
    this.orgAddress,
    this.orgClassOrRole,
    this.orgContactAddress,
    this.orgContactPhone,
    this.orgContactEmail,
    this.bestFriends,
    this.relation,
    this.birthday,
    this.interests,
    this.lifeDream,
    this.shortMidWishes,
  });

  Profile copyWith({
    String? name,
    String? avatarPath,
    String? extraPhotoPath,
    String? phone,
    String? email,
    String? instagram,
    String? discord,
    String? telegram,
    String? otherSocial,
    String? orgName,
    String? orgAddress,
    String? orgClassOrRole,
    String? orgContactAddress,
    String? orgContactPhone,
    String? orgContactEmail,
    String? bestFriends,
    String? relation,
    String? birthday,
    String? interests,
    String? lifeDream,
    String? shortMidWishes,
  }) {
    return Profile(
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      extraPhotoPath: extraPhotoPath ?? this.extraPhotoPath,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      instagram: instagram ?? this.instagram,
      discord: discord ?? this.discord,
      telegram: telegram ?? this.telegram,
      otherSocial: otherSocial ?? this.otherSocial,
      orgName: orgName ?? this.orgName,
      orgAddress: orgAddress ?? this.orgAddress,
      orgClassOrRole: orgClassOrRole ?? this.orgClassOrRole,
      orgContactAddress: orgContactAddress ?? this.orgContactAddress,
      orgContactPhone: orgContactPhone ?? this.orgContactPhone,
      orgContactEmail: orgContactEmail ?? this.orgContactEmail,
      bestFriends: bestFriends ?? this.bestFriends,
      relation: relation ?? this.relation,
      birthday: birthday ?? this.birthday,
      interests: interests ?? this.interests,
      lifeDream: lifeDream ?? this.lifeDream,
      shortMidWishes: shortMidWishes ?? this.shortMidWishes,
    );
  }

  static Profile empty() => const Profile(name: '');

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatarPath': avatarPath,
        'extraPhotoPath': extraPhotoPath,
        'phone': phone,
        'email': email,
        'instagram': instagram,
        'discord': discord,
        'telegram': telegram,
        'otherSocial': otherSocial,
        'orgName': orgName,
        'orgAddress': orgAddress,
        'orgClassOrRole': orgClassOrRole,
        'orgContactAddress': orgContactAddress,
        'orgContactPhone': orgContactPhone,
        'orgContactEmail': orgContactEmail,
        'bestFriends': bestFriends,
        'relation': relation,
        'birthday': birthday,
        'interests': interests,
        'lifeDream': lifeDream,
        'shortMidWishes': shortMidWishes,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: (j['name'] ?? '') as String,
        avatarPath: j['avatarPath'] as String?,
        extraPhotoPath: j['extraPhotoPath'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        instagram: j['instagram'] as String?,
        discord: j['discord'] as String?,
        telegram: j['telegram'] as String?,
        otherSocial: j['otherSocial'] as String?,
        orgName: j['orgName'] as String?,
        orgAddress: j['orgAddress'] as String?,
        orgClassOrRole: j['orgClassOrRole'] as String?,
        orgContactAddress: j['orgContactAddress'] as String?,
        orgContactPhone: j['orgContactPhone'] as String?,
        orgContactEmail: j['orgContactEmail'] as String?,
        bestFriends: j['bestFriends'] as String?,
        relation: j['relation'] as String?,
        birthday: j['birthday'] as String?,
        interests: j['interests'] as String?,
        lifeDream: j['lifeDream'] as String?,
        shortMidWishes: j['shortMidWishes'] as String?,
      );
}

class ProfileStore {
  static final ProfileStore _instance = ProfileStore._();
  ProfileStore._();
  factory ProfileStore() => _instance;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'profile.json'));
  }

  Future<Profile> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return Profile.empty();
      final txt = await f.readAsString();
      final j = jsonDecode(txt) as Map<String, dynamic>;
      return Profile.fromJson(j);
    } catch (_) {
      return Profile.empty();
    }
  }

  Future<void> save(Profile p) async {
    final f = await _file();
    await f.writeAsString(jsonEncode(p.toJson()));
  }
}
