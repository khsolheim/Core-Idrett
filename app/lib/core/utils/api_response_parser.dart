// Utility functions for parsing common API response patterns.
//
// Most list endpoints return JSON like `{"key": [...]}`.
// This utility reduces boilerplate in repository classes.

/// Parse a list from a keyed API response.
///
/// Given response data like `{"items": [{...}, {...}]}`, extracts the list
/// under [key] and maps each element using [fromJson].
///
/// Returns an empty list if the key is missing or null.
///
/// Example:
/// ```dart
/// final rules = parseList(response.data, 'rules', FineRule.fromJson);
/// ```
List<T> parseList<T>(
  dynamic data,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  final list = data[key] as List?;
  if (list == null) return [];
  return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
}
