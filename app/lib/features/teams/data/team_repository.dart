import '../../../data/api/api_client.dart';
import '../../../data/models/team.dart';

class TeamRepository {
  final ApiClient _client;

  TeamRepository(this._client);

  // ============ Teams ============

  Future<List<Team>> getTeams() async {
    final response = await _client.get('/teams');
    final data = response.data as List;
    return data.map((e) => Team.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Team> getTeam(String teamId) async {
    final response = await _client.get('/teams/$teamId');
    return Team.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Team> createTeam({
    required String name,
    String? sport,
  }) async {
    final response = await _client.post(
      '/teams',
      data: {
        'name': name,
        if (sport != null) 'sport': sport,
      },
    );
    return Team.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Team> updateTeam({
    required String teamId,
    String? name,
    String? sport,
  }) async {
    final response = await _client.patch(
      '/teams/$teamId',
      data: {
        if (name != null) 'name': name,
        if (sport != null) 'sport': sport,
      },
    );
    return Team.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> generateInviteCode(String teamId) async {
    final response = await _client.post('/teams/$teamId/invite');
    return response.data['invite_code'] as String;
  }

  // ============ Team Members ============

  Future<List<TeamMember>> getTeamMembers(String teamId, {bool includeInactive = false}) async {
    final response = await _client.get(
      '/teams/$teamId/members',
      queryParameters: {
        if (includeInactive) 'include_inactive': 'true',
      },
    );
    final data = response.data as List;
    return data.map((e) => TeamMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// @deprecated Use updateMemberPermissions instead
  Future<void> updateMemberRole({
    required String teamId,
    required String memberId,
    required TeamRole role,
  }) async {
    await _client.patch(
      '/teams/$teamId/members/$memberId/role',
      data: {'role': role.toApiString()},
    );
  }

  /// Update member permissions with the new flag-based system
  Future<void> updateMemberPermissions({
    required String teamId,
    required String memberId,
    bool? isAdmin,
    bool? isFineBoss,
    bool? isCoach,
    String? trainerTypeId,
    bool clearTrainerType = false,
  }) async {
    await _client.patch(
      '/teams/$teamId/members/$memberId/permissions',
      data: {
        if (isAdmin != null) 'is_admin': isAdmin,
        if (isFineBoss != null) 'is_fine_boss': isFineBoss,
        if (isCoach != null) 'is_coach': isCoach,
        if (clearTrainerType)
          'trainer_type_id': null
        else if (trainerTypeId != null)
          'trainer_type_id': trainerTypeId,
      },
    );
  }

  /// Deactivate a member (soft delete)
  Future<void> deactivateMember(String teamId, String memberId) async {
    await _client.post('/teams/$teamId/members/$memberId/deactivate');
  }

  /// Reactivate a previously deactivated member
  Future<void> reactivateMember(String teamId, String memberId) async {
    await _client.post('/teams/$teamId/members/$memberId/reactivate');
  }

  /// Remove a member completely (hard delete)
  Future<void> removeMember(String teamId, String memberId) async {
    await _client.delete('/teams/$teamId/members/$memberId');
  }

  // ============ Trainer Types ============

  Future<List<TrainerType>> getTrainerTypes(String teamId) async {
    final response = await _client.get('/teams/$teamId/trainer-types');
    final data = response.data as List;
    return data.map((e) => TrainerType.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TrainerType> createTrainerType({
    required String teamId,
    required String name,
  }) async {
    final response = await _client.post(
      '/teams/$teamId/trainer-types',
      data: {'name': name},
    );
    return TrainerType.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTrainerType(String teamId, String trainerTypeId) async {
    await _client.delete('/teams/$teamId/trainer-types/$trainerTypeId');
  }

  // ============ Team Settings ============

  Future<TeamSettings> getTeamSettings(String teamId) async {
    final response = await _client.get('/teams/$teamId/settings');
    return TeamSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TeamSettings> updateTeamSettings({
    required String teamId,
    int? attendancePoints,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    double? appealFee,
    double? gameDayMultiplier,
  }) async {
    final response = await _client.patch(
      '/teams/$teamId/settings',
      data: {
        if (attendancePoints != null) 'attendance_points': attendancePoints,
        if (winPoints != null) 'win_points': winPoints,
        if (drawPoints != null) 'draw_points': drawPoints,
        if (lossPoints != null) 'loss_points': lossPoints,
        if (appealFee != null) 'appeal_fee': appealFee,
        if (gameDayMultiplier != null) 'game_day_multiplier': gameDayMultiplier,
      },
    );
    return TeamSettings.fromJson(response.data as Map<String, dynamic>);
  }
}
