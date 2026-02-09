/// Mock repositories for testing
library;

import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/data/api/api_client.dart';
import 'package:core_idrett/data/models/user.dart';
import 'package:core_idrett/data/models/team.dart';
import 'package:core_idrett/data/models/activity.dart';
import 'package:core_idrett/data/models/fine.dart';
import 'package:core_idrett/data/models/message.dart';
import 'package:core_idrett/features/auth/data/auth_repository.dart';
import 'package:core_idrett/features/teams/data/team_repository.dart';
import 'package:core_idrett/features/teams/providers/team_provider.dart';
import 'package:core_idrett/features/activities/data/activity_repository.dart';
import 'package:core_idrett/features/fines/data/fines_repository.dart';
import 'package:core_idrett/features/fines/providers/fines_provider.dart';
import 'package:core_idrett/features/chat/data/chat_repository.dart';
import 'package:core_idrett/features/export/data/export_repository.dart';
import 'package:core_idrett/data/models/export_log.dart';
import 'package:core_idrett/features/mini_activities/data/tournament_repository.dart';
import 'package:core_idrett/data/models/tournament.dart';

// ============ Mock Classes ============

class MockApiClient extends Mock implements ApiClient {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTeamRepository extends Mock implements TeamRepository {}

class MockActivityRepository extends Mock implements ActivityRepository {}

class MockFinesRepository extends Mock implements FinesRepository {}

class MockChatRepository extends Mock implements ChatRepository {}

class MockExportRepository extends Mock implements ExportRepository {}

class MockTournamentRepository extends Mock implements TournamentRepository {}

// ============ Register Fallback Values ============

void registerFallbackValues() {
  registerFallbackValue(ActivityType.training);
  registerFallbackValue(RecurrenceType.once);
  registerFallbackValue(ResponseType.yesNo);
  registerFallbackValue(UserResponse.yes);
  registerFallbackValue(ExportType.leaderboard);
  registerFallbackValue(TournamentType.singleElimination);
}

// ============ Mock Providers Setup ============

/// Creates provider overrides for testing with mocked repositories
class MockProviders {
  final MockApiClient apiClient;
  final MockAuthRepository authRepository;
  final MockTeamRepository teamRepository;
  final MockActivityRepository activityRepository;
  final MockFinesRepository finesRepository;
  final MockChatRepository chatRepository;
  final MockExportRepository exportRepository;
  final MockTournamentRepository tournamentRepository;

  MockProviders()
      : apiClient = MockApiClient(),
        authRepository = MockAuthRepository(),
        teamRepository = MockTeamRepository(),
        activityRepository = MockActivityRepository(),
        finesRepository = MockFinesRepository(),
        chatRepository = MockChatRepository(),
        exportRepository = MockExportRepository(),
        tournamentRepository = MockTournamentRepository();

  /// Get all provider overrides for ProviderScope
  List<Object> get overrides => [
        apiClientProvider.overrideWithValue(apiClient),
        authRepositoryProvider.overrideWithValue(authRepository),
        teamRepositoryProvider.overrideWithValue(teamRepository),
        activityRepositoryProvider.overrideWithValue(activityRepository),
        finesRepositoryProvider.overrideWithValue(finesRepository),
        chatRepositoryProvider.overrideWithValue(chatRepository),
        exportRepositoryProvider.overrideWithValue(exportRepository),
        tournamentRepositoryProvider.overrideWithValue(tournamentRepository),
      ];

  /// Setup default successful auth state
  void setupAuthenticatedUser(User user) {
    when(() => authRepository.getCurrentUser())
        .thenAnswer((_) async => user);
  }

  /// Setup unauthenticated state
  void setupUnauthenticated() {
    when(() => authRepository.getCurrentUser())
        .thenAnswer((_) async => null);
  }

  /// Setup login success
  void setupLoginSuccess({
    required User user,
    String token = 'mock-token',
  }) {
    when(() => authRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => AuthResult(token: token, user: user));
  }

  /// Setup login failure
  void setupLoginFailure(Exception error) {
    when(() => authRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(error);
  }

  /// Setup register success
  void setupRegisterSuccess({
    required User user,
    String token = 'mock-token',
  }) {
    when(() => authRepository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          name: any(named: 'name'),
          inviteCode: any(named: 'inviteCode'),
        )).thenAnswer((_) async => AuthResult(token: token, user: user));
  }

  /// Setup teams list
  void setupTeamsList(List<Team> teams) {
    when(() => teamRepository.getTeams())
        .thenAnswer((_) async => teams);
  }

  /// Setup single team fetch
  void setupGetTeam(Team team) {
    when(() => teamRepository.getTeam(team.id))
        .thenAnswer((_) async => team);
  }

  /// Setup team members
  void setupTeamMembers(String teamId, List<TeamMember> members) {
    when(() => teamRepository.getTeamMembers(teamId, includeInactive: any(named: 'includeInactive')))
        .thenAnswer((_) async => members);
  }

  /// Setup create team
  void setupCreateTeam(Team team) {
    when(() => teamRepository.createTeam(
          name: any(named: 'name'),
          sport: any(named: 'sport'),
        )).thenAnswer((_) async => team);
  }

  /// Setup activity instances list
  void setupActivityInstances(String teamId, List<ActivityInstance> instances) {
    when(() => activityRepository.getUpcomingInstances(teamId, limit: any(named: 'limit')))
        .thenAnswer((_) async => instances);
  }

  /// Setup single activity instance
  void setupGetActivityInstance(ActivityInstance instance) {
    when(() => activityRepository.getInstance(instance.id))
        .thenAnswer((_) async => instance);
  }

  /// Setup fines list
  void setupFinesList(String teamId, List<Fine> fines) {
    when(() => finesRepository.getFines(
          teamId,
          status: any(named: 'status'),
          offenderId: any(named: 'offenderId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => fines);
  }

  /// Setup fine rules
  void setupFineRules(String teamId, List<FineRule> rules) {
    when(() => finesRepository.getFineRules(teamId, activeOnly: any(named: 'activeOnly')))
        .thenAnswer((_) async => rules);
  }

  /// Setup messages list
  void setupMessagesList(String teamId, List<Message> messages) {
    when(() => chatRepository.getMessages(
          teamId,
          limit: any(named: 'limit'),
          before: any(named: 'before'),
          after: any(named: 'after'),
        )).thenAnswer((_) async => messages);
  }

  /// Setup team fines summary
  void setupTeamFinesSummary(String teamId, {
    double totalFines = 1000,
    double totalPaid = 500,
    double totalPending = 500,
    int fineCount = 10,
    int pendingCount = 5,
    int paidCount = 5,
  }) {
    when(() => finesRepository.getTeamSummary(teamId))
        .thenAnswer((_) async => TeamFinesSummary(
              teamId: teamId,
              totalFines: totalFines,
              totalPaid: totalPaid,
              totalPending: totalPending,
              fineCount: fineCount,
              pendingCount: pendingCount,
              paidCount: paidCount,
            ));
  }

  /// Setup export history
  void setupExportHistory(String teamId, List<ExportLog> logs) {
    when(() => exportRepository.getExportHistory(teamId, limit: any(named: 'limit')))
        .thenAnswer((_) async => logs);
  }

  /// Setup export data
  void setupExportLeaderboard(String teamId, ExportData data) {
    when(() => exportRepository.exportLeaderboard(
      teamId,
      format: any(named: 'format'),
      seasonId: any(named: 'seasonId'),
      leaderboardId: any(named: 'leaderboardId'),
    )).thenAnswer((_) async => data);
  }

  /// Setup tournament fetch
  void setupGetTournament(Tournament tournament) {
    when(() => tournamentRepository.getTournament(tournament.id))
        .thenAnswer((_) async => tournament);
  }
}

/// Extension to make it easier to use mocks in tests
extension MockProvidersTestExtensions on MockProviders {
  /// Verify login was called with specific credentials
  void verifyLoginCalled({
    required String email,
    required String password,
  }) {
    verify(() => authRepository.login(
          email: email,
          password: password,
        )).called(1);
  }

  /// Verify register was called
  void verifyRegisterCalled({
    required String email,
    required String password,
    required String name,
    String? inviteCode,
  }) {
    verify(() => authRepository.register(
          email: email,
          password: password,
          name: name,
          inviteCode: inviteCode,
        )).called(1);
  }

  /// Verify teams list was fetched
  void verifyTeamsListFetched() {
    verify(() => teamRepository.getTeams()).called(1);
  }

  /// Verify create team was called
  void verifyCreateTeamCalled({
    required String name,
    String? sport,
  }) {
    verify(() => teamRepository.createTeam(
          name: name,
          sport: sport,
        )).called(1);
  }
}
