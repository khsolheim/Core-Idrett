import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
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

  /// Authenticate request via Bearer token and return the user, or null.
  Future<dynamic> _authenticateRequest(Request request) async {
    final token = getBearerToken(request);
    if (token == null) return null;
    return await _authService.getUserFromToken(token);
  }

  Future<Response> _register(Request request) async {
    try {
      final data = await parseBody(request);

      final email = safeStringNullable(data, 'email');
      final password = safeStringNullable(data, 'password');
      final name = safeStringNullable(data, 'name');

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
      final data = await parseBody(request);

      final email = safeStringNullable(data, 'email');
      final password = safeStringNullable(data, 'password');

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
      final data = await parseBody(request);

      final email = safeStringNullable(data, 'email');
      final password = safeStringNullable(data, 'password');
      final name = safeStringNullable(data, 'name');

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
      final user = await _authenticateRequest(request);
      if (user == null) return resp.unauthorized();

      return resp.ok(user.toJson());
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _updateProfile(Request request) async {
    try {
      final user = await _authenticateRequest(request);
      if (user == null) return resp.unauthorized('Ugyldig token');

      final data = await parseBody(request);

      final name = safeStringNullable(data, 'name');
      final avatarUrl = safeStringNullable(data, 'avatar_url');

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
      final user = await _authenticateRequest(request);
      if (user == null) return resp.unauthorized('Ugyldig token');

      final data = await parseBody(request);

      final currentPassword = safeStringNullable(data, 'current_password');
      final newPassword = safeStringNullable(data, 'new_password');

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
      final user = await _authenticateRequest(request);
      if (user == null) return resp.unauthorized();

      await _authService.deleteAccount(user.id);

      return resp.ok({'message': 'Konto slettet'});
    } catch (e) {
      return resp.serverError();
    }
  }
}
