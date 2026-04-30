import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

class CloudinaryUploadResult {
  final String url;
  final String publicId;
  const CloudinaryUploadResult({required this.url, required this.publicId});
}

class CloudinaryService {
  static const String _backendBase = 'http://localhost:8080/api';

  static Future<CloudinaryUploadResult> uploadImage({
    required String filePath,
    required String token,
    String folder = 'meetcute',
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Datoteka ne postoji: $filePath');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_backendBase/upload?folder=$folder'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      await file.readAsBytes(),
      filename: filePath.split('/').last,
      contentType: MediaType('image', 'jpeg'),
    ));

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Upload nije uspio: ${response.body}');
    }

    final data = jsonDecode(response.body)['data'] as Map<String, dynamic>;
    return CloudinaryUploadResult(
      url: data['url'] as String,
      publicId: data['publicId'] as String,
    );
  }

  static Future<String> uploadProfilePhoto({
    required String filePath,
    required String token,
    bool isPrimary = false,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('Datoteka ne postoji');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_backendBase/users/me/photos?isPrimary=$isPrimary'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      await file.readAsBytes(),
      filename: filePath.split('/').last,
      contentType: MediaType('image', 'jpeg'),
    ));

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Upload profilne nije uspio: ${response.body}');
    }

    final data = jsonDecode(response.body)['data'] as Map<String, dynamic>;
    return data['url'] as String;
  }
}