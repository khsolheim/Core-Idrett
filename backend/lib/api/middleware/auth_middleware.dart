import 'package:shelf/shelf.dart';
import '../../services/auth_service.dart';

/// Middleware that extracts and validates Bearer tokens.
/// Sets 'userId' on request context for downstream handlers.
Middleware requireAuth(AuthService authService) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401,
            body: '{"error":"Ikke autentisert"}',
            headers: {'Content-Type': 'application/json'});
      }

      final token = authHeader.substring(7);
      final user = await authService.getUserFromToken(token);

      if (user == null) {
        return Response(401,
            body: '{"error":"Ugyldig token"}',
            headers: {'Content-Type': 'application/json'});
      }

      final updatedRequest = request.change(context: {'userId': user.id});
      return innerHandler(updatedRequest);
    };
  };
}

/// Middleware that optionally extracts a Bearer token.
/// Sets 'userId' on request context if valid token is present,
/// but allows the request through regardless.
Middleware optionalAuth(AuthService authService) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7);
        final user = await authService.getUserFromToken(token);
        if (user != null) {
          final updatedRequest = request.change(context: {'userId': user.id});
          return innerHandler(updatedRequest);
        }
      }
      return innerHandler(request);
    };
  };
}
