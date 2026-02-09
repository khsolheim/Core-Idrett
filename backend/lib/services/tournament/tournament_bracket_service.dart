import '../../db/database.dart';
import '../../models/tournament.dart';
import 'tournament_crud_service.dart';
import 'tournament_rounds_service.dart';
import 'tournament_matches_service.dart';
import '../tournament_group_service.dart';

class TournamentBracketService {
  final Database _db;
  final TournamentCrudService _crudService;
  final TournamentRoundsService _roundsService;
  final TournamentMatchesService _matchesService;
  final TournamentGroupService _groupService;

  TournamentBracketService(
    this._db,
    this._crudService,
    this._roundsService,
    this._matchesService,
    this._groupService,
  );

  // ============ BRACKET GENERATION ============

  /// Generate a single elimination bracket
  Future<List<TournamentMatch>> generateSingleEliminationBracket({
    required String tournamentId,
    required List<String> teamIds,
    bool bronzeFinal = false,
  }) async {
    final allMatches = <TournamentMatch>[];
    final numTeams = teamIds.length;

    // Calculate number of rounds needed
    int numRounds = 0;
    int teamsInRound = numTeams;
    while (teamsInRound > 1) {
      numRounds++;
      teamsInRound = (teamsInRound / 2).ceil();
    }

    // Generate round names
    final roundNames = _generateRoundNames(numRounds, bronzeFinal);

    // Create rounds
    final rounds = <TournamentRound>[];
    for (int i = 0; i < numRounds; i++) {
      final round = await _roundsService.createRound(
        tournamentId: tournamentId,
        roundNumber: i + 1,
        roundName: roundNames[i],
        roundType: RoundType.winners,
      );
      rounds.add(round);
    }

    // Create bronze round if needed
    TournamentRound? bronzeRound;
    if (bronzeFinal && numRounds >= 2) {
      bronzeRound = await _roundsService.createRound(
        tournamentId: tournamentId,
        roundNumber: numRounds,
        roundName: 'Bronsefinale',
        roundType: RoundType.bronze,
      );
    }

    // Create matches for first round
    final firstRound = rounds.first;
    final matchesInFirstRound = (numTeams / 2).ceil();
    final firstRoundMatches = <TournamentMatch>[];

    for (int i = 0; i < matchesInFirstRound; i++) {
      final teamAIndex = i * 2;
      final teamBIndex = i * 2 + 1;

      final match = await _matchesService.createMatch(
        tournamentId: tournamentId,
        roundId: firstRound.id,
        bracketPosition: i,
        teamAId: teamAIndex < teamIds.length ? teamIds[teamAIndex] : null,
        teamBId: teamBIndex < teamIds.length ? teamIds[teamBIndex] : null,
        matchOrder: i,
      );
      firstRoundMatches.add(match);
      allMatches.add(match);

      // If only one team, auto-advance
      if (match.teamAId != null && match.teamBId == null) {
        await _matchesService.setWalkover(
          matchId: match.id,
          winnerId: match.teamAId!,
          reason: 'Frirunde',
        );
      }
    }

    // Create matches for subsequent rounds and link them
    var previousRoundMatches = firstRoundMatches;
    for (int r = 1; r < rounds.length; r++) {
      final round = rounds[r];
      final matchesInRound = (previousRoundMatches.length / 2).ceil();
      final currentRoundMatches = <TournamentMatch>[];

      for (int i = 0; i < matchesInRound; i++) {
        final match = await _matchesService.createMatch(
          tournamentId: tournamentId,
          roundId: round.id,
          bracketPosition: i,
          matchOrder: i,
        );
        currentRoundMatches.add(match);
        allMatches.add(match);
      }

      // Link previous round matches to this round
      for (int i = 0; i < previousRoundMatches.length; i += 2) {
        final targetMatchIndex = i ~/ 2;
        if (targetMatchIndex < currentRoundMatches.length) {
          // Update winner_goes_to_match_id
          await _db.client.update(
            'tournament_matches',
            {'winner_goes_to_match_id': currentRoundMatches[targetMatchIndex].id},
            filters: {'id': 'eq.${previousRoundMatches[i].id}'},
          );
          if (i + 1 < previousRoundMatches.length) {
            await _db.client.update(
              'tournament_matches',
              {'winner_goes_to_match_id': currentRoundMatches[targetMatchIndex].id},
              filters: {'id': 'eq.${previousRoundMatches[i + 1].id}'},
            );
          }
        }
      }

      previousRoundMatches = currentRoundMatches;
    }

    // Link semi-finals to bronze final if needed
    if (bronzeRound != null && rounds.length >= 2) {
      final semiFinalRound = rounds[rounds.length - 2];
      final semiFinalMatches = await _matchesService.getMatchesForRound(semiFinalRound.id);

      // Create bronze match
      final bronzeMatch = await _matchesService.createMatch(
        tournamentId: tournamentId,
        roundId: bronzeRound.id,
        bracketPosition: 0,
        matchOrder: 0,
      );
      allMatches.add(bronzeMatch);

      // Link losers to bronze
      for (final match in semiFinalMatches) {
        await _db.client.update(
          'tournament_matches',
          {'loser_goes_to_match_id': bronzeMatch.id},
          filters: {'id': 'eq.${match.id}'},
        );
      }
    }

    // Update tournament status
    await _crudService.updateTournamentStatus(tournamentId, TournamentStatus.inProgress);

    return allMatches;
  }

  List<String> _generateRoundNames(int numRounds, bool hasBronze) {
    final names = <String>[];

    for (int i = numRounds; i > 0; i--) {
      if (i == 1) {
        names.insert(0, 'Finale');
      } else if (i == 2) {
        names.insert(0, 'Semifinale');
      } else if (i == 3) {
        names.insert(0, 'Kvartfinale');
      } else if (i == 4) {
        names.insert(0, '8-delsfinale');
      } else if (i == 5) {
        names.insert(0, '16-delsfinale');
      } else {
        names.insert(0, 'Runde ${numRounds - i + 1}');
      }
    }

    return names;
  }

  // ============ TOURNAMENT DETAIL ============

  Future<Map<String, dynamic>?> getTournamentDetail(String tournamentId) async {
    final tournament = await _crudService.getTournamentById(tournamentId);
    if (tournament == null) return null;

    final rounds = await _roundsService.getRoundsForTournament(tournamentId);
    final matches = await _matchesService.getMatchesForTournament(tournamentId);
    final groups = await _groupService.getGroupsForTournament(tournamentId);

    // Get standings for each group
    final groupsWithStandings = <Map<String, dynamic>>[];
    for (final group in groups) {
      final standings = await _groupService.getGroupStandings(group.id);
      final groupMatches = await _groupService.getGroupMatches(group.id);
      groupsWithStandings.add({
        ...group.toJson(),
        'standings': standings.map((s) => s.toJson()).toList(),
        'matches': groupMatches.map((m) => m.toJson()).toList(),
      });
    }

    // Organize matches by round
    final roundsWithMatches = rounds.map((r) {
      final roundMatches = matches.where((m) => m.roundId == r.id).toList();
      return {
        ...r.toJson(),
        'matches': roundMatches.map((m) => m.toJson()).toList(),
      };
    }).toList();

    return {
      ...tournament.toJson(),
      'rounds': roundsWithMatches,
      'groups': groupsWithStandings,
    };
  }
}
