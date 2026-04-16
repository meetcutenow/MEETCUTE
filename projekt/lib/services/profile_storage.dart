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

  // Kopira sliku iz privremene putanje u trajni direktorij aplikacije
  // Ako putanja već pokazuje na trajni direktorij ili je asset, vraća je kakva jest
  static Future<String> _persistImage(String path) async {
    // Asset slike — ne kopiramo
    if (path.startsWith('assets/')) return path;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/profile_photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      // Ako je slika već u trajnom direktoriju, ne treba je kopirati
      if (path.startsWith(photosDir.path)) return path;

      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}_${path.hashCode.abs()}.jpg';
      final destPath = '${photosDir.path}/$fileName';

      final sourceFile = File(path);
      if (!await sourceFile.exists()) return path;

      await sourceFile.copy(destPath);
      return destPath;
    } catch (e) {
      // Ako kopiranje ne uspije, vrati originalnu putanju
      return path;
    }
  }

  static Future<void> saveProfile(ProfileSetupData data) async {
    // Kopiraj sve slike u trajni direktorij PRIJE spremanja putanja
    final persistedPaths = <String>[];
    for (final path in data.photoPaths) {
      final persisted = await _persistImage(path);
      persistedPaths.add(persisted);
    }

    // Ažuriraj putanje u data objektu
    data.photoPaths
      ..clear()
      ..addAll(persistedPaths);

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
    };
    await prefs.setString(_key, jsonEncode(map));
  }

  static Future<ProfileSetupData?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_key);
    if (str == null) return null;

    try {
      final map = jsonDecode(str) as Map<String, dynamic>;

      // Filtriraj slike — zadrži samo one koje postoje ili su asseti
      final rawPaths = List<String>.from(map['photoPaths'] ?? []);
      final validPaths = <String>[];
      for (final path in rawPaths) {
        if (path.startsWith('assets/')) {
          validPaths.add(path);
        } else if (await File(path).exists()) {
          validPaths.add(path);
        }
        // Ako slika ne postoji, preskočimo je
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