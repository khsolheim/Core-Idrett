import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core_idrett_backend/db/database.dart';
import 'package:core_idrett_backend/db/supabase_client.dart';
import 'package:core_idrett_backend/services/export/export_data_service.dart';
import 'package:core_idrett_backend/services/export/export_utility_service.dart';

// Mock classes
class MockDatabase extends Mock implements Database {}
class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockDatabase mockDb;
  late MockSupabaseClient mockClient;
  late ExportDataService exportDataService;
  late ExportUtilityService exportUtilityService;

  setUp(() {
    mockDb = MockDatabase();
    mockClient = MockSupabaseClient();
    when(() => mockDb.client).thenReturn(mockClient);

    exportDataService = ExportDataService(mockDb);
    exportUtilityService = ExportUtilityService(mockDb);
  });

  group('ExportDataService - exportLeaderboard', () {
    test('returns correct structure with type and columns', () async {
      // Arrange
      when(() => mockClient.select(
        'leaderboard_entries',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => [
        {'id': '1', 'user_id': 'user-1', 'points': 100},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'Test User'},
      ]);

      // Act
      final result = await exportDataService.exportLeaderboard('team-1');

      // Assert
      expect(result['type'], equals('leaderboard'));
      expect(result['columns'], equals(['Plass', 'Bruker', 'Poeng']));
      expect(result['data'], isA<List>());
    });

    test('returns empty data array when no entries', () async {
      // Arrange
      when(() => mockClient.select(
        'leaderboard_entries',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await exportDataService.exportLeaderboard('team-1');

      // Assert
      expect(result['type'], equals('leaderboard'));
      expect(result['data'], isEmpty);
    });

    test('maps user names correctly from user lookup', () async {
      // Arrange
      when(() => mockClient.select(
        'leaderboard_entries',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => [
        {'id': '1', 'user_id': 'user-1', 'points': 100},
        {'id': '2', 'user_id': 'user-2', 'points': 50},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'Alice'},
        {'id': 'user-2', 'name': 'Bob'},
      ]);

      // Act
      final result = await exportDataService.exportLeaderboard('team-1');

      // Assert
      final data = result['data'] as List;
      expect(data[0]['user_name'], equals('Alice'));
      expect(data[1]['user_name'], equals('Bob'));
    });

    test('assigns sequential ranks', () async {
      // Arrange
      when(() => mockClient.select(
        'leaderboard_entries',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => [
        {'id': '1', 'user_id': 'user-1', 'points': 100},
        {'id': '2', 'user_id': 'user-2', 'points': 75},
        {'id': '3', 'user_id': 'user-3', 'points': 50},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'User 1'},
        {'id': 'user-2', 'name': 'User 2'},
        {'id': 'user-3', 'name': 'User 3'},
      ]);

      // Act
      final result = await exportDataService.exportLeaderboard('team-1');

      // Assert
      final data = result['data'] as List;
      expect(data[0]['rank'], equals(1));
      expect(data[1]['rank'], equals(2));
      expect(data[2]['rank'], equals(3));
    });

    test('handles seasonId and leaderboardId filter params', () async {
      // Arrange
      when(() => mockClient.select(
        'leaderboard_entries',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => []);

      // Act
      await exportDataService.exportLeaderboard(
        'team-1',
        seasonId: 'season-1',
        leaderboardId: 'leaderboard-1',
      );

      // Assert
      verify(() => mockClient.select(
        'leaderboard_entries',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).called(1);
    });
  });

  group('ExportDataService - exportAttendance', () {
    test('returns correct structure with type attendance', () async {
      // Arrange
      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'is_active': true},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'Test User'},
      ]);

      when(() => mockClient.select(
        'activity_instances',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await exportDataService.exportAttendance('team-1');

      // Assert
      expect(result['type'], equals('attendance'));
      expect(result['columns'], equals(['Bruker', 'Tilstede', 'Fravarende', 'Kanskje', 'Totalt', 'Oppmote %']));
    });

    test('returns zero attendance when no activities exist', () async {
      // Arrange
      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'is_active': true},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'Test User'},
      ]);

      when(() => mockClient.select(
        'activity_instances',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await exportDataService.exportAttendance('team-1');

      // Assert
      final data = result['data'] as List;
      expect(data[0]['total_activities'], equals(0));
      expect(data[0]['attendance_rate'], equals(0));
      expect(data[0]['attendance_rate'], isNot(isNaN));
    });

    test('calculates attendance rate correctly', () async {
      // Arrange
      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'is_active': true},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'Test User'},
      ]);

      when(() => mockClient.select(
        'activity_instances',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'activity-1'},
        {'id': 'activity-2'},
        {'id': 'activity-3'},
        {'id': 'activity-4'},
      ]);

      when(() => mockClient.select(
        'activity_participants',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'status': 'attending'},
        {'user_id': 'user-1', 'status': 'attending'},
        {'user_id': 'user-1', 'status': 'attending'},
      ]);

      // Act
      final result = await exportDataService.exportAttendance('team-1');

      // Assert
      final data = result['data'] as List;
      expect(data[0]['attended'], equals(3));
      expect(data[0]['total_activities'], equals(4));
      expect(data[0]['attendance_rate'], equals(75)); // 3/4 * 100 rounded
    });

    test('sorts by attendance rate descending', () async {
      // Arrange
      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'is_active': true},
        {'user_id': 'user-2', 'is_active': true},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'User 1'},
        {'id': 'user-2', 'name': 'User 2'},
      ]);

      when(() => mockClient.select(
        'activity_instances',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'activity-1'},
        {'id': 'activity-2'},
      ]);

      when(() => mockClient.select(
        'activity_participants',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'status': 'attending'},
        {'user_id': 'user-2', 'status': 'attending'},
        {'user_id': 'user-2', 'status': 'attending'},
      ]);

      // Act
      final result = await exportDataService.exportAttendance('team-1');

      // Assert
      final data = result['data'] as List;
      // user-2 has 100% attendance (2/2), user-1 has 50% (1/2)
      expect(data[0]['user_id'], equals('user-2'));
      expect(data[1]['user_id'], equals('user-1'));
    });

    test('handles fromDate and toDate filters', () async {
      // Arrange
      final fromDate = DateTime(2025, 1, 1);
      final toDate = DateTime(2025, 12, 31);

      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'is_active': true},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'Test User'},
      ]);

      when(() => mockClient.select(
        'activity_instances',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      await exportDataService.exportAttendance(
        'team-1',
        fromDate: fromDate,
        toDate: toDate,
      );

      // Assert - Verify that filters were applied (service was called with filters)
      verify(() => mockClient.select(
        'activity_instances',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).called(1);
    });
  });

  group('ExportDataService - exportFines', () {
    test('returns correct structure with type fines and summary', () async {
      // Arrange
      when(() => mockClient.select(
        'fines',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await exportDataService.exportFines('team-1');

      // Assert
      expect(result['type'], equals('fines'));
      expect(result['columns'], equals(['Bruker', 'Regel', 'Belop', 'Betalt', 'Betalt dato', 'Opprettet']));
      expect(result['summary'], isA<Map>());
      expect(result['summary']['total_amount'], equals(0));
      expect(result['summary']['paid_amount'], equals(0));
      expect(result['summary']['unpaid_amount'], equals(0));
      expect(result['summary']['total_count'], equals(0));
    });

    test('returns empty summary (zeros) when no fines', () async {
      // Arrange
      when(() => mockClient.select(
        'fines',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await exportDataService.exportFines('team-1');

      // Assert
      expect(result['data'], isEmpty);
      expect(result['summary']['total_count'], equals(0));
    });

    test('calculates total_amount, paid_amount, unpaid_amount correctly', () async {
      // Arrange
      when(() => mockClient.select(
        'fines',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => [
        {'id': '1', 'user_id': 'user-1', 'amount': 100, 'paid_at': null, 'rule_id': null, 'created_at': '2025-01-01'},
        {'id': '2', 'user_id': 'user-2', 'amount': 50, 'paid_at': '2025-01-15', 'rule_id': null, 'created_at': '2025-01-01'},
        {'id': '3', 'user_id': 'user-3', 'amount': 75, 'paid_at': '2025-01-20', 'rule_id': null, 'created_at': '2025-01-01'},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'User 1'},
        {'id': 'user-2', 'name': 'User 2'},
        {'id': 'user-3', 'name': 'User 3'},
      ]);

      // Act
      final result = await exportDataService.exportFines('team-1');

      // Assert
      expect(result['summary']['total_amount'], equals(225)); // 100 + 50 + 75
      expect(result['summary']['paid_amount'], equals(125)); // 50 + 75
      expect(result['summary']['unpaid_amount'], equals(100)); // 100
      expect(result['summary']['total_count'], equals(3));
    });

    test('handles paidOnly=true filter', () async {
      // Arrange
      when(() => mockClient.select(
        'fines',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => []);

      // Act
      await exportDataService.exportFines('team-1', paidOnly: true);

      // Assert
      verify(() => mockClient.select(
        'fines',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).called(1);
    });

    test('handles paidOnly=false filter', () async {
      // Arrange
      when(() => mockClient.select(
        'fines',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => []);

      // Act
      await exportDataService.exportFines('team-1', paidOnly: false);

      // Assert
      verify(() => mockClient.select(
        'fines',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).called(1);
    });

    test('maps rule names and user names correctly', () async {
      // Arrange
      when(() => mockClient.select(
        'fines',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => [
        {'id': '1', 'user_id': 'user-1', 'amount': 100, 'paid_at': null, 'rule_id': 'rule-1', 'created_at': '2025-01-01'},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'Test User'},
      ]);

      when(() => mockClient.select(
        'fine_rules',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'rule-1', 'name': 'Late to training'},
      ]);

      // Act
      final result = await exportDataService.exportFines('team-1');

      // Assert
      final data = result['data'] as List;
      expect(data[0]['user_name'], equals('Test User'));
      expect(data[0]['rule_name'], equals('Late to training'));
    });
  });

  group('ExportDataService - exportMembers', () {
    test('returns correct structure with type members', () async {
      // Arrange
      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await exportDataService.exportMembers('team-1');

      // Assert
      expect(result['type'], equals('members'));
      expect(result['columns'], equals(['Navn', 'E-post', 'Fodselsdato', 'Roller', 'Ble med']));
      expect(result['data'], isEmpty);
    });

    test('returns empty data when no active members', () async {
      // Arrange
      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await exportDataService.exportMembers('team-1');

      // Assert
      expect(result['data'], isEmpty);
    });

    test('maps roles correctly (Admin, Botesjef, trainer type)', () async {
      // Arrange
      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => [
        {
          'user_id': 'user-1',
          'is_admin': true,
          'is_fine_boss': false,
          'trainer_type_id': null,
          'joined_at': '2025-01-01',
          'is_active': true
        },
        {
          'user_id': 'user-2',
          'is_admin': false,
          'is_fine_boss': true,
          'trainer_type_id': null,
          'joined_at': '2025-01-02',
          'is_active': true
        },
        {
          'user_id': 'user-3',
          'is_admin': false,
          'is_fine_boss': false,
          'trainer_type_id': 'trainer-1',
          'joined_at': '2025-01-03',
          'is_active': true
        },
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'Admin User', 'email': 'admin@test.com', 'birth_date': '1990-01-01'},
        {'id': 'user-2', 'name': 'Fine Boss', 'email': 'boss@test.com', 'birth_date': '1991-01-01'},
        {'id': 'user-3', 'name': 'Trainer', 'email': 'trainer@test.com', 'birth_date': '1992-01-01'},
      ]);

      when(() => mockClient.select(
        'trainer_types',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'trainer-1', 'name': 'Head Coach'},
      ]);

      // Act
      final result = await exportDataService.exportMembers('team-1');

      // Assert
      final data = result['data'] as List;
      expect(data[0]['roles'], equals('Admin'));
      expect(data[1]['roles'], equals('Botesjef'));
      expect(data[2]['roles'], equals('Head Coach'));
    });

    test('sorts by name alphabetically', () async {
      // Arrange
      when(() => mockClient.select(
        'team_members',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'is_admin': false, 'is_fine_boss': false, 'trainer_type_id': null, 'joined_at': '2025-01-01', 'is_active': true},
        {'user_id': 'user-2', 'is_admin': false, 'is_fine_boss': false, 'trainer_type_id': null, 'joined_at': '2025-01-02', 'is_active': true},
      ]);

      when(() => mockClient.select(
        'users',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'user-1', 'name': 'Zoe', 'email': 'zoe@test.com', 'birth_date': null},
        {'id': 'user-2', 'name': 'Alice', 'email': 'alice@test.com', 'birth_date': null},
      ]);

      // Act
      final result = await exportDataService.exportMembers('team-1');

      // Assert
      final data = result['data'] as List;
      expect(data[0]['name'], equals('Alice'));
      expect(data[1]['name'], equals('Zoe'));
    });
  });

  group('ExportDataService - exportActivities', () {
    test('returns correct structure with type activities', () async {
      // Arrange
      when(() => mockClient.select(
        'activity_instances',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await exportDataService.exportActivities('team-1');

      // Assert
      expect(result['type'], equals('activities'));
      expect(result['columns'], equals(['Aktivitet', 'Type', 'Starttid', 'Sluttid', 'Sted', 'Deltakere']));
      expect(result['data'], isEmpty);
    });

    test('returns empty data when no activities', () async {
      // Arrange
      when(() => mockClient.select(
        'activity_instances',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await exportDataService.exportActivities('team-1');

      // Assert
      expect(result['data'], isEmpty);
    });

    test('maps template names and types', () async {
      // Arrange
      when(() => mockClient.select(
        'activity_instances',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => [
        {
          'id': 'activity-1',
          'template_id': 'template-1',
          'title': null,
          'type': null,
          'start_time': '2025-01-01T10:00:00Z',
          'end_time': '2025-01-01T12:00:00Z',
          'location': 'Field 1',
        },
      ]);

      when(() => mockClient.select(
        'activity_templates',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'id': 'template-1', 'name': 'Training Session', 'type': 'training'},
      ]);

      when(() => mockClient.select(
        'activity_participants',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await exportDataService.exportActivities('team-1');

      // Assert
      final data = result['data'] as List;
      expect(data[0]['title'], equals('Training Session'));
      expect(data[0]['type'], equals('training'));
    });

    test('calculates attending_count from participants', () async {
      // Arrange
      when(() => mockClient.select(
        'activity_instances',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => [
        {
          'id': 'activity-1',
          'template_id': null,
          'title': 'Test Activity',
          'type': 'match',
          'start_time': '2025-01-01T10:00:00Z',
          'end_time': '2025-01-01T12:00:00Z',
          'location': 'Field 1',
        },
      ]);

      when(() => mockClient.select(
        'activity_participants',
        select: any(named: 'select'),
        filters: any(named: 'filters'),
      )).thenAnswer((_) async => [
        {'instance_id': 'activity-1', 'status': 'attending'},
        {'instance_id': 'activity-1', 'status': 'attending'},
        {'instance_id': 'activity-1', 'status': 'absent'},
      ]);

      // Act
      final result = await exportDataService.exportActivities('team-1');

      // Assert
      final data = result['data'] as List;
      expect(data[0]['attending_count'], equals(2));
    });

    test('handles date range filters', () async {
      // Arrange
      final fromDate = DateTime(2025, 1, 1);
      final toDate = DateTime(2025, 12, 31);

      when(() => mockClient.select(
        'activity_instances',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => []);

      // Act
      await exportDataService.exportActivities(
        'team-1',
        fromDate: fromDate,
        toDate: toDate,
      );

      // Assert
      verify(() => mockClient.select(
        'activity_instances',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).called(1);
    });
  });

  group('ExportUtilityService - generateCsv', () {
    test('generates header row with semicolon delimiter', () {
      // Arrange
      final exportData = {
        'type': 'test',
        'columns': ['Name', 'Age', 'City'],
        'data': [],
      };

      // Act
      final csv = exportUtilityService.generateCsv(exportData);

      // Assert
      expect(csv, startsWith('Name;Age;City\n'));
    });

    test('formats boolean values as Ja/Nei', () {
      // Arrange
      final exportData = {
        'type': 'test',
        'columns': ['Name', 'Active'],
        'data': [
          {'name': 'Alice', 'active': true},
          {'name': 'Bob', 'active': false},
        ],
      };

      // Act
      final csv = exportUtilityService.generateCsv(exportData);

      // Assert
      expect(csv, contains('Alice;Ja'));
      expect(csv, contains('Bob;Nei'));
    });

    test('escapes values containing semicolons with quotes', () {
      // Arrange
      final exportData = {
        'type': 'test',
        'columns': ['Name', 'Description'],
        'data': [
          {'name': 'Test', 'description': 'A; B; C'},
        ],
      };

      // Act
      final csv = exportUtilityService.generateCsv(exportData);

      // Assert
      expect(csv, contains('"A; B; C"'));
    });

    test('handles null values as empty strings', () {
      // Arrange
      final exportData = {
        'type': 'test',
        'columns': ['Name', 'Optional'],
        'data': [
          {'name': 'Test', 'optional': null},
        ],
      };

      // Act
      final csv = exportUtilityService.generateCsv(exportData);

      // Assert
      final lines = csv.split('\n');
      expect(lines[1], equals('Test;'));
    });

    test('empty data produces header-only CSV', () {
      // Arrange
      final exportData = {
        'type': 'test',
        'columns': ['Col1', 'Col2'],
        'data': [],
      };

      // Act
      final csv = exportUtilityService.generateCsv(exportData);

      // Assert
      expect(csv, equals('Col1;Col2\n'));
    });
  });
}
