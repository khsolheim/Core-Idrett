/// Common test helpers and utilities for backend tests
/// Provides shared test setup, assertions, and utility functions

import 'package:test/test.dart';

/// Create a test-friendly timestamp (rounded to seconds to avoid millisecond issues)
DateTime testTimestamp({DateTime? base}) {
  final time = base ?? DateTime.now();
  return DateTime(
    time.year,
    time.month,
    time.day,
    time.hour,
    time.minute,
    time.second,
  );
}

/// Parse a date string to DateTime (handles both ISO8601 and date-only)
DateTime parseTestDate(String dateString) {
  if (dateString.contains('T')) {
    return DateTime.parse(dateString);
  } else {
    // Date-only format
    final parts = dateString.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}

/// Format DateTime to date-only string (YYYY-MM-DD)
String formatDateOnly(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// Generate a unique test ID with optional prefix
String testId([String prefix = 'test']) {
  return '$prefix-${DateTime.now().millisecondsSinceEpoch}';
}

/// Generate multiple unique test IDs
List<String> testIds(int count, [String prefix = 'test']) {
  return List.generate(count, (i) => '$prefix-${DateTime.now().millisecondsSinceEpoch}-$i');
}

/// Wait for a short duration (useful for timing-dependent tests)
Future<void> waitShort() => Future.delayed(const Duration(milliseconds: 10));

/// Wait for a medium duration
Future<void> waitMedium() => Future.delayed(const Duration(milliseconds: 100));

/// Wait for a long duration
Future<void> waitLong() => Future.delayed(const Duration(milliseconds: 500));

/// Assert that two maps are equal, ignoring specified keys
void assertMapsEqual(
  Map<String, dynamic> actual,
  Map<String, dynamic> expected, {
  List<String> ignoreKeys = const [],
}) {
  final actualFiltered = Map<String, dynamic>.from(actual)
    ..removeWhere((key, _) => ignoreKeys.contains(key));
  final expectedFiltered = Map<String, dynamic>.from(expected)
    ..removeWhere((key, _) => ignoreKeys.contains(key));

  expect(actualFiltered, equals(expectedFiltered));
}

/// Assert that a list contains exactly the expected items (order-independent)
void assertListContainsExactly<T>(List<T> actual, List<T> expected) {
  expect(actual.length, equals(expected.length),
      reason: 'List lengths differ: actual=${actual.length}, expected=${expected.length}');

  for (final item in expected) {
    expect(actual, contains(item),
        reason: 'Expected item not found in actual list: $item');
  }
}

/// Assert that a map contains all expected keys
void assertMapHasKeys(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    expect(map.containsKey(key), isTrue,
        reason: 'Map missing expected key: $key');
  }
}

/// Assert that a map does not contain any forbidden keys
void assertMapDoesNotHaveKeys(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    expect(map.containsKey(key), isFalse,
        reason: 'Map contains forbidden key: $key');
  }
}

/// Assert that a value is within a numeric range
void assertInRange(num value, num min, num max) {
  expect(value, greaterThanOrEqualTo(min),
      reason: 'Value $value is less than minimum $min');
  expect(value, lessThanOrEqualTo(max),
      reason: 'Value $value is greater than maximum $max');
}

/// Assert that a percentage value is valid (0-100)
void assertValidPercentage(num percentage) {
  assertInRange(percentage, 0, 100);
}

/// Assert that two doubles are approximately equal
void assertApproximatelyEqual(
  double actual,
  double expected, {
  double epsilon = 0.001,
}) {
  final diff = (actual - expected).abs();
  expect(diff, lessThan(epsilon),
      reason: 'Values differ by more than $epsilon: actual=$actual, expected=$expected');
}

/// Generate Norwegian phone number for testing
String testPhoneNumber([int seed = 0]) {
  final base = 40000000 + (seed % 10000000);
  return '+47$base';
}

/// Generate Norwegian postal code for testing
String testPostalCode([int seed = 0]) {
  final codes = ['0001', '5003', '7030', '9170', '0150', '5063', '7040', '9294'];
  return codes[seed % codes.length];
}
