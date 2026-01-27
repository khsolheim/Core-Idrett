import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/user.dart';
import '../../../core/config.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String? inviteCode,
  }) async {
    final endpoint = inviteCode != null
        ? '${AppConfig.authInvite}/$inviteCode'
        : AppConfig.authRegister;

    final response = await _apiClient.post(endpoint, data: {
      'email': email,
      'password': password,
      'name': name,
    });

    final token = response.data['token'] as String;
    final user = User.fromJson(response.data['user'] as Map<String, dynamic>);

    await _apiClient.saveToken(token);

    return AuthResult(token: token, user: user);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(AppConfig.authLogin, data: {
      'email': email,
      'password': password,
    });

    final token = response.data['token'] as String;
    final user = User.fromJson(response.data['user'] as Map<String, dynamic>);

    await _apiClient.saveToken(token);

    return AuthResult(token: token, user: user);
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
  }

  Future<User?> getCurrentUser() async {
    try {
      await _apiClient.loadToken();
      final response = await _apiClient.get('/auth/me');
      return User.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<User> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    final response = await _apiClient.patch('/auth/profile', data: {
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.post('/auth/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<void> deleteAccount() async {
    await _apiClient.delete('/auth/account');
    await _apiClient.clearToken();
  }
}

class AuthResult {
  final String token;
  final User user;

  AuthResult({required this.token, required this.user});
}
