import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import 'helpers/response_helpers.dart' as resp;

class AuthHandler {
  final AuthService _authService;

  AuthHandler(this._authService);

  Router get router {
    final router = Router();

    router.post('/register', _register);
    router.post('/login', _login);
    router.post('/invite/<code>', _registerWithInvite);
    router.get('/me', _getCurrentUser);
    router.patch('/profile', _updateProfile);
    router.post('/change-password', _changePassword);
    router.delete('/account', _deleteAccount);

    return router;
  }

  Future<Response> _register(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final email = data['email'] as String?;
      final password = data['password'] as String?;
      final name = data['name'] as String?;

      if (email == null || password == null || name == null) {
        return resp.badRequest('Mangler påkrevde felt');
      }

      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
      );

      return resp.ok({
        'token': result.token,
        'user': result.user.toJson(),
      });
    } on AuthException catch (e) {
      return resp.badRequest(e.message);
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _login(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final email = data['email'] as String?;
      final password = data['password'] as String?;

      if (email == null || password == null) {
        return resp.badRequest('Mangler e-post eller passord');
      }

      final result = await _authService.login(
        email: email,
        password: password,
      );

      return resp.ok({
        'token': result.token,
        'user': result.user.toJson(),
      });
    } on AuthException catch (e) {
      return resp.unauthorized(e.message);
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _registerWithInvite(Request request, String code) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final email = data['email'] as String?;
      final password = data['password'] as String?;
      final name = data['name'] as String?;

      if (email == null || password == null || name == null) {
        return resp.badRequest('Mangler påkrevde felt');
      }

      final result = await _authService.registerWithInvite(
        inviteCode: code,
        email: email,
        password: password,
        name: name,
      );

      return resp.ok({
        'token': result.token,
        'user': result.user.toJson(),
      });
    } on AuthException catch (e) {
      return resp.badRequest(e.message);
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _getCurrentUser(Request request) async {
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return resp.unauthorized();
      }

      final token = authHeader.substring(7);
      final user = await _authService.getUserFromToken(token);

      if (user == null) {
        return resp.unauthorized('Ugyldig token');
      }

      return resp.ok(user.toJson());
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _updateProfile(Request request) async {
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return resp.unauthorized();
      }

      final token = authHeader.substring(7);
      final user = await _authService.getUserFromToken(token);

      if (user == null) {
        return resp.unauthorized('Ugyldig token');
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      final avatarUrl = data['avatar_url'] as String?;

      if (name == null && avatarUrl == null) {
        return resp.badRequest('Ingen felt å oppdatere');
      }

      final updatedUser = await _authService.updateProfile(
        userId: user.id,
        name: name,
        avatarUrl: avatarUrl,
      );

      if (updatedUser == null) {
        return resp.notFound('Bruker ikke funnet');
      }

      return resp.ok(updatedUser.toJson());
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _changePassword(Request request) async {
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return resp.unauthorized();
      }

      final token = authHeader.substring(7);
      final user = await _authService.getUserFromToken(token);

      if (user == null) {
        return resp.unauthorized('Ugyldig token');
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final currentPassword = data['current_password'] as String?;
      final newPassword = data['new_password'] as String?;

      if (currentPassword == null || newPassword == null) {
        return resp.badRequest('Mangler pakrevde felt');
      }

      await _authService.changePassword(
        userId: user.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      return resp.ok({'message': 'Passord endret'});
    } on AuthException catch (e) {
      return resp.badRequest(e.message);
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _deleteAccount(Request request) async {
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return resp.unauthorized();
      }

      final token = authHeader.substring(7);
      final user = await _authService.getUserFromToken(token);

      if (user == null) {
        return resp.unauthorized('Ugyldig token');
      }

      await _authService.deleteAccount(user.id);

      return resp.ok({'message': 'Konto slettet'});
    } catch (e) {
      return resp.serverError();
    }
  }

}
