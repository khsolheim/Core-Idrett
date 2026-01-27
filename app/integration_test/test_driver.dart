import 'package:integration_test/integration_test_driver.dart';

/// Driver for running integration tests with flutter drive.
///
/// Usage:
///   flutter drive \
///     --driver=integration_test/test_driver.dart \
///     --target=integration_test/app_test.dart
///
/// For web testing:
///   flutter drive \
///     --driver=integration_test/test_driver.dart \
///     --target=integration_test/app_test.dart \
///     -d chrome
Future<void> main() => integrationDriver();
