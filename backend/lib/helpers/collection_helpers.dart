/// Counts occurrences of a key value across a list of maps.
///
/// For each item in [items], extracts the value of [key] as a String
/// and increments its count.
///
/// Example:
/// ```dart
/// final data = [{'team_id': 'a'}, {'team_id': 'a'}, {'team_id': 'b'}];
/// groupByCount(data, 'team_id'); // {'a': 2, 'b': 1}
/// ```
Map<String, int> groupByCount(List<Map<String, dynamic>> items, String key) {
  final counts = <String, int>{};
  for (final item in items) {
    final id = item[key] as String;
    counts[id] = (counts[id] ?? 0) + 1;
  }
  return counts;
}

/// Groups items by a key value, collecting all items with the same key.
///
/// For each item in [items], extracts the value of [key] as a String
/// and adds the item to the corresponding group.
///
/// Example:
/// ```dart
/// final data = [{'type': 'a', 'v': 1}, {'type': 'a', 'v': 2}, {'type': 'b', 'v': 3}];
/// groupBy(data, 'type'); // {'a': [{...}, {...}], 'b': [{...}]}
/// ```
Map<String, List<Map<String, dynamic>>> groupBy(
  List<Map<String, dynamic>> items, String key) {
  final groups = <String, List<Map<String, dynamic>>>{};
  for (final item in items) {
    final id = item[key] as String;
    groups.putIfAbsent(id, () => []).add(item);
  }
  return groups;
}
