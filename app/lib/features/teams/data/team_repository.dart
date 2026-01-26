import '../../../data/api/api_client.dart';
import '../../../data/models/team.dart';

class TeamRepository {
  final ApiClient _client;

  TeamRepository(this._client);

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

  Future<List<TeamMember>> getTeamMembers(String teamId) async {
    final response = await _client.get('/teams/$teamId/members');
    final data = response.data['members'] as List;
    return data.map((e) => TeamMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> generateInviteCode(String teamId) async {
    final response = await _client.post('/teams/$teamId/invite');
    return response.data['invite_code'] as String;
  }

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

  Future<void> removeMember(String teamId, String memberId) async {
    await _client.delete('/teams/$teamId/members/$memberId');
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
  }) async {
    final response = await _client.patch(
      '/teams/$teamId/settings',
      data: {
        if (attendancePoints != null) 'attendance_points': attendancePoints,
        if (winPoints != null) 'win_points': winPoints,
        if (drawPoints != null) 'draw_points': drawPoints,
        if (lossPoints != null) 'loss_points': lossPoints,
      },
    );
    return TeamSettings.fromJson(response.data as Map<String, dynamic>);
  }
}
