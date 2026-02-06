/// Factory methods for creating test data
library;

import 'package:core_idrett/data/models/user.dart';
import 'package:core_idrett/data/models/team.dart';
import 'package:core_idrett/data/models/activity.dart';
import 'package:core_idrett/data/models/fine.dart';
import 'package:core_idrett/data/models/message.dart';

/// Factory for creating User test data
class TestUserFactory {
  static int _counter = 0;

  static User create({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    DateTime? birthDate,
    DateTime? createdAt,
  }) {
    _counter++;
    return User(
      id: id ?? 'user-$_counter',
      email: email ?? 'user$_counter@test.com',
      name: name ?? 'Test User $_counter',
      avatarUrl: avatarUrl,
      birthDate: birthDate,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static void reset() => _counter = 0;
}

/// Factory for creating Team test data
class TestTeamFactory {
  static int _counter = 0;

  static Team create({
    String? id,
    String? name,
    String? sport,
    String? inviteCode,
    DateTime? createdAt,
    bool userIsAdmin = false,
    bool userIsFineBoss = false,
    bool userIsCoach = false,
    TrainerType? userTrainerType,
  }) {
    _counter++;
    return Team(
      id: id ?? 'team-$_counter',
      name: name ?? 'Test Team $_counter',
      sport: sport,
      inviteCode: inviteCode ?? 'INVITE$_counter',
      createdAt: createdAt ?? DateTime.now(),
      userIsAdmin: userIsAdmin,
      userIsFineBoss: userIsFineBoss,
      userIsCoach: userIsCoach,
      userTrainerType: userTrainerType,
    );
  }

  static void reset() => _counter = 0;
}

/// Factory for creating TeamMember test data
class TestTeamMemberFactory {
  static int _counter = 0;

  static TeamMember create({
    String? id,
    String? userId,
    String? teamId,
    String? userName,
    String? userAvatarUrl,
    DateTime? userBirthDate,
    bool isAdmin = false,
    bool isFineBoss = false,
    bool isCoach = false,
    TrainerType? trainerType,
    bool isActive = true,
    DateTime? joinedAt,
  }) {
    _counter++;
    return TeamMember(
      id: id ?? 'member-$_counter',
      userId: userId ?? 'user-$_counter',
      teamId: teamId ?? 'team-1',
      userName: userName ?? 'Member $_counter',
      userAvatarUrl: userAvatarUrl,
      userBirthDate: userBirthDate,
      isAdmin: isAdmin,
      isFineBoss: isFineBoss,
      isCoach: isCoach,
      trainerType: trainerType,
      isActive: isActive,
      joinedAt: joinedAt ?? DateTime.now(),
    );
  }

  static void reset() => _counter = 0;
}

/// Factory for creating Activity test data
class TestActivityFactory {
  static int _counter = 0;

  static Activity create({
    String? id,
    String? teamId,
    String? title,
    ActivityType type = ActivityType.training,
    String? location,
    String? description,
    RecurrenceType recurrenceType = RecurrenceType.once,
    DateTime? recurrenceEndDate,
    ResponseType responseType = ResponseType.yesNo,
    int? responseDeadlineHours,
    DateTime? createdAt,
    int? instanceCount,
  }) {
    _counter++;
    return Activity(
      id: id ?? 'activity-$_counter',
      teamId: teamId ?? 'team-1',
      title: title ?? 'Test Activity $_counter',
      type: type,
      location: location,
      description: description,
      recurrenceType: recurrenceType,
      recurrenceEndDate: recurrenceEndDate,
      responseType: responseType,
      responseDeadlineHours: responseDeadlineHours,
      createdAt: createdAt ?? DateTime.now(),
      instanceCount: instanceCount,
    );
  }

  static void reset() => _counter = 0;
}

/// Factory for creating ActivityInstance test data
class TestActivityInstanceFactory {
  static int _counter = 0;

  static ActivityInstance create({
    String? id,
    String? activityId,
    String? teamId,
    DateTime? date,
    String? startTime,
    String? endTime,
    InstanceStatus status = InstanceStatus.scheduled,
    String? cancelledReason,
    String? title,
    ActivityType? type,
    String? location,
    String? description,
    ResponseType? responseType,
    int? responseDeadlineHours,
    List<ActivityResponseItem>? responses,
    UserResponse? userResponse,
    int? yesCount,
    int? noCount,
    int? maybeCount,
  }) {
    _counter++;
    return ActivityInstance(
      id: id ?? 'instance-$_counter',
      activityId: activityId ?? 'activity-1',
      teamId: teamId ?? 'team-1',
      date: date ?? DateTime.now().add(const Duration(days: 1)),
      startTime: startTime ?? '18:00',
      endTime: endTime ?? '20:00',
      status: status,
      cancelledReason: cancelledReason,
      title: title ?? 'Test Instance $_counter',
      type: type ?? ActivityType.training,
      location: location,
      description: description,
      responseType: responseType ?? ResponseType.yesNo,
      responseDeadlineHours: responseDeadlineHours,
      responses: responses,
      userResponse: userResponse,
      yesCount: yesCount ?? 0,
      noCount: noCount ?? 0,
      maybeCount: maybeCount ?? 0,
    );
  }

  static void reset() => _counter = 0;
}

/// Factory for creating Fine test data
class TestFineFactory {
  static int _counter = 0;

  static Fine create({
    String? id,
    String? ruleId,
    String? teamId,
    String? offenderId,
    String? reporterId,
    String? approvedBy,
    String status = 'pending',
    double amount = 50.0,
    String? description,
    String? evidenceUrl,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? offenderName,
    String? offenderAvatarUrl,
    String? reporterName,
    String? ruleName,
    FineAppeal? appeal,
    double? paidAmount,
  }) {
    _counter++;
    return Fine(
      id: id ?? 'fine-$_counter',
      ruleId: ruleId,
      teamId: teamId ?? 'team-1',
      offenderId: offenderId ?? 'user-2',
      reporterId: reporterId ?? 'user-1',
      approvedBy: approvedBy,
      status: status,
      amount: amount,
      description: description ?? 'Test fine $_counter',
      evidenceUrl: evidenceUrl,
      createdAt: createdAt ?? DateTime.now(),
      resolvedAt: resolvedAt,
      offenderName: offenderName ?? 'Offender $_counter',
      offenderAvatarUrl: offenderAvatarUrl,
      reporterName: reporterName ?? 'Reporter',
      ruleName: ruleName,
      appeal: appeal,
      paidAmount: paidAmount,
    );
  }

  static void reset() => _counter = 0;
}

/// Factory for creating FineRule test data
class TestFineRuleFactory {
  static int _counter = 0;

  static FineRule create({
    String? id,
    String? teamId,
    String? name,
    double amount = 50.0,
    String? description,
    bool active = true,
    DateTime? createdAt,
  }) {
    _counter++;
    return FineRule(
      id: id ?? 'rule-$_counter',
      teamId: teamId ?? 'team-1',
      name: name ?? 'Test Rule $_counter',
      amount: amount,
      description: description,
      active: active,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static void reset() => _counter = 0;
}

/// Factory for creating Message test data
class TestMessageFactory {
  static int _counter = 0;

  static Message create({
    String? id,
    String? teamId,
    String? userId,
    String? content,
    String? replyToId,
    bool isEdited = false,
    bool isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userAvatarUrl,
    Message? replyTo,
  }) {
    _counter++;
    final now = DateTime.now();
    return Message(
      id: id ?? 'message-$_counter',
      teamId: teamId ?? 'team-1',
      userId: userId ?? 'user-1',
      content: content ?? 'Test message $_counter',
      replyToId: replyToId,
      isEdited: isEdited,
      isDeleted: isDeleted,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      userName: userName ?? 'User $_counter',
      userAvatarUrl: userAvatarUrl,
      replyTo: replyTo,
    );
  }

  static void reset() => _counter = 0;
}

/// Reset all factories (call in setUp/tearDown)
void resetAllTestFactories() {
  TestUserFactory.reset();
  TestTeamFactory.reset();
  TestTeamMemberFactory.reset();
  TestActivityFactory.reset();
  TestActivityInstanceFactory.reset();
  TestFineFactory.reset();
  TestFineRuleFactory.reset();
  TestMessageFactory.reset();
}
