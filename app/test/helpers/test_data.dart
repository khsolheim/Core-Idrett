/// Factory methods for creating test data with realistic Norwegian names
library;

import 'package:core_idrett/data/models/user.dart';
import 'package:core_idrett/data/models/team.dart';
import 'package:core_idrett/data/models/activity.dart';
import 'package:core_idrett/data/models/fine.dart';
import 'package:core_idrett/data/models/message.dart';
import 'package:core_idrett/data/models/conversation.dart';
import 'package:core_idrett/data/models/document.dart';
import 'package:core_idrett/data/models/absence.dart';

/// Norwegian names for cycling through test data
const _norwegianNames = [
  'Ola Nordmann',
  'Kari Hansen',
  'Per Olsen',
  'Lise Andersen',
  'Erik Johansen',
  'Maria Nilsen',
  'Jonas Berg',
  'Ingrid Dahl',
  'Anders Moen',
  'Sofie Haugen',
];

/// Norwegian team names for cycling
const _norwegianTeams = [
  'Rosenborg BK',
  'Brann FK',
  'Viking FK',
  'Molde FK',
  'Vålerenga IF',
];

/// Deterministic base timestamp (2024-01-15 10:00:00 UTC)
final _baseTime = DateTime.parse('2024-01-15T10:00:00Z');

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
    final norwegianName = _norwegianNames[(_counter - 1) % _norwegianNames.length];
    final emailPrefix = norwegianName.toLowerCase().replaceAll(' ', '.');
    return User(
      id: id ?? 'user-$_counter',
      email: email ?? '$emailPrefix$_counter@example.no',
      name: name ?? norwegianName,
      avatarUrl: avatarUrl,
      birthDate: birthDate,
      createdAt: createdAt ?? _baseTime,
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
      name: name ?? _norwegianTeams[(_counter - 1) % _norwegianTeams.length],
      sport: sport ?? 'Fotball',
      inviteCode: inviteCode ?? 'INVITE$_counter',
      createdAt: createdAt ?? _baseTime,
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
    bool isInjured = false,
    DateTime? joinedAt,
  }) {
    _counter++;
    final norwegianName = _norwegianNames[(_counter - 1) % _norwegianNames.length];
    return TeamMember(
      id: id ?? 'member-$_counter',
      userId: userId ?? 'user-$_counter',
      teamId: teamId ?? 'team-1',
      userName: userName ?? norwegianName,
      userAvatarUrl: userAvatarUrl,
      userBirthDate: userBirthDate,
      isAdmin: isAdmin,
      isFineBoss: isFineBoss,
      isCoach: isCoach,
      trainerType: trainerType,
      isActive: isActive,
      isInjured: isInjured,
      joinedAt: joinedAt ?? _baseTime,
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
      title: title ?? (type == ActivityType.match ? 'Kamp $_counter' : 'Trening $_counter'),
      type: type,
      location: location ?? 'Lade Arena',
      description: description,
      recurrenceType: recurrenceType,
      recurrenceEndDate: recurrenceEndDate,
      responseType: responseType,
      responseDeadlineHours: responseDeadlineHours,
      createdAt: createdAt ?? _baseTime,
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
      date: date ?? _baseTime.add(Duration(days: _counter)),
      startTime: startTime ?? '18:00',
      endTime: endTime ?? '20:00',
      status: status,
      cancelledReason: cancelledReason,
      title: title ?? 'Treningsøkt $_counter',
      type: type ?? ActivityType.training,
      location: location ?? 'Lade Arena',
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
    bool isGameDay = false,
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
    final fineReasons = ['For sent til trening', 'Glemt utstyr', 'Ulovlig takling'];
    return Fine(
      id: id ?? 'fine-$_counter',
      ruleId: ruleId,
      teamId: teamId ?? 'team-1',
      offenderId: offenderId ?? 'user-2',
      reporterId: reporterId ?? 'user-1',
      approvedBy: approvedBy,
      status: status,
      amount: amount,
      description: description ?? fineReasons[(_counter - 1) % fineReasons.length],
      evidenceUrl: evidenceUrl,
      isGameDay: isGameDay,
      createdAt: createdAt ?? _baseTime,
      resolvedAt: resolvedAt,
      offenderName: offenderName ?? _norwegianNames[1],
      offenderAvatarUrl: offenderAvatarUrl,
      reporterName: reporterName ?? _norwegianNames[0],
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
    final ruleNames = ['For sent til trening', 'Glemt drakt', 'Mobilbruk under trening'];
    return FineRule(
      id: id ?? 'rule-$_counter',
      teamId: teamId ?? 'team-1',
      name: name ?? ruleNames[(_counter - 1) % ruleNames.length],
      amount: amount,
      description: description,
      active: active,
      createdAt: createdAt ?? _baseTime,
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
    String? recipientId,
    String? userId,
    String? content,
    String? replyToId,
    bool isEdited = false,
    bool isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userAvatarUrl,
    String? recipientName,
    String? recipientAvatarUrl,
    Message? replyTo,
  }) {
    _counter++;
    return Message(
      id: id ?? 'message-$_counter',
      teamId: teamId,
      recipientId: recipientId,
      userId: userId ?? 'user-1',
      content: content ?? 'Melding $_counter',
      replyToId: replyToId,
      isEdited: isEdited,
      isDeleted: isDeleted,
      createdAt: createdAt ?? _baseTime,
      updatedAt: updatedAt ?? _baseTime,
      userName: userName ?? _norwegianNames[0],
      userAvatarUrl: userAvatarUrl,
      recipientName: recipientName,
      recipientAvatarUrl: recipientAvatarUrl,
      replyTo: replyTo,
    );
  }

  static void reset() => _counter = 0;
}

/// Factory for creating ChatConversation test data
class TestConversationFactory {
  static ChatConversation create({
    ConversationType type = ConversationType.team,
    String? teamId,
    String? recipientId,
    String? name,
    String? avatarUrl,
    String? lastMessage,
    DateTime? lastMessageAt,
    int unreadCount = 0,
  }) {
    return ChatConversation(
      type: type,
      teamId: teamId,
      recipientId: recipientId,
      name: name ?? (type == ConversationType.team ? _norwegianTeams[0] : _norwegianNames[0]),
      avatarUrl: avatarUrl,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
    );
  }

  static void reset() {}
}

/// Factory for creating TeamDocument test data
class TestDocumentFactory {
  static int _counter = 0;

  static TeamDocument create({
    String? id,
    String? teamId,
    String? uploadedBy,
    String? name,
    String? description,
    String? filePath,
    int fileSize = 1024,
    String mimeType = 'application/pdf',
    String? category,
    bool isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? uploaderName,
    String? uploaderAvatarUrl,
  }) {
    _counter++;
    return TeamDocument(
      id: id ?? 'doc-$_counter',
      teamId: teamId ?? 'team-1',
      uploadedBy: uploadedBy ?? 'user-1',
      name: name ?? 'Dokument $_counter.pdf',
      description: description,
      filePath: filePath ?? '/documents/doc-$_counter.pdf',
      fileSize: fileSize,
      mimeType: mimeType,
      category: category,
      isDeleted: isDeleted,
      createdAt: createdAt ?? _baseTime,
      updatedAt: updatedAt ?? _baseTime,
      uploaderName: uploaderName ?? _norwegianNames[0],
      uploaderAvatarUrl: uploaderAvatarUrl,
    );
  }

  static void reset() => _counter = 0;
}

/// Factory for creating AbsenceCategory test data
class TestAbsenceCategoryFactory {
  static int _counter = 0;

  static AbsenceCategory create({
    String? id,
    String? teamId,
    String? name,
    bool requiresApproval = false,
    bool countsAsValid = true,
    int sortOrder = 0,
    DateTime? createdAt,
  }) {
    _counter++;
    final categories = ['Sykdom', 'Jobb', 'Familie', 'Skade'];
    return AbsenceCategory(
      id: id ?? 'category-$_counter',
      teamId: teamId ?? 'team-1',
      name: name ?? categories[(_counter - 1) % categories.length],
      requiresApproval: requiresApproval,
      countsAsValid: countsAsValid,
      sortOrder: sortOrder,
      createdAt: createdAt ?? _baseTime,
    );
  }

  static void reset() => _counter = 0;
}

/// Factory for creating AbsenceRecord test data
class TestAbsenceRecordFactory {
  static int _counter = 0;

  static AbsenceRecord create({
    String? id,
    String? userId,
    String? instanceId,
    String? categoryId,
    String? reason,
    AbsenceStatus status = AbsenceStatus.pending,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? createdAt,
    String? userName,
    String? userAvatarUrl,
    String? categoryName,
    bool? categoryCountsAsValid,
    String? activityName,
    DateTime? activityDate,
    String? approvedByName,
  }) {
    _counter++;
    return AbsenceRecord(
      id: id ?? 'absence-$_counter',
      userId: userId ?? 'user-1',
      instanceId: instanceId ?? 'instance-1',
      categoryId: categoryId,
      reason: reason,
      status: status,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      createdAt: createdAt ?? _baseTime,
      userName: userName ?? _norwegianNames[0],
      userAvatarUrl: userAvatarUrl,
      categoryName: categoryName ?? 'Sykdom',
      categoryCountsAsValid: categoryCountsAsValid ?? true,
      activityName: activityName ?? 'Trening 1',
      activityDate: activityDate,
      approvedByName: approvedByName,
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
  TestConversationFactory.reset();
  TestDocumentFactory.reset();
  TestAbsenceCategoryFactory.reset();
  TestAbsenceRecordFactory.reset();
}
