import 'dart:io';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/user.dart';

class AuthService {
  final Database _db;
  final _uuid = const Uuid();
  late final String _jwtSecret;

  AuthService(this._db) {
    _jwtSecret = Platform.environment['JWT_SECRET'] ?? 'dev-secret-change-in-production';
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
      id: row['id'] as String,
      email: row['email'] as String,
      name: row['name'] as String,
      avatarUrl: row['avatar_url'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
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
    final passwordHash = row['password_hash'] as String;

    if (!BCrypt.checkpw(password, passwordHash)) {
      throw AuthException('Ugyldig e-post eller passord');
    }

    final user = User(
      id: row['id'] as String,
      email: row['email'] as String,
      name: row['name'] as String,
      avatarUrl: row['avatar_url'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
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

    final teamId = teamResult.first['id'] as String;

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
      final userId = jwt.payload['sub'] as String;

      final result = await _db.client.select(
        'users',
        select: '*',
        filters: {'id': 'eq.$userId'},
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return User(
        id: row['id'] as String,
        email: row['email'] as String,
        name: row['name'] as String,
        avatarUrl: row['avatar_url'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    } catch (e) {
      return null;
    }
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
      select: '*',
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return User(
      id: row['id'] as String,
      email: row['email'] as String,
      name: row['name'] as String,
      avatarUrl: row['avatar_url'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
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
