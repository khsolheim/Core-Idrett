import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/team.dart';
import '../data/team_repository.dart';

// Repository provider
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return TeamRepository(client);
});

// Teams list provider
final teamsProvider = FutureProvider<List<Team>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getTeams();
});

// Team detail provider
final teamDetailProvider = FutureProvider.family<Team?, String>((ref, teamId) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getTeam(teamId);
});

// Team members provider
final teamMembersProvider = FutureProvider.family<List<TeamMember>, String>((ref, teamId) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getTeamMembers(teamId);
});

// Team settings provider
final teamSettingsProvider = FutureProvider.family<TeamSettings, String>((ref, teamId) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getTeamSettings(teamId);
});

// Team actions
class TeamNotifier extends StateNotifier<AsyncValue<Team?>> {
  final TeamRepository _repo;
  final Ref _ref;

  TeamNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<Team?> createTeam({
    required String name,
    String? sport,
  }) async {
    state = const AsyncValue.loading();
    try {
      final team = await _repo.createTeam(name: name, sport: sport);
      state = AsyncValue.data(team);
      _ref.invalidate(teamsProvider);
      return team;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<String?> generateInviteCode(String teamId) async {
    try {
      return await _repo.generateInviteCode(teamId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateMemberRole({
    required String teamId,
    required String memberId,
    required TeamRole role,
  }) async {
    try {
      await _repo.updateMemberRole(
        teamId: teamId,
        memberId: memberId,
        role: role,
      );
      _ref.invalidate(teamMembersProvider(teamId));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeMember(String teamId, String memberId) async {
    try {
      await _repo.removeMember(teamId, memberId);
      _ref.invalidate(teamMembersProvider(teamId));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Team?> updateTeam({
    required String teamId,
    String? name,
    String? sport,
  }) async {
    try {
      final team = await _repo.updateTeam(teamId: teamId, name: name, sport: sport);
      _ref.invalidate(teamsProvider);
      _ref.invalidate(teamDetailProvider(teamId));
      return team;
    } catch (e) {
      return null;
    }
  }

  Future<TeamSettings?> updateTeamSettings({
    required String teamId,
    int? attendancePoints,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
  }) async {
    try {
      final settings = await _repo.updateTeamSettings(
        teamId: teamId,
        attendancePoints: attendancePoints,
        winPoints: winPoints,
        drawPoints: drawPoints,
        lossPoints: lossPoints,
      );
      _ref.invalidate(teamSettingsProvider(teamId));
      return settings;
    } catch (e) {
      return null;
    }
  }
}

final teamNotifierProvider = StateNotifierProvider<TeamNotifier, AsyncValue<Team?>>((ref) {
  final repo = ref.watch(teamRepositoryProvider);
  return TeamNotifier(repo, ref);
});
