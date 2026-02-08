/// Test data factories for backend models
/// Provides realistic Norwegian test data for unit and integration tests

import '../../lib/models/absence.dart';
import '../../lib/models/activity.dart';
import '../../lib/models/fine.dart';
import '../../lib/models/message.dart';
import '../../lib/models/season.dart';
import '../../lib/models/team.dart';
import '../../lib/models/user.dart';

/// Norwegian names for realistic test data
class NorwegianNames {
  static const firstNames = [
    'Lars',
    'Emma',
    'Magnus',
    'Ingrid',
    'Ole',
    'Sofie',
    'Erik',
    'Nora',
    'Knut',
    'Astrid',
    'Jonas',
    'Hedda',
    'Sven',
    'Maren',
    'Henrik',
    'Thea',
  ];

  static const lastNames = [
    'Hansen',
    'Johansen',
    'Olsen',
    'Larsen',
    'Andersen',
    'Pedersen',
    'Nilsen',
    'Kristiansen',
    'Jensen',
    'Karlsen',
    'Eriksen',
    'Berg',
    'Haugen',
    'Hagen',
    'Solberg',
    'Strand',
  ];

  static String fullName(int seed) {
    final firstIdx = seed % firstNames.length;
    final lastIdx = (seed ~/ firstNames.length) % lastNames.length;
    return '${firstNames[firstIdx]} ${lastNames[lastIdx]}';
  }
}

/// Test data factory for User model
class TestUsers {
  static User create({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    final userId = id ?? 'user-${DateTime.now().millisecondsSinceEpoch}';
    return User(
      id: userId,
      email: email ?? '${name ?? 'test'}@example.com',
      name: name ?? NorwegianNames.fullName(userId.hashCode),
      avatarUrl: avatarUrl,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static List<User> createMany(int count) {
    return List.generate(
      count,
      (i) => create(
        id: 'user-$i',
        name: NorwegianNames.fullName(i),
        email: '${NorwegianNames.fullName(i).toLowerCase().replaceAll(' ', '.')}@example.com',
      ),
    );
  }
}

/// Test data factory for Team model
class TestTeams {
  static Team create({
    String? id,
    String? name,
    String? sport,
    String? inviteCode,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? 'team-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test Lag',
      sport: sport ?? 'Fotball',
      inviteCode: inviteCode ?? 'TEST123',
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static TrainerType createTrainerType({
    String? id,
    String? teamId,
    String? name,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return TrainerType(
      id: id ?? 'trainer-type-${DateTime.now().millisecondsSinceEpoch}',
      teamId: teamId ?? 'team-1',
      name: name ?? 'Hovedtrener',
      displayOrder: displayOrder ?? 1,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static TeamMember createMember({
    String? id,
    String? userId,
    String? teamId,
    String? role,
    bool? isAdmin,
    bool? isFineBoss,
    bool? isCoach,
    String? trainerTypeId,
    String? trainerTypeName,
    bool? isActive,
    bool? isInjured,
    DateTime? joinedAt,
  }) {
    return TeamMember(
      id: id ?? 'member-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId ?? 'user-1',
      teamId: teamId ?? 'team-1',
      role: role ?? 'player',
      isAdmin: isAdmin ?? false,
      isFineBoss: isFineBoss ?? false,
      isCoach: isCoach ?? false,
      trainerTypeId: trainerTypeId,
      trainerTypeName: trainerTypeName,
      isActive: isActive ?? true,
      isInjured: isInjured ?? false,
      joinedAt: joinedAt ?? DateTime.now(),
    );
  }
}

/// Test data factory for Activity models
class TestActivities {
  static Activity create({
    String? id,
    String? teamId,
    String? title,
    String? type,
    String? location,
    String? description,
    String? recurrenceType,
    DateTime? recurrenceEndDate,
    String? responseType,
    int? responseDeadlineHours,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? 'activity-${DateTime.now().millisecondsSinceEpoch}',
      teamId: teamId ?? 'team-1',
      title: title ?? 'Trening',
      type: type ?? 'training',
      location: location ?? 'Kunstgressbanen',
      description: description,
      recurrenceType: recurrenceType ?? 'once',
      recurrenceEndDate: recurrenceEndDate,
      responseType: responseType ?? 'yes_no',
      responseDeadlineHours: responseDeadlineHours ?? 24,
      createdBy: createdBy,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static ActivityInstance createInstance({
    String? id,
    String? activityId,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? status,
    String? cancelledReason,
  }) {
    return ActivityInstance(
      id: id ?? 'instance-${DateTime.now().millisecondsSinceEpoch}',
      activityId: activityId ?? 'activity-1',
      date: date ?? DateTime.now(),
      startTime: startTime ?? '18:00',
      endTime: endTime ?? '20:00',
      status: status ?? 'scheduled',
      cancelledReason: cancelledReason,
    );
  }

  static ActivityResponse createResponse({
    String? id,
    String? instanceId,
    String? userId,
    String? response,
    String? comment,
    DateTime? respondedAt,
  }) {
    return ActivityResponse(
      id: id ?? 'response-${DateTime.now().millisecondsSinceEpoch}',
      instanceId: instanceId ?? 'instance-1',
      userId: userId ?? 'user-1',
      response: response ?? 'yes',
      comment: comment,
      respondedAt: respondedAt ?? DateTime.now(),
    );
  }
}

/// Test data factory for Fine models
class TestFines {
  static FineRule createRule({
    String? id,
    String? teamId,
    String? name,
    double? amount,
    String? description,
    bool? active,
    DateTime? createdAt,
  }) {
    return FineRule(
      id: id ?? 'rule-${DateTime.now().millisecondsSinceEpoch}',
      teamId: teamId ?? 'team-1',
      name: name ?? 'For sent til trening',
      amount: amount ?? 50.0,
      description: description,
      active: active ?? true,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static Fine create({
    String? id,
    String? ruleId,
    String? teamId,
    String? offenderId,
    String? reporterId,
    String? approvedBy,
    String? status,
    double? amount,
    String? description,
    String? evidenceUrl,
    bool? isGameDay,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return Fine(
      id: id ?? 'fine-${DateTime.now().millisecondsSinceEpoch}',
      ruleId: ruleId,
      teamId: teamId ?? 'team-1',
      offenderId: offenderId ?? 'user-1',
      reporterId: reporterId ?? 'user-2',
      approvedBy: approvedBy,
      status: status ?? 'pending',
      amount: amount ?? 50.0,
      description: description,
      evidenceUrl: evidenceUrl,
      isGameDay: isGameDay ?? false,
      createdAt: createdAt ?? DateTime.now(),
      resolvedAt: resolvedAt,
    );
  }
}

/// Test data factory for Season models
class TestSeasons {
  static Season create({
    String? id,
    String? teamId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Season(
      id: id ?? 'season-${DateTime.now().millisecondsSinceEpoch}',
      teamId: teamId ?? 'team-1',
      name: name ?? '2024 Vårsesong',
      startDate: startDate ?? DateTime(2024, 1, 1),
      endDate: endDate ?? DateTime(2024, 6, 30),
      isActive: isActive ?? true,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static Leaderboard createLeaderboard({
    String? id,
    String? teamId,
    String? seasonId,
    String? name,
    String? description,
    bool? isMain,
    int? sortOrder,
    LeaderboardCategory? category,
    DateTime? createdAt,
  }) {
    return Leaderboard(
      id: id ?? 'leaderboard-${DateTime.now().millisecondsSinceEpoch}',
      teamId: teamId ?? 'team-1',
      seasonId: seasonId,
      name: name ?? 'Hovedtabell',
      description: description,
      isMain: isMain ?? true,
      sortOrder: sortOrder ?? 0,
      category: category ?? LeaderboardCategory.total,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}

/// Test data factory for Message model
class TestMessages {
  static Message create({
    String? id,
    String? teamId,
    String? recipientId,
    String? userId,
    String? content,
    String? replyToId,
    bool? isEdited,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return Message(
      id: id ?? 'message-${now.millisecondsSinceEpoch}',
      teamId: teamId,
      recipientId: recipientId,
      userId: userId ?? 'user-1',
      content: content ?? 'Test melding',
      replyToId: replyToId,
      isEdited: isEdited ?? false,
      isDeleted: isDeleted ?? false,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }
}

/// Test data factory for Absence models
class TestAbsences {
  static AbsenceCategory createCategory({
    String? id,
    String? teamId,
    String? name,
    String? description,
    bool? requiresApproval,
    bool? countsAsValid,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return AbsenceCategory(
      id: id ?? 'category-${DateTime.now().millisecondsSinceEpoch}',
      teamId: teamId ?? 'team-1',
      name: name ?? 'Syk',
      description: description,
      requiresApproval: requiresApproval ?? false,
      countsAsValid: countsAsValid ?? true,
      isActive: isActive ?? true,
      sortOrder: sortOrder ?? 0,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static AbsenceRecord createRecord({
    String? id,
    String? userId,
    String? instanceId,
    String? categoryId,
    String? reason,
    AbsenceStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return AbsenceRecord(
      id: id ?? 'absence-${now.millisecondsSinceEpoch}',
      userId: userId ?? 'user-1',
      instanceId: instanceId ?? 'instance-1',
      categoryId: categoryId,
      reason: reason,
      status: status ?? AbsenceStatus.pending,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      rejectionReason: rejectionReason,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }
}
