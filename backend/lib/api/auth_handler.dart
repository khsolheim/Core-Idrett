import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';

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
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevde felt'}));
      }

      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
      );

      return Response.ok(jsonEncode({
        'token': result.token,
        'user': result.user.toJson(),
      }));
    } on AuthException catch (e) {
      return Response(400, body: jsonEncode({'error': e.message}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _login(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final email = data['email'] as String?;
      final password = data['password'] as String?;

      if (email == null || password == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler e-post eller passord'}));
      }

      final result = await _authService.login(
        email: email,
        password: password,
      );

      return Response.ok(jsonEncode({
        'token': result.token,
        'user': result.user.toJson(),
      }));
    } on AuthException catch (e) {
      return Response(401, body: jsonEncode({'error': e.message}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
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
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevde felt'}));
      }

      final result = await _authService.registerWithInvite(
        inviteCode: code,
        email: email,
        password: password,
        name: name,
      );

      return Response.ok(jsonEncode({
        'token': result.token,
        'user': result.user.toJson(),
      }));
    } on AuthException catch (e) {
      return Response(400, body: jsonEncode({'error': e.message}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _getCurrentUser(Request request) async {
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final token = authHeader.substring(7);
      final user = await _authService.getUserFromToken(token);

      if (user == null) {
        return Response(401, body: jsonEncode({'error': 'Ugyldig token'}));
      }

      return Response.ok(jsonEncode(user.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _updateProfile(Request request) async {
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final token = authHeader.substring(7);
      final user = await _authService.getUserFromToken(token);

      if (user == null) {
        return Response(401, body: jsonEncode({'error': 'Ugyldig token'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      final avatarUrl = data['avatar_url'] as String?;

      if (name == null && avatarUrl == null) {
        return Response(400, body: jsonEncode({'error': 'Ingen felt å oppdatere'}));
      }

      final updatedUser = await _authService.updateProfile(
        userId: user.id,
        name: name,
        avatarUrl: avatarUrl,
      );

      if (updatedUser == null) {
        return Response(404, body: jsonEncode({'error': 'Bruker ikke funnet'}));
      }

      return Response.ok(jsonEncode(updatedUser.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _changePassword(Request request) async {
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final token = authHeader.substring(7);
      final user = await _authService.getUserFromToken(token);

      if (user == null) {
        return Response(401, body: jsonEncode({'error': 'Ugyldig token'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final currentPassword = data['current_password'] as String?;
      final newPassword = data['new_password'] as String?;

      if (currentPassword == null || newPassword == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler pakrevde felt'}));
      }

      await _authService.changePassword(
        userId: user.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      return Response.ok(jsonEncode({'message': 'Passord endret'}));
    } on AuthException catch (e) {
      return Response(400, body: jsonEncode({'error': e.message}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _deleteAccount(Request request) async {
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final token = authHeader.substring(7);
      final user = await _authService.getUserFromToken(token);

      if (user == null) {
        return Response(401, body: jsonEncode({'error': 'Ugyldig token'}));
      }

      await _authService.deleteAccount(user.id);

      return Response.ok(jsonEncode({'message': 'Konto slettet'}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }
}
