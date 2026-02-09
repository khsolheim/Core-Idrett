import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core_idrett_backend/db/database.dart';
import 'package:core_idrett_backend/db/supabase_client.dart';
import 'package:core_idrett_backend/models/tournament.dart';
import 'package:core_idrett_backend/services/tournament/tournament_bracket_service.dart';
import 'package:core_idrett_backend/services/tournament/tournament_crud_service.dart';
import 'package:core_idrett_backend/services/tournament/tournament_rounds_service.dart';
import 'package:core_idrett_backend/services/tournament/tournament_matches_service.dart';
import 'package:core_idrett_backend/services/tournament_group_service.dart';

class MockDatabase extends Mock implements Database {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockTournamentCrudService extends Mock implements TournamentCrudService {}
class MockTournamentRoundsService extends Mock implements TournamentRoundsService {}
class MockTournamentMatchesService extends Mock implements TournamentMatchesService {}
class MockTournamentGroupService extends Mock implements TournamentGroupService {}

void main() {
  late MockDatabase db;
  late MockSupabaseClient client;
  late MockTournamentCrudService crudService;
  late MockTournamentRoundsService roundsService;
  late MockTournamentMatchesService matchesService;
  late MockTournamentGroupService groupService;
  late TournamentBracketService service;

  setUpAll(() {
    registerFallbackValue(RoundType.winners);
    registerFallbackValue(TournamentStatus.inProgress);
    registerFallbackValue(MatchStatus.pending);
  });

  setUp(() {
    db = MockDatabase();
    client = MockSupabaseClient();
    crudService = MockTournamentCrudService();
    roundsService = MockTournamentRoundsService();
    matchesService = MockTournamentMatchesService();
    groupService = MockTournamentGroupService();

    when(() => db.client).thenReturn(client);

    service = TournamentBracketService(
      db,
      crudService,
      roundsService,
      matchesService,
      groupService,
    );
  });

  group('generateSingleEliminationBracket', () {
    group('round name generation', () {
      test('2 lag (1 runde) → roundNames: [Finale]', () async {
        final teamIds = ['team1', 'team2'];
        var roundCounter = 0;
        var matchCounter = 0;
        final createdRoundNames = <String>[];

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          roundCounter++;
          final roundName = invocation.namedArguments[#roundName] as String?;
          createdRoundNames.add(roundName ?? '');
          return TournamentRound(
            id: 'round-$roundCounter',
            tournamentId: 'tourn-1',
            roundNumber: invocation.namedArguments[#roundNumber] as int,
            roundName: roundName,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          matchCounter++;
          return TournamentMatch(
            id: 'match-$matchCounter',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: invocation.namedArguments[#bracketPosition] as int,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
        );

        expect(createdRoundNames, equals(['Finale']));
      });

      test('3-4 lag (2 runder) → roundNames: [Finale, Semifinale]', () async {
        final teamIds = ['team1', 'team2', 'team3', 'team4'];
        var roundCounter = 0;
        var matchCounter = 0;
        final createdRoundNames = <String>[];

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          roundCounter++;
          final roundName = invocation.namedArguments[#roundName] as String?;
          createdRoundNames.add(roundName ?? '');
          return TournamentRound(
            id: 'round-$roundCounter',
            tournamentId: 'tourn-1',
            roundNumber: invocation.namedArguments[#roundNumber] as int,
            roundName: roundName,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          matchCounter++;
          return TournamentMatch(
            id: 'match-$matchCounter',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: invocation.namedArguments[#bracketPosition] as int,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
        );

        expect(createdRoundNames, equals(['Finale', 'Semifinale']));
      });

      test('5-8 lag (3 runder) → roundNames: [Finale, Semifinale, Kvartfinale]', () async {
        final teamIds = ['team1', 'team2', 'team3', 'team4', 'team5', 'team6', 'team7', 'team8'];
        var roundCounter = 0;
        var matchCounter = 0;
        final createdRoundNames = <String>[];

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          roundCounter++;
          final roundName = invocation.namedArguments[#roundName] as String?;
          createdRoundNames.add(roundName ?? '');
          return TournamentRound(
            id: 'round-$roundCounter',
            tournamentId: 'tourn-1',
            roundNumber: invocation.namedArguments[#roundNumber] as int,
            roundName: roundName,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          matchCounter++;
          return TournamentMatch(
            id: 'match-$matchCounter',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: invocation.namedArguments[#bracketPosition] as int,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
        );

        expect(createdRoundNames, equals(['Finale', 'Semifinale', 'Kvartfinale']));
      });

      test('9-16 lag (4 runder) → roundNames: [Finale, Semifinale, Kvartfinale, 8-delsfinale]', () async {
        final teamIds = List.generate(16, (i) => 'team${i + 1}');
        var roundCounter = 0;
        var matchCounter = 0;
        final createdRoundNames = <String>[];

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          roundCounter++;
          final roundName = invocation.namedArguments[#roundName] as String?;
          createdRoundNames.add(roundName ?? '');
          return TournamentRound(
            id: 'round-$roundCounter',
            tournamentId: 'tourn-1',
            roundNumber: invocation.namedArguments[#roundNumber] as int,
            roundName: roundName,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          matchCounter++;
          return TournamentMatch(
            id: 'match-$matchCounter',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: invocation.namedArguments[#bracketPosition] as int,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
        );

        expect(createdRoundNames, equals(['Finale', 'Semifinale', 'Kvartfinale', '8-delsfinale']));
      });
    });

    group('participant count handling', () {
      test('2 deltakere → 1 runde, 1 kamp, alle lag plassert', () async {
        final teamIds = ['team1', 'team2'];
        var roundCounter = 0;
        var matchCounter = 0;
        final placedTeams = <String>[];

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          roundCounter++;
          return TournamentRound(
            id: 'round-$roundCounter',
            tournamentId: 'tourn-1',
            roundNumber: invocation.namedArguments[#roundNumber] as int,
            roundName: invocation.namedArguments[#roundName] as String?,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          matchCounter++;
          final teamA = invocation.namedArguments[#teamAId] as String?;
          final teamB = invocation.namedArguments[#teamBId] as String?;
          if (teamA != null) placedTeams.add(teamA);
          if (teamB != null) placedTeams.add(teamB);

          return TournamentMatch(
            id: 'match-$matchCounter',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: invocation.namedArguments[#bracketPosition] as int,
            teamAId: teamA,
            teamBId: teamB,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        final matches = await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
        );

        expect(roundCounter, equals(1));
        expect(matches.length, equals(1));
        expect(placedTeams.toSet(), equals(teamIds.toSet()));
        verify(() => crudService.updateTournamentStatus('tourn-1', TournamentStatus.inProgress)).called(1);
      });

      test('3 deltakere → 2 runder, 3 kamper totalt', () async {
        final teamIds = ['team1', 'team2', 'team3'];
        var roundCounter = 0;
        var matchCounter = 0;

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          roundCounter++;
          return TournamentRound(
            id: 'round-$roundCounter',
            tournamentId: 'tourn-1',
            roundNumber: invocation.namedArguments[#roundNumber] as int,
            roundName: invocation.namedArguments[#roundName] as String?,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          matchCounter++;
          return TournamentMatch(
            id: 'match-$matchCounter',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: invocation.namedArguments[#bracketPosition] as int,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.setWalkover(
          matchId: any(named: 'matchId'),
          winnerId: any(named: 'winnerId'),
          reason: any(named: 'reason'),
        )).thenAnswer((_) async {});

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        final matches = await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
        );

        expect(roundCounter, equals(2));
        expect(matches.length, equals(3)); // 2 første runde + 1 finale
      });

      test('4 deltakere → 2 runder, 3 kamper totalt', () async {
        final teamIds = ['team1', 'team2', 'team3', 'team4'];
        var roundCounter = 0;
        var matchCounter = 0;

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          roundCounter++;
          return TournamentRound(
            id: 'round-$roundCounter',
            tournamentId: 'tourn-1',
            roundNumber: invocation.namedArguments[#roundNumber] as int,
            roundName: invocation.namedArguments[#roundName] as String?,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          matchCounter++;
          return TournamentMatch(
            id: 'match-$matchCounter',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: invocation.namedArguments[#bracketPosition] as int,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        final matches = await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
        );

        expect(roundCounter, equals(2));
        expect(matches.length, equals(3)); // 2 semi + 1 finale
      });

      test('5 deltakere → 3 runder, 6 kamper totalt', () async {
        final teamIds = ['team1', 'team2', 'team3', 'team4', 'team5'];
        var matchCounter = 0;

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          final roundNum = invocation.namedArguments[#roundNumber] as int;
          return TournamentRound(
            id: 'round-$roundNum',
            tournamentId: 'tourn-1',
            roundNumber: roundNum,
            roundName: invocation.namedArguments[#roundName] as String?,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          matchCounter++;
          return TournamentMatch(
            id: 'match-$matchCounter',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: invocation.namedArguments[#bracketPosition] as int,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.setWalkover(
          matchId: any(named: 'matchId'),
          winnerId: any(named: 'winnerId'),
          reason: any(named: 'reason'),
        )).thenAnswer((_) async {});

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        final matches = await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
        );

        expect(matches.length, equals(6)); // 3 første + 2 semi + 1 finale
      });

      test('8 deltakere → 3 runder, 7 kamper totalt', () async {
        final teamIds = List.generate(8, (i) => 'team${i + 1}');
        var matchCounter = 0;

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          final roundNum = invocation.namedArguments[#roundNumber] as int;
          return TournamentRound(
            id: 'round-$roundNum',
            tournamentId: 'tourn-1',
            roundNumber: roundNum,
            roundName: invocation.namedArguments[#roundName] as String?,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          matchCounter++;
          return TournamentMatch(
            id: 'match-$matchCounter',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: invocation.namedArguments[#bracketPosition] as int,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        final matches = await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
        );

        expect(matches.length, equals(7)); // 4 quarter + 2 semi + 1 finale
      });

      test('16 deltakere → 4 runder, 15 kamper totalt', () async {
        final teamIds = List.generate(16, (i) => 'team${i + 1}');
        var matchCounter = 0;

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          final roundNum = invocation.namedArguments[#roundNumber] as int;
          return TournamentRound(
            id: 'round-$roundNum',
            tournamentId: 'tourn-1',
            roundNumber: roundNum,
            roundName: invocation.namedArguments[#roundName] as String?,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          matchCounter++;
          return TournamentMatch(
            id: 'match-$matchCounter',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: invocation.namedArguments[#bracketPosition] as int,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        final matches = await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
        );

        expect(matches.length, equals(15)); // 8 + 4 + 2 + 1
      });
    });

    group('bye handling (odd teams)', () {
      test('3 lag → en kamp får teamBId=null, setWalkover kalles', () async {
        final teamIds = ['team1', 'team2', 'team3'];
        final walkoverCalls = <Map<String, dynamic>>[];

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          final roundNum = invocation.namedArguments[#roundNumber] as int;
          return TournamentRound(
            id: 'round-$roundNum',
            tournamentId: 'tourn-1',
            roundNumber: roundNum,
            roundName: invocation.namedArguments[#roundName] as String?,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          final matchNum = invocation.namedArguments[#bracketPosition] as int;
          return TournamentMatch(
            id: 'match-$matchNum',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: matchNum,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.setWalkover(
          matchId: any(named: 'matchId'),
          winnerId: any(named: 'winnerId'),
          reason: any(named: 'reason'),
        )).thenAnswer((invocation) async {
          walkoverCalls.add({
            'matchId': invocation.namedArguments[#matchId],
            'winnerId': invocation.namedArguments[#winnerId],
            'reason': invocation.namedArguments[#reason],
          });
        });

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
        );

        expect(walkoverCalls.length, equals(1));
        expect(walkoverCalls[0]['reason'], equals('Frirunde'));
      });

      test('5 lag → flere walkovers for byes', () async {
        final teamIds = ['team1', 'team2', 'team3', 'team4', 'team5'];
        var walkoverCount = 0;

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          final roundNum = invocation.namedArguments[#roundNumber] as int;
          return TournamentRound(
            id: 'round-$roundNum',
            tournamentId: 'tourn-1',
            roundNumber: roundNum,
            roundName: invocation.namedArguments[#roundName] as String?,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          final matchNum = invocation.namedArguments[#bracketPosition] as int;
          return TournamentMatch(
            id: 'match-$matchNum',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: matchNum,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.setWalkover(
          matchId: any(named: 'matchId'),
          winnerId: any(named: 'winnerId'),
          reason: any(named: 'reason'),
        )).thenAnswer((_) async {
          walkoverCount++;
        });

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
        );

        expect(walkoverCount, greaterThan(0));
      });
    });

    group('bronze final', () {
      test('bronzeFinal=true → ekstra runde med roundType=bronze opprettes', () async {
        final teamIds = ['team1', 'team2', 'team3', 'team4'];
        final createdRoundTypes = <RoundType>[];

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          final roundNum = invocation.namedArguments[#roundNumber] as int;
          final roundType = invocation.namedArguments[#roundType] as RoundType;
          createdRoundTypes.add(roundType);

          return TournamentRound(
            id: 'round-$roundNum',
            tournamentId: 'tourn-1',
            roundNumber: roundNum,
            roundName: invocation.namedArguments[#roundName] as String?,
            roundType: roundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          final matchNum = invocation.namedArguments[#bracketPosition] as int;
          return TournamentMatch(
            id: 'match-$matchNum',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: matchNum,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.getMatchesForRound(any()))
          .thenAnswer((_) async => [
            TournamentMatch(
              id: 'semi1',
              tournamentId: 'tourn-1',
              roundId: 'round-1',
              bracketPosition: 0,
              createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
            ),
            TournamentMatch(
              id: 'semi2',
              tournamentId: 'tourn-1',
              roundId: 'round-1',
              bracketPosition: 1,
              createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
            ),
          ]);

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
          bronzeFinal: true,
        );

        expect(createdRoundTypes.contains(RoundType.bronze), isTrue);
      });

      test('4 lag med bronzeFinal=true → totalt 4 kamper (2 semi + 1 finale + 1 bronsefinale)', () async {
        final teamIds = ['team1', 'team2', 'team3', 'team4'];
        var matchCounter = 0;

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          final roundNum = invocation.namedArguments[#roundNumber] as int;
          return TournamentRound(
            id: 'round-$roundNum',
            tournamentId: 'tourn-1',
            roundNumber: roundNum,
            roundName: invocation.namedArguments[#roundName] as String?,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          matchCounter++;
          return TournamentMatch(
            id: 'match-$matchCounter',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: invocation.namedArguments[#bracketPosition] as int,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.getMatchesForRound(any()))
          .thenAnswer((_) async => [
            TournamentMatch(
              id: 'semi1',
              tournamentId: 'tourn-1',
              roundId: 'round-1',
              bracketPosition: 0,
              createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
            ),
            TournamentMatch(
              id: 'semi2',
              tournamentId: 'tourn-1',
              roundId: 'round-1',
              bracketPosition: 1,
              createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
            ),
          ]);

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        final matches = await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
          bronzeFinal: true,
        );

        expect(matches.length, equals(4));
      });

      test('bronzeFinal=true → getMatchesForRound kalles for semifinale', () async {
        final teamIds = ['team1', 'team2', 'team3', 'team4'];

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          final roundNum = invocation.namedArguments[#roundNumber] as int;
          return TournamentRound(
            id: 'round-$roundNum',
            tournamentId: 'tourn-1',
            roundNumber: roundNum,
            roundName: invocation.namedArguments[#roundName] as String?,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          return TournamentMatch(
            id: 'match-1',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: invocation.namedArguments[#bracketPosition] as int,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.getMatchesForRound(any()))
          .thenAnswer((_) async => [
            TournamentMatch(
              id: 'semi1',
              tournamentId: 'tourn-1',
              roundId: 'round-1',
              bracketPosition: 0,
              createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
            ),
            TournamentMatch(
              id: 'semi2',
              tournamentId: 'tourn-1',
              roundId: 'round-1',
              bracketPosition: 1,
              createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
            ),
          ]);

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
          bronzeFinal: true,
        );

        verify(() => matchesService.getMatchesForRound(any())).called(1);
      });

      test('bronzeFinal=false → ingen bronsefinale opprettes', () async {
        final teamIds = ['team1', 'team2', 'team3', 'team4'];
        final createdRoundTypes = <RoundType>[];

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          final roundNum = invocation.namedArguments[#roundNumber] as int;
          final roundType = invocation.namedArguments[#roundType] as RoundType;
          createdRoundTypes.add(roundType);

          return TournamentRound(
            id: 'round-$roundNum',
            tournamentId: 'tourn-1',
            roundNumber: roundNum,
            roundName: invocation.namedArguments[#roundName] as String?,
            roundType: roundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          return TournamentMatch(
            id: 'match-1',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: invocation.namedArguments[#bracketPosition] as int,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
          bronzeFinal: false,
        );

        expect(createdRoundTypes.contains(RoundType.bronze), isFalse);
      });
    });

    group('match linking', () {
      test('winner_goes_to_match_id oppdateres for linking mellom runder', () async {
        final teamIds = ['team1', 'team2', 'team3', 'team4'];
        var updateCount = 0;

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          final roundNum = invocation.namedArguments[#roundNumber] as int;
          return TournamentRound(
            id: 'round-$roundNum',
            tournamentId: 'tourn-1',
            roundNumber: roundNum,
            roundName: invocation.namedArguments[#roundName] as String?,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          final pos = invocation.namedArguments[#bracketPosition] as int;
          return TournamentMatch(
            id: 'match-$pos',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: pos,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async {
          updateCount++;
          return [];
        });

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
        );

        expect(updateCount, greaterThan(0));
      });

      test('loser_goes_to_match_id settes for semi→bronze når bronzeFinal=true', () async {
        final teamIds = ['team1', 'team2', 'team3', 'team4'];
        final loserLinkingCalls = <Map<String, dynamic>>[];

        when(() => roundsService.createRound(
          tournamentId: any(named: 'tournamentId'),
          roundNumber: any(named: 'roundNumber'),
          roundName: any(named: 'roundName'),
          roundType: any(named: 'roundType'),
        )).thenAnswer((invocation) async {
          final roundNum = invocation.namedArguments[#roundNumber] as int;
          return TournamentRound(
            id: 'round-$roundNum',
            tournamentId: 'tourn-1',
            roundNumber: roundNum,
            roundName: invocation.namedArguments[#roundName] as String?,
            roundType: invocation.namedArguments[#roundType] as RoundType,
            status: MatchStatus.pending,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.createMatch(
          tournamentId: any(named: 'tournamentId'),
          roundId: any(named: 'roundId'),
          bracketPosition: any(named: 'bracketPosition'),
          teamAId: any(named: 'teamAId'),
          teamBId: any(named: 'teamBId'),
          matchOrder: any(named: 'matchOrder'),
        )).thenAnswer((invocation) async {
          final pos = invocation.namedArguments[#bracketPosition] as int;
          return TournamentMatch(
            id: 'match-$pos',
            tournamentId: 'tourn-1',
            roundId: invocation.namedArguments[#roundId] as String,
            bracketPosition: pos,
            teamAId: invocation.namedArguments[#teamAId] as String?,
            teamBId: invocation.namedArguments[#teamBId] as String?,
            matchOrder: invocation.namedArguments[#matchOrder] as int,
            createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
          );
        });

        when(() => matchesService.getMatchesForRound(any()))
          .thenAnswer((_) async => [
            TournamentMatch(
              id: 'semi1',
              tournamentId: 'tourn-1',
              roundId: 'round-1',
              bracketPosition: 0,
              createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
            ),
            TournamentMatch(
              id: 'semi2',
              tournamentId: 'tourn-1',
              roundId: 'round-1',
              bracketPosition: 1,
              createdAt: DateTime.parse('2026-02-09T10:00:00Z'),
            ),
          ]);

        when(() => client.update(
          'tournament_matches',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((invocation) async {
          final data = invocation.positionalArguments[1] as Map<String, dynamic>;
          if (data.containsKey('loser_goes_to_match_id')) {
            loserLinkingCalls.add({
              'data': data,
              'filters': invocation.namedArguments[#filters],
            });
          }
          return [];
        });

        when(() => crudService.updateTournamentStatus(any(), any()))
          .thenAnswer((_) async {});

        await service.generateSingleEliminationBracket(
          tournamentId: 'tourn-1',
          teamIds: teamIds,
          bronzeFinal: true,
        );

        expect(loserLinkingCalls.length, equals(2)); // 2 semi-finals linked to bronze
      });
    });
  });
}
