import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

/// Test template model for reusable test definitions
class TestTemplate extends Equatable {
  final String id;
  final String teamId;
  final String name;
  final String? description;
  final String unit; // "sekunder", "meter", "repetisjoner", "poeng"
  final bool higherIsBetter;
  final DateTime createdAt;

  const TestTemplate({
    required this.id,
    required this.teamId,
    required this.name,
    this.description,
    required this.unit,
    required this.higherIsBetter,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        teamId,
        name,
        description,
        unit,
        higherIsBetter,
        createdAt,
      ];

  factory TestTemplate.fromJson(Map<String, dynamic> row) {
    return TestTemplate(
      id: safeString(row, 'id'),
      teamId: safeString(row, 'team_id'),
      name: safeString(row, 'name'),
      description: safeStringNullable(row, 'description'),
      unit: safeString(row, 'unit'),
      higherIsBetter: safeBool(row, 'higher_is_better', defaultValue: false),
      createdAt: requireDateTime(row, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'name': name,
      'description': description,
      'unit': unit,
      'higher_is_better': higherIsBetter,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Test result model for individual test scores
class TestResult extends Equatable {
  final String id;
  final String testTemplateId;
  final String userId;
  final String? instanceId;
  final double value;
  final DateTime recordedAt;
  final String? notes;

  // Optional joined fields
  final String? userName;
  final String? userAvatarUrl;
  final String? testName;
  final String? testUnit;

  const TestResult({
    required this.id,
    required this.testTemplateId,
    required this.userId,
    this.instanceId,
    required this.value,
    required this.recordedAt,
    this.notes,
    this.userName,
    this.userAvatarUrl,
    this.testName,
    this.testUnit,
  });

  @override
  List<Object?> get props => [
        id,
        testTemplateId,
        userId,
        instanceId,
        value,
        recordedAt,
        notes,
        userName,
        userAvatarUrl,
        testName,
        testUnit,
      ];

  factory TestResult.fromJson(Map<String, dynamic> row) {
    return TestResult(
      id: safeString(row, 'id'),
      testTemplateId: safeString(row, 'test_template_id'),
      userId: safeString(row, 'user_id'),
      instanceId: safeStringNullable(row, 'instance_id'),
      value: safeDouble(row, 'value'),
      recordedAt: requireDateTime(row, 'recorded_at'),
      notes: safeStringNullable(row, 'notes'),
      userName: safeStringNullable(row, 'user_name'),
      userAvatarUrl: safeStringNullable(row, 'user_avatar_url'),
      testName: safeStringNullable(row, 'test_name'),
      testUnit: safeStringNullable(row, 'test_unit'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'test_template_id': testTemplateId,
      'user_id': userId,
      'instance_id': instanceId,
      'value': value,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
      if (userName != null) 'user_name': userName,
      if (userAvatarUrl != null) 'user_avatar_url': userAvatarUrl,
      if (testName != null) 'test_name': testName,
      if (testUnit != null) 'test_unit': testUnit,
    };
  }
}
