import 'request_helpers.dart';

/// Require a non-empty String field from the body.
String requireString(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value == null || value is! String || value.isEmpty) {
    throw BadRequestException('Mangler påkrevd felt ($key)');
  }
  return value;
}

/// Require a positive integer field from the body.
int requirePositiveInt(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value == null || value is! int || value < 1) {
    throw BadRequestException('$key må være et positivt heltall');
  }
  return value;
}

/// Require an enum field from the body using a fromString converter.
/// [fromString] should throw if the value is invalid.
T requireEnum<T>(
  Map<String, dynamic> body,
  String key,
  T Function(String) fromString,
) {
  final value = body[key];
  if (value == null || value is! String) {
    throw BadRequestException('Mangler påkrevd felt ($key)');
  }
  try {
    return fromString(value);
  } catch (_) {
    throw BadRequestException('Ugyldig verdi for $key: $value');
  }
}

/// Get an optional enum field from the body.
T? optionalEnum<T>(
  Map<String, dynamic> body,
  String key,
  T Function(String) fromString,
) {
  final value = body[key];
  if (value == null) return null;
  if (value is! String) {
    throw BadRequestException('Ugyldig type for $key');
  }
  try {
    return fromString(value);
  } catch (_) {
    throw BadRequestException('Ugyldig verdi for $key: $value');
  }
}

/// Get an optional double field with optional min/max bounds.
double? optionalDouble(
  Map<String, dynamic> body,
  String key, {
  double? min,
  double? max,
}) {
  final value = body[key];
  if (value == null) return null;
  if (value is! num) {
    throw BadRequestException('$key må være et tall');
  }
  final d = value.toDouble();
  if (min != null && d < min) {
    throw BadRequestException('$key må være minst $min');
  }
  if (max != null && d > max) {
    throw BadRequestException('$key kan ikke være mer enn $max');
  }
  return d;
}

/// Get an optional integer with optional min/max bounds.
int? optionalInt(
  Map<String, dynamic> body,
  String key, {
  int? min,
  int? max,
}) {
  final value = body[key];
  if (value == null) return null;
  if (value is! int) {
    throw BadRequestException('$key må være et heltall');
  }
  if (min != null && value < min) {
    throw BadRequestException('$key må være minst $min');
  }
  if (max != null && value > max) {
    throw BadRequestException('$key kan ikke være mer enn $max');
  }
  return value;
}
