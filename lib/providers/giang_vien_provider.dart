import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/giang_vien_model.dart';
import '../services/api_service.dart';

class GiangVienProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<GiangVien> _giangViens = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<GiangVien> get giangViens => _giangViens;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<GiangVien> get filteredGiangViens {
    if (_searchQuery.isEmpty) return _giangViens;
    final query = _searchQuery.toLowerCase();
    return _giangViens.where((gv) {
      return gv.idgv.toLowerCase().contains(query) ||
          gv.fullname.toLowerCase().contains(query);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Fetch all GiangVien documents from Node.js API
  Future<void> fetchGiangViens() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _giangViens = await _apiService.getAllGiangVien();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if IDGV already exists (client-side validation)
  bool isIdgvExists(String idgv, {String? excludeOriginalIdgv}) {
    return _giangViens.any(
      (gv) =>
          gv.idgv.trim().toLowerCase() == idgv.trim().toLowerCase() &&
          (excludeOriginalIdgv == null ||
              gv.idgv.trim().toLowerCase() !=
                  excludeOriginalIdgv.trim().toLowerCase()),
    );
  }

  /// Create a new GiangVien with optional image file upload to Cloudinary
  Future<bool> addGiangVien(
    GiangVien gv, {
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.insertGiangVien(
        gv: gv,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
      );
      await fetchGiangViens();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update GiangVien with optional new image file
  Future<bool> updateGiangVien(
    GiangVien updatedGv, {
    Uint8List? imageBytes,
    String? imageFileName,
    String? originalIdgv,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.updateGiangVien(
        updatedGv: updatedGv,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
        originalIdgv: originalIdgv,
      );
      await fetchGiangViens();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete GiangVien
  Future<bool> deleteGiangVien(GiangVien gv) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteGiangVien(gv);
      _giangViens.removeWhere(
        (item) => (gv.id != null && item.id == gv.id) || item.idgv == gv.idgv,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
