import 'dart:math' as math;
import '../db/database.dart';
import '../models/statistics.dart';
import '../helpers/parsing_helpers.dart';

/// Service for managing player ELO ratings
class PlayerRatingService {
  final Database _db;

  PlayerRatingService(this._db);

  Future<PlayerRating?> getPlayerRating(String userId, String teamId) async {
    final result = await _db.client.select(
      'player_ratings',
      filters: {
        'user_id': 'eq.$userId',
        'team_id': 'eq.$teamId',
      },
    );

    if (result.isEmpty) return null;

    // Get user info
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'eq.$userId'},
    );

    final user = users.isNotEmpty ? users.first : <String, dynamic>{};

    return PlayerRating.fromJson({
      ...result.first,
      'user_name': user['name'],
      'user_avatar_url': user['avatar_url'],
    });
  }

  Future<PlayerRating> getOrCreatePlayerRating(String userId, String teamId) async {
    var rating = await getPlayerRating(userId, teamId);
    if (rating != null) return rating;

    // Create new rating
    final result = await _db.client.insert('player_ratings', {
      'user_id': userId,
      'team_id': teamId,
    });

    // Get user info
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'eq.$userId'},
    );

    final user = users.isNotEmpty ? users.first : <String, dynamic>{};

    return PlayerRating.fromJson({
      ...result.first,
      'user_name': user['name'],
      'user_avatar_url': user['avatar_url'],
    });
  }

  Future<void> updateRatingsAfterMatch({
    required String teamId,
    required List<String> winnerIds,
    required List<String> loserIds,
    bool isDraw = false,
  }) async {
    const kFactor = 32.0;

    // Batch fetch all player ratings for participants
    final allPlayerIds = {...winnerIds, ...loserIds}.toList();
    final existingRatings = allPlayerIds.isNotEmpty
        ? await _db.client.select(
            'player_ratings',
            filters: {
              'user_id': 'in.(${allPlayerIds.join(',')})',
              'team_id': 'eq.$teamId',
            },
          )
        : <Map<String, dynamic>>[];

    final ratingsMap = <String, Map<String, dynamic>>{};
    for (final r in existingRatings) {
      ratingsMap[safeString(r, 'user_id')] = r;
    }

    // Ensure all players have ratings (create missing ones)
    for (final playerId in allPlayerIds) {
      if (!ratingsMap.containsKey(playerId)) {
        final rating = await getOrCreatePlayerRating(playerId, teamId);
        ratingsMap[playerId] = {
          'user_id': playerId,
          'team_id': teamId,
          'rating': rating.rating,
          'wins': rating.wins,
          'losses': rating.losses,
          'draws': rating.draws,
        };
      }
    }

    if (isDraw) {
      // Update draws for all participants
      for (final playerId in allPlayerIds) {
        final current = ratingsMap[playerId]!;
        await _db.client.update(
          'player_ratings',
          {'draws': (safeInt(current, 'draws', defaultValue: 0)) + 1},
          filters: {
            'user_id': 'eq.$playerId',
            'team_id': 'eq.$teamId',
          },
        );
      }
      return;
    }

    // Calculate average ratings from batch-fetched data
    double winnerAvg = 0;
    for (final playerId in winnerIds) {
      winnerAvg += (ratingsMap[playerId]!['rating'] as num? ?? 1000).toDouble();
    }
    winnerAvg /= winnerIds.length;

    double loserAvg = 0;
    for (final playerId in loserIds) {
      loserAvg += (ratingsMap[playerId]!['rating'] as num? ?? 1000).toDouble();
    }
    loserAvg /= loserIds.length;

    // Calculate expected scores
    final expectedWinner = 1 / (1 + math.pow(10, (loserAvg - winnerAvg) / 400));
    final expectedLoser = 1 - expectedWinner;

    // Calculate rating changes
    final winnerChange = (kFactor * (1 - expectedWinner)).round();
    final loserChange = (kFactor * (0 - expectedLoser)).round();

    // Update winners
    for (final playerId in winnerIds) {
      final current = ratingsMap[playerId]!;
      await _db.client.update(
        'player_ratings',
        {
          'rating': (current['rating'] as num? ?? 1000) + winnerChange,
          'wins': (safeInt(current, 'wins', defaultValue: 0)) + 1,
        },
        filters: {
          'user_id': 'eq.$playerId',
          'team_id': 'eq.$teamId',
        },
      );
    }

    // Update losers
    for (final playerId in loserIds) {
      final current = ratingsMap[playerId]!;
      final newRating = math.max(100, (current['rating'] as num? ?? 1000) + loserChange);
      await _db.client.update(
        'player_ratings',
        {
          'rating': newRating,
          'losses': (safeInt(current, 'losses', defaultValue: 0)) + 1,
        },
        filters: {
          'user_id': 'eq.$playerId',
          'team_id': 'eq.$teamId',
        },
      );
    }
  }
}
