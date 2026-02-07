import 'dart:convert';

// Utility functions for parsing common API response patterns.

/// Parse a list from a keyed API response.
///
/// Given response data like `{"items": [{...}, {...}]}`, extracts the list
/// under [key] and maps each element using [fromJson].
///
/// Returns an empty list if the key is missing or null.
List<T> parseList<T>(
  dynamic data,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  final list = data[key] as List?;
  if (list == null) return [];
  return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
}

/// Parse a raw JSON object response that may arrive as String or Map.
///
/// Handles Dio responses where data can be pre-parsed (Map) or raw (String).
Map<String, dynamic> parseJsonResponse(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String) return Map<String, dynamic>.from(jsonDecode(data) as Map);
  throw Exception('Unexpected response type: ${data.runtimeType}');
}

/// Parse a raw JSON list response that may arrive as String, List, or null.
///
/// Handles Dio responses where data can be pre-parsed (List) or raw (String).
/// Returns empty list for null data.
List<dynamic> parseListResponse(dynamic data) {
  if (data == null) return [];
  if (data is List) return data;
  if (data is String) {
    final decoded = jsonDecode(data);
    if (decoded == null) return [];
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format: expected List, got ${decoded.runtimeType}');
  }
  throw Exception('Unexpected response type: ${data.runtimeType}');
}
