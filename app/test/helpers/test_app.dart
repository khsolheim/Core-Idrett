/// Test app wrapper for widget and integration tests
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:core_idrett/core/theme.dart';
import 'package:core_idrett/core/router.dart';
import 'package:core_idrett/data/models/user.dart';
import 'package:core_idrett/data/models/team.dart';

import 'mock_repositories.dart';
import 'test_data.dart';

/// Initialize date formatting for Norwegian locale
/// Call this in setUpAll for tests that use DateFormat
Future<void> initializeTestLocales() async {
  await initializeDateFormatting('nb_NO', null);
  await initializeDateFormatting('en_US', null);
}

/// Creates a test app wrapper with provider overrides
class TestApp extends StatelessWidget {
  final Widget child;
  final List<Override> overrides;
  final GoRouter? router;

  const TestApp({
    super.key,
    required this.child,
    this.overrides = const [],
    this.router,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
      ),
    );
  }
}

/// Creates a test app with full router for navigation tests
class TestAppWithRouter extends ConsumerWidget {
  final List<Override> overrides;
  final String? initialLocation;

  const TestAppWithRouter({
    super.key,
    this.overrides = const [],
    this.initialLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
    );
  }
}

/// Wraps a widget with ProviderScope for testing
Widget createTestWidget(
  Widget widget, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: widget,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
    ),
  );
}

/// Creates a test widget with routing support
Widget createRoutedTestWidget({
  required List<Override> overrides,
  String initialLocation = '/login',
}) {
  return ProviderScope(
    overrides: overrides,
    child: const TestAppWithRouter(),
  );
}

/// Helper class for setting up common test scenarios
class TestScenario {
  final MockProviders mocks;
  late User testUser;

  TestScenario() : mocks = MockProviders() {
    testUser = TestUserFactory.create(
      id: 'test-user-1',
      email: 'test@example.com',
      name: 'Test User',
    );
  }

  /// Setup for logged-out state
  void setupLoggedOut() {
    mocks.setupUnauthenticated();
  }

  /// Setup for logged-in state
  void setupLoggedIn({User? user}) {
    final u = user ?? testUser;
    mocks.setupAuthenticatedUser(u);
  }

  /// Setup with teams
  void setupWithTeams({
    List<Team>? teams,
    int teamCount = 2,
  }) {
    final teamList = teams ?? List.generate(
      teamCount,
      (i) => TestTeamFactory.create(
        id: 'team-${i + 1}',
        name: 'Team ${i + 1}',
        userIsAdmin: i == 0,
      ),
    );
    mocks.setupTeamsList(teamList);
  }

  /// Setup with team members
  void setupWithTeamMembers(String teamId, {int memberCount = 3}) {
    final members = List.generate(
      memberCount,
      (i) => TestTeamMemberFactory.create(
        id: 'member-${i + 1}',
        userId: 'user-${i + 1}',
        teamId: teamId,
        userName: 'Member ${i + 1}',
        isAdmin: i == 0,
      ),
    );
    mocks.setupTeamMembers(teamId, members);
  }

  /// Setup with activities
  void setupWithActivities(String teamId, {int activityCount = 3}) {
    final instances = List.generate(
      activityCount,
      (i) => TestActivityInstanceFactory.create(
        id: 'instance-${i + 1}',
        teamId: teamId,
        title: 'Activity ${i + 1}',
      ),
    );
    mocks.setupActivityInstances(teamId, instances);
  }

  /// Setup with fines
  void setupWithFines(String teamId, {int fineCount = 3}) {
    final fines = List.generate(
      fineCount,
      (i) => TestFineFactory.create(
        id: 'fine-${i + 1}',
        teamId: teamId,
      ),
    );
    mocks.setupFinesList(teamId, fines);
  }

  /// Setup with fine rules
  void setupWithFineRules(String teamId, {int ruleCount = 3}) {
    final rules = List.generate(
      ruleCount,
      (i) => TestFineRuleFactory.create(
        id: 'rule-${i + 1}',
        teamId: teamId,
        name: 'Rule ${i + 1}',
        amount: (i + 1) * 50.0,
      ),
    );
    mocks.setupFineRules(teamId, rules);
  }

  /// Setup with messages
  void setupWithMessages(String teamId, {int messageCount = 5}) {
    final messages = List.generate(
      messageCount,
      (i) => TestMessageFactory.create(
        id: 'message-${i + 1}',
        teamId: teamId,
        content: 'Message ${i + 1}',
      ),
    );
    mocks.setupMessagesList(teamId, messages);
  }

  /// Get provider overrides
  List<Override> get overrides => mocks.overrides;
}

/// Extension methods for WidgetTester to simplify common test operations
extension WidgetTesterExtensions on WidgetTester {
  /// Find a widget by key and tap it
  Future<void> tapByKey(Key key) async {
    await tap(find.byKey(key));
    await pump();
  }

  /// Find a widget by text and tap it
  Future<void> tapByText(String text) async {
    await tap(find.text(text));
    await pump();
  }

  /// Enter text in a TextField by key
  Future<void> enterTextByKey(Key key, String text) async {
    await enterText(find.byKey(key), text);
    await pump();
  }

  /// Enter text in a TextField by hint text
  Future<void> enterTextByHint(String hint, String text) async {
    await enterText(
      find.widgetWithText(TextField, hint),
      text,
    );
    await pump();
  }

  /// Scroll until a widget is visible
  Future<void> scrollUntilVisible(
    Finder finder, {
    double delta = 100,
    Finder? scrollable,
  }) async {
    await dragUntilVisible(
      finder,
      scrollable ?? find.byType(Scrollable).first,
      Offset(0, -delta),
    );
  }
}

/// Common finders for the app
class AppFinders {
  // Auth screens
  static Finder get emailField => find.byKey(const Key('email_field'));
  static Finder get passwordField => find.byKey(const Key('password_field'));
  static Finder get nameField => find.byKey(const Key('name_field'));
  static Finder get loginButton => find.byKey(const Key('login_button'));
  static Finder get registerButton => find.byKey(const Key('register_button'));

  // Teams
  static Finder get createTeamButton => find.byKey(const Key('create_team_button'));
  static Finder get teamNameField => find.byKey(const Key('team_name_field'));
  static Finder get teamSportField => find.byKey(const Key('team_sport_field'));

  // Activities
  static Finder get createActivityButton => find.byKey(const Key('create_activity_button'));
  static Finder get activityTitleField => find.byKey(const Key('activity_title_field'));

  // Fines
  static Finder get reportFineButton => find.byKey(const Key('report_fine_button'));
  static Finder get fineAmountField => find.byKey(const Key('fine_amount_field'));

  // Common
  static Finder get saveButton => find.byKey(const Key('save_button'));
  static Finder get cancelButton => find.byKey(const Key('cancel_button'));
  static Finder get backButton => find.byIcon(Icons.arrow_back);
  static Finder get loadingIndicator => find.byType(CircularProgressIndicator);
  static Finder get snackBar => find.byType(SnackBar);

  // Find by text
  static Finder text(String text) => find.text(text);
  static Finder textContaining(String text) => find.textContaining(text);
}
