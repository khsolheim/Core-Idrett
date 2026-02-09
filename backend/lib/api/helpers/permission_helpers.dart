/// Check if user can manage fines (admin or fine_boss).
bool isFinesManager(Map<String, dynamic> team) {
  return team['user_is_admin'] == true || team['user_is_fine_boss'] == true;
}

/// Check if user is a coach or admin.
bool isCoachOrAdmin(Map<String, dynamic> team) {
  return team['user_is_admin'] == true || team['user_is_coach'] == true;
}
