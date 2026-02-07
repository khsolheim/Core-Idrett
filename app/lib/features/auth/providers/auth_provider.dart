import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user.dart';
import '../data/auth_repository.dart';

final authStateProvider = NotifierProvider<AuthNotifier, AsyncValue<User?>>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<AsyncValue<User?>> {
  late final AuthRepository _repository;

  @override
  AsyncValue<User?> build() {
    _repository = ref.watch(authRepositoryProvider);
    _repository.setOnTokenExpired(_handleTokenExpiration);
    _init();
    return const AsyncValue.loading();
  }

  /// Handle token expiration - clears auth state to trigger redirect to login
  void _handleTokenExpiration() {
    // Token is already cleared by ApiClient, just update state
    state = const AsyncValue.data(null);
  }

  Future<void> _init() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? inviteCode,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.register(
        email: email,
        password: password,
        name: name,
        inviteCode: inviteCode,
      );
      state = AsyncValue.data(result.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.login(
        email: email,
        password: password,
      );
      state = AsyncValue.data(result.user);
    } catch (e) {
      state = const AsyncValue.data(null); // Forblir utlogget
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  Future<User?> updateProfile({String? name, String? avatarUrl}) async {
    try {
      final user = await _repository.updateProfile(
        name: name,
        avatarUrl: avatarUrl,
      );
      state = AsyncValue.data(user);
      return user;
    } catch (e) {
      // Return null to signal failure - caller handles error display
      return null;
    }
  }
}
