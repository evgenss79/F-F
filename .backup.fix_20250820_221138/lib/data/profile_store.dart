import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Profile {
  final String? name;
  final String? avatarPath;

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

  final String? bestFriends;

  final String? relation;   // сын, дочь, мама, ...
  final String? birthday;   // YYYY-MM-DD
  final String? interests;
  final String? lifeDream;
  final String? shortMidWishes;

  final String? extraPhotoPath;

  const Profile({
    this.name,
    this.avatarPath,
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
    this.extraPhotoPath,
  });

  Profile copyWith({
    String? name,
    String? avatarPath,
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
    String? extraPhotoPath,
  }) {
    return Profile(
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
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
      extraPhotoPath: extraPhotoPath ?? this.extraPhotoPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatarPath': avatarPath,
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
        'extraPhotoPath': extraPhotoPath,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: j['name'],
        avatarPath: j['avatarPath'],
        phone: j['phone'],
        email: j['email'],
        instagram: j['instagram'],
        discord: j['discord'],
        telegram: j['telegram'],
        otherSocial: j['otherSocial'],
        orgName: j['orgName'],
        orgAddress: j['orgAddress'],
        orgClassOrRole: j['orgClassOrRole'],
        orgContactAddress: j['orgContactAddress'],
        orgContactPhone: j['orgContactPhone'],
        orgContactEmail: j['orgContactEmail'],
        bestFriends: j['bestFriends'],
        relation: j['relation'],
        birthday: j['birthday'],
        interests: j['interests'],
        lifeDream: j['lifeDream'],
        shortMidWishes: j['shortMidWishes'],
        extraPhotoPath: j['extraPhotoPath'],
      );
}

class ProfileStore {
  static const _key = 'profile_v1';

  Future<Profile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const Profile();
    return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }

  Future<void> save(Profile p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(p.toJson()));
  }
}
