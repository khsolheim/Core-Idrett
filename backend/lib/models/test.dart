import 'package:equatable/equatable.dart';

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
      id: row['id'] as String,
      teamId: row['team_id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      unit: row['unit'] as String,
      higherIsBetter: row['higher_is_better'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
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
      id: row['id'] as String,
      testTemplateId: row['test_template_id'] as String,
      userId: row['user_id'] as String,
      instanceId: row['instance_id'] as String?,
      value: (row['value'] as num).toDouble(),
      recordedAt: DateTime.parse(row['recorded_at'] as String),
      notes: row['notes'] as String?,
      userName: row['user_name'] as String?,
      userAvatarUrl: row['user_avatar_url'] as String?,
      testName: row['test_name'] as String?,
      testUnit: row['test_unit'] as String?,
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
