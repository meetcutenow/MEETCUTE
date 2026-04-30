import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/profile_setup_screen.dart';

class ProfileStorage {
  static const _key = 'profile_data';
  static const _usernameKey = 'username';
  static const _displayNameKey = 'display_name';
  static const _registeredKey = 'is_registered';

  static Future<String> _persistImage(String path) async {
    if (path.startsWith('assets/')) return path;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/profile_photos');
      if (!await photosDir.exists()) await photosDir.create(recursive: true);
      if (path.startsWith(photosDir.path)) return path;
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}_${path.hashCode.abs()}.jpg';
      final destPath = '${photosDir.path}/$fileName';
      final sourceFile = File(path);
      if (!await sourceFile.exists()) return path;
      await sourceFile.copy(destPath);
      return destPath;
    } catch (e) {
      return path;
    }
  }

  static Future<void> saveProfile(ProfileSetupData data) async {
    final persistedPaths = <String>[];
    for (final path in data.photoPaths) {
      persistedPaths.add(await _persistImage(path));
    }
    data.photoPaths..clear()..addAll(persistedPaths);

    final prefs = await SharedPreferences.getInstance();
    final map = {
      'photoPaths': persistedPaths,
      'birthDay': data.birthDay,
      'birthMonth': data.birthMonth,
      'birthYear': data.birthYear,
      'height': data.height,
      'hairColor': data.hairColor,
      'eyeColor': data.eyeColor,
      'piercing': data.piercing,
      'tattoo': data.tattoo,
      'gender': data.gender,
      'interests': data.interests,
      'iceBreaker': data.iceBreaker,
      'seekingGender': data.seekingGender,
      'prefAgeFrom': data.prefAgeFrom,
      'prefAgeTo': data.prefAgeTo,
    };
    await prefs.setString(_key, jsonEncode(map));
  }

  static Future<ProfileSetupData?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_key);
    if (str == null) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      final rawPaths = List<String>.from(map['photoPaths'] ?? []);
      final validPaths = <String>[];
      for (final path in rawPaths) {
        if (path.startsWith('assets/') || await File(path).exists()) {
          validPaths.add(path);
        }
      }
      return ProfileSetupData(
        photoPaths: validPaths,
        birthDay: map['birthDay'],
        birthMonth: map['birthMonth'],
        birthYear: map['birthYear'],
        height: map['height'],
        hairColor: map['hairColor'],
        eyeColor: map['eyeColor'],
        piercing: map['piercing'],
        tattoo: map['tattoo'],
        gender: map['gender'],
        interests: List<String>.from(map['interests'] ?? []),
        iceBreaker: map['iceBreaker'] ?? '',
        seekingGender: map['seekingGender'],
        prefAgeFrom: map['prefAgeFrom'],
        prefAgeTo: map['prefAgeTo'],
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveRegistration(String username, String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_displayNameKey, displayName);
    await prefs.setBool(_registeredKey, true);
  }

  static Future<bool> loadRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_registeredKey) ?? false;
  }

  static Future<String> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey) ?? '';
  }

  static Future<String> loadDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_displayNameKey) ?? '';
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}