import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/giang_vien_model.dart';

/// API Service communicating with the Node.js Express REST API
/// Fully compatible with both Flutter Web and Flutter Mobile.
class ApiService {
  late final String _rawBaseUrl;

  ApiService() {
    _rawBaseUrl = dotenv.env['API_BASE_URL']?.trim() ?? 'http://localhost:3000/api';
  }

  /// Resolves the actual base URL depending on platform.
  /// On Android Emulator, localhost is reached via 10.0.2.2.
  String get baseUrl {
    String url = _rawBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (url.contains('localhost')) {
        url = url.replaceAll('localhost', '10.0.2.2');
      } else if (url.contains('127.0.0.1')) {
        url = url.replaceAll('127.0.0.1', '10.0.2.2');
      }
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Helper to determine the MediaType from filename
  MediaType _getMediaType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  /// AUTH: Login Admin via Node.js API (POST /api/auth/login)
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username.trim(),
            'password': password.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return true;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Đăng nhập không thành công');
    }
  }

  /// READ: Get all GiangVien documents (GET /api/giangviens)
  Future<List<GiangVien>> getAllGiangVien() async {
    final url = Uri.parse('$baseUrl/giangviens');

    final response =
        await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List list = [];
      if (decoded is Map && decoded['data'] != null) {
        list = decoded['data'];
      } else if (decoded is List) {
        list = decoded;
      }
      return list.map((item) => GiangVien.fromJson(item)).toList();
    } else {
      throw Exception(
        'Lỗi tải danh sách giảng viên (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// CREATE: Add a new GiangVien with MultipartRequest
  /// Sends IDGV, Fullname, SumClass as text fields and image as file (or text URL)
  Future<bool> insertGiangVien({
    required GiangVien gv,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    final url = Uri.parse('$baseUrl/giangviens');
    final request = http.MultipartRequest('POST', url);

    // Text fields
    request.fields['IDGV'] = gv.idgv;
    request.fields['Fullname'] = gv.fullname;
    request.fields['SumClass'] = gv.sumClass.toString();

    // Image file or existing URL
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final fileName = imageFileName ?? 'upload.jpg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
          contentType: _getMediaType(fileName),
        ),
      );
    } else if (gv.image.isNotEmpty) {
      request.fields['Image'] = gv.image;
    }

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      try {
        final errData = jsonDecode(response.body);
        throw Exception(errData['message'] ?? response.body);
      } catch (e) {
        if (e is Exception && !e.toString().contains('FormatException')) rethrow;
        throw Exception(
          'Lỗi thêm mới (${response.statusCode}): ${response.body}',
        );
      }
    }
  }

  /// UPDATE: Update GiangVien with MultipartRequest
  /// Sends optional new image file or preserves existing URL
  Future<bool> updateGiangVien({
    required GiangVien updatedGv,
    Uint8List? imageBytes,
    String? imageFileName,
    String? originalIdgv,
  }) async {
    final targetId = updatedGv.id ?? originalIdgv ?? updatedGv.idgv;
    final url = Uri.parse('$baseUrl/giangviens/$targetId');
    final request = http.MultipartRequest('PUT', url);

    request.fields['IDGV'] = updatedGv.idgv;
    request.fields['Fullname'] = updatedGv.fullname;
    request.fields['SumClass'] = updatedGv.sumClass.toString();

    if (imageBytes != null && imageBytes.isNotEmpty) {
      final fileName = imageFileName ?? 'upload.jpg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
          contentType: _getMediaType(fileName),
        ),
      );
    } else if (updatedGv.image.isNotEmpty) {
      request.fields['Image'] = updatedGv.image;
    }

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return true;
    } else {
      try {
        final errData = jsonDecode(response.body);
        throw Exception(errData['message'] ?? response.body);
      } catch (e) {
        if (e is Exception && !e.toString().contains('FormatException')) rethrow;
        throw Exception(
          'Lỗi cập nhật (${response.statusCode}): ${response.body}',
        );
      }
    }
  }

  /// DELETE: Remove GiangVien by id or IDGV
  Future<bool> deleteGiangVien(GiangVien gv) async {
    final targetId = gv.id ?? gv.idgv;
    final url = Uri.parse('$baseUrl/giangviens/$targetId');

    final response =
        await http.delete(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Lỗi xóa giảng viên (${response.statusCode}): ${response.body}',
      );
    }
  }
}
