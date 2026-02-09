import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core_idrett_backend/db/database.dart';
import 'package:core_idrett_backend/db/supabase_client.dart';
import 'package:core_idrett_backend/services/statistics_service.dart';
import 'package:core_idrett_backend/services/user_service.dart';
import 'package:core_idrett_backend/services/team_service.dart';
import 'package:core_idrett_backend/services/player_rating_service.dart';
import 'package:core_idrett_backend/models/statistics.dart';

// Mock classes
class MockDatabase extends Mock implements Database {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockUserService extends Mock implements UserService {}
class MockTeamService extends Mock implements TeamService {}
class MockPlayerRatingService extends Mock implements PlayerRatingService {}

void main() {
  late MockDatabase mockDb;
  late MockSupabaseClient mockClient;
  late MockUserService mockUserService;
  late MockTeamService mockTeamService;
  late MockPlayerRatingService mockPlayerRatingService;
  late StatisticsService statisticsService;

  setUp(() {
    mockDb = MockDatabase();
    mockClient = MockSupabaseClient();
    mockUserService = MockUserService();
    mockTeamService = MockTeamService();
    mockPlayerRatingService = MockPlayerRatingService();

    when(() => mockDb.client).thenReturn(mockClient);

    statisticsService = StatisticsService(
      mockDb,
      mockUserService,
      mockTeamService,
      mockPlayerRatingService,
    );
  });

  group('StatisticsService - getLeaderboard', () {
    test('returns empty list when team has no members', () async {
      // Arrange
      when(() => mockTeamService.getTeamMemberUserIds(any()))
          .thenAnswer((_) async => []);

      // Act
      final result = await statisticsService.getLeaderboard('team-1');

      // Assert
      expect(result, isEmpty);
    });

    test('returns leaderboard sorted by points descending, then by rating', () async {
      // Arrange
      when(() => mockTeamService.getTeamMemberUserIds(any()))
          .thenAnswer((_) async => ['user-1', 'user-2', 'user-3']);

      when(() => mockUserService.getUserMap(any())).thenAnswer((_) async => {
        'user-1': {'id': 'user-1', 'name': 'User 1', 'avatar_url': null},
        'user-2': {'id': 'user-2', 'name': 'User 2', 'avatar_url': null},
        'user-3': {'id': 'user-3', 'name': 'User 3', 'avatar_url': null},
      });

      when(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'total_points': 50},
        {'user_id': 'user-2', 'total_points': 100},
        {'user_id': 'user-3', 'total_points': 75},
      ]);

      when(() => mockClient.select(
        'player_ratings',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'rating': 1000.0, 'wins': 0, 'losses': 0, 'draws': 0},
        {'user_id': 'user-2', 'rating': 1000.0, 'wins': 0, 'losses': 0, 'draws': 0},
        {'user_id': 'user-3', 'rating': 1000.0, 'wins': 0, 'losses': 0, 'draws': 0},
      ]);

      // Act
      final result = await statisticsService.getLeaderboard('team-1');

      // Assert
      expect(result.length, equals(3));
      expect(result[0].totalPoints, equals(100)); // user-2
      expect(result[1].totalPoints, equals(75));  // user-3
      expect(result[2].totalPoints, equals(50));  // user-1
    });

    test('assigns correct sequential ranks', () async {
      // Arrange
      when(() => mockTeamService.getTeamMemberUserIds(any()))
          .thenAnswer((_) async => ['user-1', 'user-2', 'user-3']);

      when(() => mockUserService.getUserMap(any())).thenAnswer((_) async => {
        'user-1': {'id': 'user-1', 'name': 'User 1', 'avatar_url': null},
        'user-2': {'id': 'user-2', 'name': 'User 2', 'avatar_url': null},
        'user-3': {'id': 'user-3', 'name': 'User 3', 'avatar_url': null},
      });

      when(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'total_points': 100},
        {'user_id': 'user-2', 'total_points': 50},
        {'user_id': 'user-3', 'total_points': 75},
      ]);

      when(() => mockClient.select(
        'player_ratings',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await statisticsService.getLeaderboard('team-1');

      // Assert
      expect(result[0].rank, equals(1));
      expect(result[1].rank, equals(2));
      expect(result[2].rank, equals(3));
    });

    test('handles missing season stats (defaults to 0 points)', () async {
      // Arrange
      when(() => mockTeamService.getTeamMemberUserIds(any()))
          .thenAnswer((_) async => ['user-1', 'user-2']);

      when(() => mockUserService.getUserMap(any())).thenAnswer((_) async => {
        'user-1': {'id': 'user-1', 'name': 'User 1', 'avatar_url': null},
        'user-2': {'id': 'user-2', 'name': 'User 2', 'avatar_url': null},
      });

      // Only user-1 has season stats
      when(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'total_points': 100},
      ]);

      when(() => mockClient.select(
        'player_ratings',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await statisticsService.getLeaderboard('team-1');

      // Assert
      expect(result[0].totalPoints, equals(100)); // user-1
      expect(result[1].totalPoints, equals(0));   // user-2 defaults to 0
    });

    test('handles missing player ratings (defaults to 1000.0 rating)', () async {
      // Arrange
      when(() => mockTeamService.getTeamMemberUserIds(any()))
          .thenAnswer((_) async => ['user-1']);

      when(() => mockUserService.getUserMap(any())).thenAnswer((_) async => {
        'user-1': {'id': 'user-1', 'name': 'User 1', 'avatar_url': null},
      });

      when(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // No ratings
      when(() => mockClient.select(
        'player_ratings',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await statisticsService.getLeaderboard('team-1');

      // Assert
      expect(result[0].rating, equals(1000.0));
    });

    test('filters by seasonYear parameter', () async {
      // Arrange
      when(() => mockTeamService.getTeamMemberUserIds(any()))
          .thenAnswer((_) async => ['user-1']);

      when(() => mockUserService.getUserMap(any())).thenAnswer((_) async => {
        'user-1': {'id': 'user-1', 'name': 'User 1', 'avatar_url': null},
      });

      when(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'total_points': 100},
      ]);

      when(() => mockClient.select(
        'player_ratings',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      await statisticsService.getLeaderboard('team-1', seasonYear: 2024);

      // Assert - Verify filter was applied with the provided year
      verify(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).called(1);
    });
  });

  group('StatisticsService - getPlayerStatistics', () {
    test('returns null when user is not a team member', () async {
      // Arrange
      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await statisticsService.getPlayerStatistics('user-1', 'team-1');

      // Assert
      expect(result, isNull);
    });

    test('returns null when user does not exist', () async {
      // Arrange
      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'team_id': 'team-1'},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await statisticsService.getPlayerStatistics('user-1', 'team-1');

      // Assert
      expect(result, isNull);
    });

    test('returns statistics with 0 totalActivities and 0.0 attendancePercentage when team has no activities', () async {
      // Arrange
      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'team_id': 'team-1'},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'Test User', 'avatar_url': null},
      ]);

      when(() => mockPlayerRatingService.getPlayerRating(any(), any()))
          .thenAnswer((_) async => null);

      when(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      when(() => mockClient.select(
        'activities',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await statisticsService.getPlayerStatistics('user-1', 'team-1');

      // Assert
      expect(result, isNotNull);
      expect(result!.totalActivities, equals(0));
      expect(result.attendancePercentage, equals(0.0));
      expect(result.attendancePercentage, isNot(isNaN));
    });

    test('calculates attendancePercentage correctly', () async {
      // Arrange
      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'team_id': 'team-1'},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'Test User', 'avatar_url': null},
      ]);

      when(() => mockPlayerRatingService.getPlayerRating(any(), any()))
          .thenAnswer((_) async => null);

      when(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      when(() => mockClient.select(
        'activities',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'activity-1'},
      ]);

      when(() => mockClient.select(
        'activity_instances',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'instance-1'},
        {'id': 'instance-2'},
        {'id': 'instance-3'},
        {'id': 'instance-4'},
      ]);

      when(() => mockClient.select(
        'activity_responses',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'instance_id': 'instance-1', 'user_id': 'user-1', 'response': 'yes'},
        {'instance_id': 'instance-2', 'user_id': 'user-1', 'response': 'yes'},
        {'instance_id': 'instance-3', 'user_id': 'user-1', 'response': 'yes'},
      ]);

      // Act
      final result = await statisticsService.getPlayerStatistics('user-1', 'team-1');

      // Assert
      expect(result, isNotNull);
      expect(result!.totalActivities, equals(4));
      expect(result.attendedActivities, equals(3));
      expect(result.attendancePercentage, equals(75.0)); // 3/4 * 100
    });

    test('returns 0.0 percentage when totalActivities is 0 (division-by-zero prevention)', () async {
      // Arrange
      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'team_id': 'team-1'},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'Test User', 'avatar_url': null},
      ]);

      when(() => mockPlayerRatingService.getPlayerRating(any(), any()))
          .thenAnswer((_) async => null);

      when(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      when(() => mockClient.select(
        'activities',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await statisticsService.getPlayerStatistics('user-1', 'team-1');

      // Assert
      expect(result!.attendancePercentage, equals(0.0));
      expect(result.attendancePercentage.isFinite, isTrue);
    });

    test('includes current season stats when available', () async {
      // Arrange
      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'team_id': 'team-1'},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'Test User', 'avatar_url': null},
      ]);

      when(() => mockPlayerRatingService.getPlayerRating(any(), any()))
          .thenAnswer((_) async => null);

      when(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {
          'id': 'season-stats-1',
          'user_id': 'user-1',
          'team_id': 'team-1',
          'season_year': DateTime.now().year,
          'total_points': 100,
          'total_wins': 5,
          'total_losses': 2,
          'total_draws': 1,
          'attendance_count': 10,
        },
      ]);

      when(() => mockClient.select(
        'activities',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await statisticsService.getPlayerStatistics('user-1', 'team-1');

      // Assert
      expect(result, isNotNull);
      expect(result!.currentSeason, isNotNull);
      expect(result.currentSeason!.totalPoints, equals(100));
    });

    test('includes player rating from PlayerRatingService', () async {
      // Arrange
      final testRating = PlayerRating(
        id: 'rating-1',
        userId: 'user-1',
        teamId: 'team-1',
        rating: 1250.5,
        wins: 5,
        losses: 2,
        draws: 1,
        updatedAt: DateTime(2025, 1, 1),
      );

      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'team_id': 'team-1'},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'Test User', 'avatar_url': null},
      ]);

      when(() => mockPlayerRatingService.getPlayerRating(any(), any()))
          .thenAnswer((_) async => testRating);

      when(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      when(() => mockClient.select(
        'activities',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await statisticsService.getPlayerStatistics('user-1', 'team-1');

      // Assert
      expect(result, isNotNull);
      expect(result!.rating, equals(testRating));
    });
  });

  group('StatisticsService - getTeamAttendance', () {
    test('returns empty list when team has no members', () async {
      // Arrange
      when(() => mockTeamService.getTeamMemberUserIds(any()))
          .thenAnswer((_) async => []);

      // Act
      final result = await statisticsService.getTeamAttendance('team-1');

      // Assert
      expect(result, isEmpty);
    });

    test('returns records with 0 totalActivities and 0.0 percentage when team has no activities', () async {
      // Arrange
      when(() => mockTeamService.getTeamMemberUserIds(any()))
          .thenAnswer((_) async => ['user-1']);

      when(() => mockUserService.getUserMap(any())).thenAnswer((_) async => {
        'user-1': {'id': 'user-1', 'name': 'Test User', 'avatar_url': null},
      });

      when(() => mockClient.select(
        'activities',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await statisticsService.getTeamAttendance('team-1');

      // Assert
      expect(result.length, equals(1));
      expect(result[0].totalActivities, equals(0));
      expect(result[0].percentage, equals(0.0));
      expect(result[0].percentage, isNot(isNaN));
    });

    test('calculates attendance correctly for multiple users', () async {
      // Arrange
      when(() => mockTeamService.getTeamMemberUserIds(any()))
          .thenAnswer((_) async => ['user-1', 'user-2']);

      when(() => mockUserService.getUserMap(any())).thenAnswer((_) async => {
        'user-1': {'id': 'user-1', 'name': 'User 1', 'avatar_url': null},
        'user-2': {'id': 'user-2', 'name': 'User 2', 'avatar_url': null},
      });

      when(() => mockClient.select(
        'activities',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'activity-1'},
      ]);

      when(() => mockClient.select(
        'activity_instances',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'instance-1', 'date': '2025-01-01'},
        {'id': 'instance-2', 'date': '2025-01-02'},
      ]);

      when(() => mockClient.select(
        'activity_responses',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'response': 'yes', 'instance_id': 'instance-1'},
        {'user_id': 'user-1', 'response': 'yes', 'instance_id': 'instance-2'},
        {'user_id': 'user-2', 'response': 'yes', 'instance_id': 'instance-1'},
        {'user_id': 'user-2', 'response': 'no', 'instance_id': 'instance-2'},
      ]);

      // Act
      final result = await statisticsService.getTeamAttendance('team-1');

      // Assert
      expect(result[0].attended, equals(2)); // user-1: 100% (should be first after sort)
      expect(result[1].attended, equals(1)); // user-2: 50%
    });

    test('sorts by percentage descending', () async {
      // Arrange
      when(() => mockTeamService.getTeamMemberUserIds(any()))
          .thenAnswer((_) async => ['user-1', 'user-2', 'user-3']);

      when(() => mockUserService.getUserMap(any())).thenAnswer((_) async => {
        'user-1': {'id': 'user-1', 'name': 'User 1', 'avatar_url': null},
        'user-2': {'id': 'user-2', 'name': 'User 2', 'avatar_url': null},
        'user-3': {'id': 'user-3', 'name': 'User 3', 'avatar_url': null},
      });

      when(() => mockClient.select(
        'activities',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'activity-1'},
      ]);

      when(() => mockClient.select(
        'activity_instances',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'instance-1', 'date': '2025-01-01'},
        {'id': 'instance-2', 'date': '2025-01-02'},
      ]);

      when(() => mockClient.select(
        'activity_responses',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'response': 'yes', 'instance_id': 'instance-1'},
        {'user_id': 'user-2', 'response': 'yes', 'instance_id': 'instance-1'},
        {'user_id': 'user-2', 'response': 'yes', 'instance_id': 'instance-2'},
        {'user_id': 'user-3', 'response': 'no', 'instance_id': 'instance-1'},
        {'user_id': 'user-3', 'response': 'no', 'instance_id': 'instance-2'},
      ]);

      // Act
      final result = await statisticsService.getTeamAttendance('team-1');

      // Assert
      expect(result[0].userId, equals('user-2')); // 100%
      expect(result[1].userId, equals('user-1')); // 50%
      expect(result[2].userId, equals('user-3')); // 0%
    });

    test('handles date range filtering (fromDate/toDate)', () async {
      // Arrange
      final fromDate = DateTime(2025, 1, 1);
      final toDate = DateTime(2025, 12, 31);

      when(() => mockTeamService.getTeamMemberUserIds(any()))
          .thenAnswer((_) async => ['user-1']);

      when(() => mockUserService.getUserMap(any())).thenAnswer((_) async => {
        'user-1': {'id': 'user-1', 'name': 'User 1', 'avatar_url': null},
      });

      when(() => mockClient.select(
        'activities',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      await statisticsService.getTeamAttendance('team-1', fromDate: fromDate, toDate: toDate);

      // Assert - Verify date filters were used
      verify(() => mockClient.select(
        'activities',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).called(1);
    });

    test('returns 0.0 percentage (not NaN/Infinity) when totalActivities is 0', () async {
      // Arrange
      when(() => mockTeamService.getTeamMemberUserIds(any()))
          .thenAnswer((_) async => ['user-1']);

      when(() => mockUserService.getUserMap(any())).thenAnswer((_) async => {
        'user-1': {'id': 'user-1', 'name': 'User 1', 'avatar_url': null},
      });

      when(() => mockClient.select(
        'activities',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await statisticsService.getTeamAttendance('team-1');

      // Assert
      expect(result[0].percentage, equals(0.0));
      expect(result[0].percentage.isFinite, isTrue);
      expect(result[0].percentage.isNaN, isFalse);
    });
  });

  group('StatisticsService - addPoints', () {
    test('creates new season_stats row when none exists for user+team+year', () async {
      // Arrange
      when(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      when(() => mockClient.insert(
        'season_stats',
        any(),
      )).thenAnswer((_) async => [
        {
          'user_id': 'user-1',
          'team_id': 'team-1',
          'season_year': DateTime.now().year,
          'total_points': 50,
        },
      ]);

      // Act
      await statisticsService.addPoints('user-1', 'team-1', 50);

      // Assert
      verify(() => mockClient.insert('season_stats', any())).called(1);
    });

    test('increments existing total_points when season_stats exists', () async {
      // Arrange
      when(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {
          'user_id': 'user-1',
          'team_id': 'team-1',
          'season_year': DateTime.now().year,
          'total_points': 100,
        },
      ]);

      when(() => mockClient.update(
        'season_stats',
        any(),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {
          'user_id': 'user-1',
          'team_id': 'team-1',
          'season_year': DateTime.now().year,
          'total_points': 150,
        },
      ]);

      // Act
      await statisticsService.addPoints('user-1', 'team-1', 50);

      // Assert
      verify(() => mockClient.update(
        'season_stats',
        any(),
        filters: any(named: 'filters'),
      )).called(1);
    });
  });

  group('StatisticsService - recordMatchResult', () {
    test('creates new season_stats with win column set to 1', () async {
      // Arrange
      when(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      when(() => mockClient.insert(
        'season_stats',
        any(),
      )).thenAnswer((_) async => [
        {
          'user_id': 'user-1',
          'team_id': 'team-1',
          'season_year': DateTime.now().year,
          'total_wins': 1,
        },
      ]);

      // Act
      await statisticsService.recordMatchResult('user-1', 'team-1', 'win');

      // Assert
      verify(() => mockClient.insert('season_stats', any())).called(1);
    });

    test('increments existing win count', () async {
      // Arrange
      when(() => mockClient.select(
        'season_stats',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {
          'user_id': 'user-1',
          'team_id': 'team-1',
          'season_year': DateTime.now().year,
          'total_wins': 5,
        },
      ]);

      when(() => mockClient.update(
        'season_stats',
        any(),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {
          'user_id': 'user-1',
          'team_id': 'team-1',
          'season_year': DateTime.now().year,
          'total_wins': 6,
        },
      ]);

      // Act
      await statisticsService.recordMatchResult('user-1', 'team-1', 'win');

      // Assert
      verify(() => mockClient.update(
        'season_stats',
        any(),
        filters: any(named: 'filters'),
      )).called(1);
    });

    test('ignores invalid result strings (not win, loss, draw)', () async {
      // Arrange - No expectations, method should return early

      // Act
      await statisticsService.recordMatchResult('user-1', 'team-1', 'invalid');

      // Assert - No database calls should be made
      verifyNever(() => mockClient.select(any(), filters: any(named: 'filters')));
      verifyNever(() => mockClient.insert(any(), any()));
      verifyNever(() => mockClient.update(any(), any(), filters: any(named: 'filters')));
    });
  });
}
