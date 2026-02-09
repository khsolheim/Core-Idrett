import '../db/database.dart';
import '../helpers/parsing_helpers.dart';

class UserService {
  final Database _db;

  UserService(this._db);

  /// Fetch users by IDs and return a map of userId -> user data (id, name, avatar_url).
  /// Returns an empty map if [userIds] is empty.
  Future<Map<String, Map<String, dynamic>>> getUserMap(List<String> userIds) async {
    if (userIds.isEmpty) return {};

    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[safeString(u, 'id')] = u;
    }
    return userMap;
  }
}
