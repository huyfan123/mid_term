import 'api_service.dart';

/// Authentication service for the Admin module
class AuthService {
  final ApiService _apiService = ApiService();

  Future<bool> login(String username, String password) async {
    try {
      return await _apiService.login(username, password);
    } catch (_) {
      // Fallback to local admin check if server is unreachable
      final trimmedUser = username.trim().toLowerCase();
      final trimmedPass = password.trim();
      if (trimmedUser == 'admin' && trimmedPass == 'admin') {
        return true;
      }
      rethrow;
    }
  }
}
