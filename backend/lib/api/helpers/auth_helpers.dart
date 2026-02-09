import 'package:shelf/shelf.dart';
import '../../services/team_service.dart';

/// Extract userId from request context (set by auth middleware).
String? getUserId(Request request) {
  return request.context['userId'] as String?;
}

/// Verify user is a member of the team. Returns the team map or null.
Future<Map<String, dynamic>?> requireTeamMember(
  TeamService teamService,
  String teamId,
  String userId,
) async {
  return await teamService.getTeamById(teamId, userId);
}

/// Check if user has admin permissions using boolean flag system.
bool isAdmin(Map<String, dynamic> team) {
  return team['user_is_admin'] == true;
}
