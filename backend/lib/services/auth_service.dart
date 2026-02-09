import 'dart:io';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/user.dart';
import '../helpers/parsing_helpers.dart';

class AuthService {
  final Database _db;
  final _uuid = const Uuid();
  late final String _jwtSecret;

  AuthService(this._db) {
    final secret = Platform.environment['JWT_SECRET'];
    if (secret == null || secret.isEmpty) {
      throw StateError('JWT_SECRET environment variable is required');
    }
    _jwtSecret = secret;
  }

  Future<({User user, String token})> register({
    required String email,
    required String password,
    required String name,
  }) async {
    // Check if user exists
    final existingUser = await _db.client.select(
      'users',
      filters: {'email': 'eq.$email'},
    );

    if (existingUser.isNotEmpty) {
      throw AuthException('En bruker med denne e-postadressen finnes allerede');
    }

    final id = _uuid.v4();
    final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

    final result = await _db.client.insert('users', {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'name': name,
    });

    final row = result.first;
    final user = User(
      id: safeString(row, 'id'),
      email: safeString(row, 'email'),
      name: safeString(row, 'name'),
      avatarUrl: safeStringNullable(row, 'avatar_url'),
      createdAt: requireDateTime(row, 'created_at'),
    );

    final token = _generateToken(user);
    return (user: user, token: token);
  }

  Future<({User user, String token})> login({
    required String email,
    required String password,
  }) async {
    final result = await _db.client.select(
      'users',
      select: '*',
      filters: {'email': 'eq.$email'},
    );

    if (result.isEmpty) {
      throw AuthException('Ugyldig e-post eller passord');
    }

    final row = result.first;
    final passwordHash = safeString(row, 'password_hash');

    if (!BCrypt.checkpw(password, passwordHash)) {
      throw AuthException('Ugyldig e-post eller passord');
    }

    final user = User(
      id: safeString(row, 'id'),
      email: safeString(row, 'email'),
      name: safeString(row, 'name'),
      avatarUrl: safeStringNullable(row, 'avatar_url'),
      createdAt: requireDateTime(row, 'created_at'),
    );

    final token = _generateToken(user);
    return (user: user, token: token);
  }

  Future<({User user, String token})> registerWithInvite({
    required String inviteCode,
    required String email,
    required String password,
    required String name,
  }) async {
    // Verify invite code exists and get team
    final teamResult = await _db.client.select(
      'teams',
      select: 'id',
      filters: {'invite_code': 'eq.$inviteCode'},
    );

    if (teamResult.isEmpty) {
      throw AuthException('Ugyldig invitasjonskode');
    }

    final teamId = safeString(teamResult.first, 'id');

    // Register user
    final result = await register(email: email, password: password, name: name);

    // Add user to team as player
    await _db.client.insert('team_members', {
      'id': _uuid.v4(),
      'user_id': result.user.id,
      'team_id': teamId,
      'role': 'player',
    });

    return result;
  }

  Future<User?> getUserFromToken(String token) async {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      final userId = safeString(jwt.payload, 'sub');

      final result = await _db.client.select(
        'users',
        select: '*',
        filters: {'id': 'eq.$userId'},
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return User(
        id: safeString(row, 'id'),
        email: safeString(row, 'email'),
        name: safeString(row, 'name'),
        avatarUrl: safeStringNullable(row, 'avatar_url'),
        createdAt: requireDateTime(row, 'created_at'),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    // Get user and verify current password
    final result = await _db.client.select(
      'users',
      select: 'password_hash',
      filters: {'id': 'eq.$userId'},
    );

    if (result.isEmpty) {
      throw AuthException('Bruker ikke funnet');
    }

    final passwordHash = safeString(result.first, 'password_hash');

    if (!BCrypt.checkpw(currentPassword, passwordHash)) {
      throw AuthException('Feil navaerende passord');
    }

    // Hash new password and update
    final newPasswordHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());

    await _db.client.update(
      'users',
      {'password_hash': newPasswordHash},
      filters: {'id': 'eq.$userId'},
    );
  }

  Future<User?> updateProfile({
    required String userId,
    String? name,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isEmpty) return null;

    final result = await _db.client.update(
      'users',
      updates,
      filters: {'id': 'eq.$userId'},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return User(
      id: safeString(row, 'id'),
      email: safeString(row, 'email'),
      name: safeString(row, 'name'),
      avatarUrl: safeStringNullable(row, 'avatar_url'),
      createdAt: requireDateTime(row, 'created_at'),
    );
  }

  Future<void> deleteAccount(String userId) async {
    // Delete in order: related data first, then user
    // team_members
    await _db.client.delete(
      'team_members',
      filters: {'user_id': 'eq.$userId'},
    );

    // fines (where user is the one who received the fine)
    await _db.client.delete(
      'fines',
      filters: {'user_id': 'eq.$userId'},
    );

    // activities (where user created them)
    await _db.client.delete(
      'activities',
      filters: {'created_by': 'eq.$userId'},
    );

    // messages
    await _db.client.delete(
      'messages',
      filters: {'user_id': 'eq.$userId'},
    );

    // Finally delete the user
    await _db.client.delete(
      'users',
      filters: {'id': 'eq.$userId'},
    );
  }

  String _generateToken(User user) {
    final jwt = JWT(
      {
        'sub': user.id,
        'email': user.email,
        'name': user.name,
      },
      issuer: 'core-idrett',
    );

    return jwt.sign(SecretKey(_jwtSecret), expiresIn: const Duration(days: 30));
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
