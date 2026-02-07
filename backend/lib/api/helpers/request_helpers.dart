import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Parse the request body as JSON and return it as a Map.
Future<Map<String, dynamic>> parseBody(Request request) async {
  final body = await request.readAsString();
  return jsonDecode(body) as Map<String, dynamic>;
}

/// Get a required field from the body map.
/// Throws a [BadRequestException] if the field is missing or null.
T requiredField<T>(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value == null) {
    throw BadRequestException('Mangler påkrevd felt ($key)');
  }
  if (value is! T) {
    throw BadRequestException('Ugyldig type for felt $key');
  }
  return value;
}

/// Get an optional field from the body map.
/// Returns null if the field is missing or null.
T? optionalField<T>(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value == null) return null;
  if (value is! T) {
    throw BadRequestException('Ugyldig type for felt $key');
  }
  return value;
}

/// Extract the Bearer token from the Authorization header.
/// Returns null if the header is missing or doesn't start with "Bearer ".
String? getBearerToken(Request request) {
  final authHeader = request.headers['authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  return authHeader.substring(7);
}

/// Exception thrown when request validation fails.
class BadRequestException implements Exception {
  final String message;
  BadRequestException(this.message);

  @override
  String toString() => message;
}
