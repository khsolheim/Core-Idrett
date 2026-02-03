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

// Team members with inactive provider (admin only)
final teamMembersWithInactiveProvider = FutureProvider.family<List<TeamMember>, String>((ref, teamId) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getTeamMembers(teamId, includeInactive: true);
});

// Trainer types provider
final trainerTypesProvider = FutureProvider.family<List<TrainerType>, String>((ref, teamId) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getTrainerTypes(teamId);
});

// Team settings provider
final teamSettingsProvider = FutureProvider.family<TeamSettings, String>((ref, teamId) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getTeamSettings(teamId);
});

// Team actions
class TeamNotifier extends Notifier<AsyncValue<Team?>> {
  late final TeamRepository _repo;

  @override
  AsyncValue<Team?> build() {
    _repo = ref.watch(teamRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<Team?> createTeam({
    required String name,
    String? sport,
  }) async {
    state = const AsyncValue.loading();
    try {
      final team = await _repo.createTeam(name: name, sport: sport);
      state = AsyncValue.data(team);
      ref.invalidate(teamsProvider);
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

  /// @deprecated Use updateMemberPermissions instead
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
      ref.invalidate(teamMembersProvider(teamId));
      ref.invalidate(teamMembersWithInactiveProvider(teamId));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update member permissions with the new flag-based system
  Future<bool> updateMemberPermissions({
    required String teamId,
    required String memberId,
    bool? isAdmin,
    bool? isFineBoss,
    bool? isCoach,
    String? trainerTypeId,
    bool clearTrainerType = false,
  }) async {
    try {
      await _repo.updateMemberPermissions(
        teamId: teamId,
        memberId: memberId,
        isAdmin: isAdmin,
        isFineBoss: isFineBoss,
        isCoach: isCoach,
        trainerTypeId: trainerTypeId,
        clearTrainerType: clearTrainerType,
      );
      ref.invalidate(teamMembersProvider(teamId));
      ref.invalidate(teamMembersWithInactiveProvider(teamId));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deactivate a member (soft delete)
  Future<bool> deactivateMember(String teamId, String memberId) async {
    try {
      await _repo.deactivateMember(teamId, memberId);
      ref.invalidate(teamMembersProvider(teamId));
      ref.invalidate(teamMembersWithInactiveProvider(teamId));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reactivate a previously deactivated member
  Future<bool> reactivateMember(String teamId, String memberId) async {
    try {
      await _repo.reactivateMember(teamId, memberId);
      ref.invalidate(teamMembersProvider(teamId));
      ref.invalidate(teamMembersWithInactiveProvider(teamId));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove a member completely (hard delete)
  Future<bool> removeMember(String teamId, String memberId) async {
    try {
      await _repo.removeMember(teamId, memberId);
      ref.invalidate(teamMembersProvider(teamId));
      ref.invalidate(teamMembersWithInactiveProvider(teamId));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Set whether a member is injured
  /// When injured: future opt_out activity responses are removed
  /// When healthy: 'yes' responses are created for future opt_out activities
  Future<bool> setInjuredStatus(String teamId, String memberId, bool isInjured) async {
    try {
      await _repo.setMemberInjuredStatus(teamId, memberId, isInjured);
      ref.invalidate(teamMembersProvider(teamId));
      ref.invalidate(teamMembersWithInactiveProvider(teamId));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create a new trainer type
  Future<TrainerType?> createTrainerType({
    required String teamId,
    required String name,
  }) async {
    try {
      final trainerType = await _repo.createTrainerType(teamId: teamId, name: name);
      ref.invalidate(trainerTypesProvider(teamId));
      return trainerType;
    } catch (e) {
      return null;
    }
  }

  /// Delete a trainer type
  Future<bool> deleteTrainerType(String teamId, String trainerTypeId) async {
    try {
      await _repo.deleteTrainerType(teamId, trainerTypeId);
      ref.invalidate(trainerTypesProvider(teamId));
      ref.invalidate(teamMembersProvider(teamId));
      ref.invalidate(teamMembersWithInactiveProvider(teamId));
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
      ref.invalidate(teamsProvider);
      ref.invalidate(teamDetailProvider(teamId));
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
    double? appealFee,
    double? gameDayMultiplier,
  }) async {
    try {
      final settings = await _repo.updateTeamSettings(
        teamId: teamId,
        attendancePoints: attendancePoints,
        winPoints: winPoints,
        drawPoints: drawPoints,
        lossPoints: lossPoints,
        appealFee: appealFee,
        gameDayMultiplier: gameDayMultiplier,
      );
      ref.invalidate(teamSettingsProvider(teamId));
      return settings;
    } catch (e) {
      return null;
    }
  }
}

final teamNotifierProvider = NotifierProvider<TeamNotifier, AsyncValue<Team?>>(() {
  return TeamNotifier();
});
