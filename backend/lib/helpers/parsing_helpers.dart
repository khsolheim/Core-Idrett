/// Safe type extraction helpers for JSON deserialization
///
/// These helpers provide type-safe extraction from Map<String, dynamic>
/// with clear error messages when values are missing or have wrong types.
/// Used in model fromJson factories and service layer database access.

/// Extract a required String field from a Map
String safeString(Map<String, dynamic> map, String key,
    {String? defaultValue}) {
  final value = map[key];
  if (value == null) {
    if (defaultValue != null) return defaultValue;
    throw FormatException('Missing required field: $key');
  }
  if (value is! String) {
    throw FormatException('Field $key must be String, got ${value.runtimeType}');
  }
  return value;
}

/// Extract a nullable String field from a Map
String? safeStringNullable(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Field $key must be String, got ${value.runtimeType}');
  }
  return value;
}

/// Extract a required int field from a Map with default value
int safeInt(Map<String, dynamic> map, String key, {int defaultValue = 0}) {
  final value = map[key];
  if (value == null) return defaultValue;
  if (value is! int) {
    throw FormatException('Field $key must be int, got ${value.runtimeType}');
  }
  return value;
}

/// Extract a nullable int field from a Map
int? safeIntNullable(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! int) {
    throw FormatException('Field $key must be int, got ${value.runtimeType}');
  }
  return value;
}

/// Extract a required double field from a Map with default value
/// Accepts both int and double input (converts int to double)
double safeDouble(Map<String, dynamic> map, String key,
    {double defaultValue = 0.0}) {
  final value = map[key];
  if (value == null) return defaultValue;
  if (value is! num) {
    throw FormatException('Field $key must be num, got ${value.runtimeType}');
  }
  return value.toDouble();
}

/// Extract a nullable double field from a Map
/// Accepts both int and double input (converts int to double)
double? safeDoubleNullable(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! num) {
    throw FormatException('Field $key must be num, got ${value.runtimeType}');
  }
  return value.toDouble();
}

/// Extract a required bool field from a Map with default value
bool safeBool(Map<String, dynamic> map, String key,
    {bool defaultValue = false}) {
  final value = map[key];
  if (value == null) return defaultValue;
  if (value is! bool) {
    throw FormatException('Field $key must be bool, got ${value.runtimeType}');
  }
  return value;
}

/// Extract a nullable bool field from a Map
bool? safeBoolNullable(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! bool) {
    throw FormatException('Field $key must be bool, got ${value.runtimeType}');
  }
  return value;
}

/// Extract a required num field from a Map with default value
num safeNum(Map<String, dynamic> map, String key, {num defaultValue = 0}) {
  final value = map[key];
  if (value == null) return defaultValue;
  if (value is! num) {
    throw FormatException('Field $key must be num, got ${value.runtimeType}');
  }
  return value;
}

/// Extract a nullable num field from a Map
num? safeNumNullable(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! num) {
    throw FormatException('Field $key must be num, got ${value.runtimeType}');
  }
  return value;
}

/// Extract a required DateTime field from a Map
/// Handles both DateTime objects (from Supabase) and String values (ISO 8601)
DateTime requireDateTime(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    throw FormatException('Missing required field: $key');
  }
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid DateTime format for $key: $value');
    }
    return parsed;
  }
  throw FormatException(
      'Field $key must be DateTime or String, got ${value.runtimeType}');
}

/// Extract a nullable DateTime field from a Map
/// Handles both DateTime objects (from Supabase) and String values (ISO 8601)
DateTime? safeDateTimeNullable(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid DateTime format for $key: $value');
    }
    return parsed;
  }
  throw FormatException(
      'Field $key must be DateTime or String, got ${value.runtimeType}');
}

/// Extract a required Map field from a Map
Map<String, dynamic> safeMap(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    throw FormatException('Missing required field: $key');
  }
  if (value is! Map) {
    throw FormatException('Field $key must be Map, got ${value.runtimeType}');
  }
  return Map<String, dynamic>.from(value);
}

/// Extract a nullable Map field from a Map
Map<String, dynamic>? safeMapNullable(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! Map) {
    throw FormatException('Field $key must be Map, got ${value.runtimeType}');
  }
  return Map<String, dynamic>.from(value);
}

/// Extract a required List field from a Map
List<dynamic> safeList(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    throw FormatException('Missing required field: $key');
  }
  if (value is! List) {
    throw FormatException('Field $key must be List, got ${value.runtimeType}');
  }
  return value;
}

/// Extract a nullable List field from a Map
List<dynamic>? safeListNullable(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! List) {
    throw FormatException('Field $key must be List, got ${value.runtimeType}');
  }
  return value;
}
