---
phase: 01-test-infrastructure
plan: 04
subsystem: frontend-testing
tags: [testing, roundtrip, serialization, model-tests]
dependency_graph:
  requires:
    - 01-02 (Equatable models)
  provides:
    - frontend-model-roundtrip-tests
    - serialization-safety-net
  affects:
    - all-frontend-features
tech_stack:
  added: []
  patterns:
    - Roundtrip serialization testing (fromJson(toJson(m)) == m)
    - Norwegian test names for all test cases
    - Two-variant testing (all-populated + optional-null)
key_files:
  created:
    - app/test/models/user_test.dart
    - app/test/models/team_test.dart
    - app/test/models/activity_test.dart
    - app/test/models/message_test.dart
    - app/test/models/conversation_test.dart
    - app/test/models/fine_test.dart
    - app/test/models/document_test.dart
    - app/test/models/absence_test.dart
    - app/test/models/notification_test.dart
    - app/test/models/export_log_test.dart
    - app/test/models/stopwatch_test.dart
  modified: []
decisions:
  - "Models without toJson() require manual JSON map construction for tests"
  - "All test names in Norwegian per locked project decision"
  - "Two test variants per class: fully populated and optional-fields-null"
  - "Team model tests manually add user role fields to JSON for roundtrip (not in toJson())"
metrics:
  duration_minutes: 5
  completed_date: 2026-02-08
  tasks_completed: 1.08 (Task 1 complete + partial Task 2)
  files_created: 11
  test_files_created: 11
  classes_tested: 30
  test_cases_written: 60
  tests_passing: 60
---

# Phase 01 Plan 04: Frontend Model Roundtrip Tests (PARTIAL COMPLETION)

**One-liner:** Comprehensive roundtrip serialization tests for 30 frontend model classes ensuring fromJson(toJson(m)) == m equality.

## Status

**PARTIAL COMPLETION**: Task 1 fully complete, Task 2 in progress (1 of 12 files).

### Completed
- **Task 1**: All core frontend models tested (10 files, 27 classes, 54 tests) ✓
- **Task 2**: Stopwatch models tested (1 file, 3 classes, 6 tests) ✓

### Remaining
- **Task 2**: 11 model files remaining:
  - statistics_core.dart (5 classes)
  - statistics_player.dart (6 classes)
  - points_config_models.dart (3 classes)
  - points_config_leaderboard.dart (3 classes)
  - tournament_models.dart (4 classes)
  - tournament_group_models.dart (5 classes)
  - achievement_models.dart (4 classes)
  - mini_activity_models.dart (2 classes)
  - mini_activity_support.dart (6 classes)
  - mini_activity_statistics_core.dart (3 classes)
  - mini_activity_statistics_aggregate.dart (3 classes)
  - **Total remaining**: ~44 classes, ~88 test cases

## Context

Frontend models depend on correct JSON serialization for API communication. Without roundtrip tests, field mapping bugs, type parsing errors, and nullable handling issues can crash the app at runtime. These tests provide the safety net for refactoring in later phases.

Plan 01-02 added Equatable to all frontend models, enabling structural equality assertions (`expect(decoded, equals(original))`).

## What Was Built

### Task 1: Core Frontend Models (COMPLETE)

Created roundtrip tests for 10 model files covering 27 classes:

**user.dart (1 class)**
- User

**team.dart (4 classes)**
- TrainerType
- Team
- TeamMember
- TeamSettings

**activity.dart (5 classes)**
- SeriesInfo
- Activity
- ActivityResponseItem
- ActivityInstance
- InstanceOperationResult

**message.dart (1 class)**
- Message

**conversation.dart (1 class)**
- ChatConversation

**fine.dart (6 classes)**
- FineRule
- FineAppeal
- Fine
- FinePayment
- TeamFinesSummary
- UserFinesSummary

**document.dart (2 classes)**
- TeamDocument
- DocumentCategoryCount

**absence.dart (3 classes)**
- AbsenceCategory
- AbsenceRecord
- AbsenceSummary

**notification.dart (2 classes)**
- NotificationPreferences
- DeviceToken

**export_log.dart (2 classes)**
- ExportLog
- ExportData

### Task 2: Complex Frontend Models (IN PROGRESS - 1/12 files)

**stopwatch.dart (3 classes)** ✓
- StopwatchSession
- StopwatchTime
- StopwatchSessionWithTimes

## Testing

- `flutter test test/models/` runs all 60 roundtrip tests and passes
- Each class has exactly 2 test cases (all fields populated + optional fields null)
- All test names in Norwegian (`roundtrip med alle felt populert`, `roundtrip med alle valgfrie felt null`)
- Zero test failures

## Implementation Patterns

### toJson() Availability

Not all models have `toJson()` methods. Tests handle both cases:

**Models WITH toJson():**
```dart
final json = original.toJson();
final decoded = User.fromJson(json);
expect(decoded, equals(original));
```

**Models WITHOUT toJson():**
```dart
final jsonMap = {
  'id': original.id,
  'activity_id': original.activityId,
  // ... all fields manually mapped
};
final decoded = SeriesInfo.fromJson(jsonMap);
expect(decoded, equals(original));
```

### Team Model Special Case

Team model's `toJson()` doesn't include user role fields (`user_is_admin`, `user_is_coach`, etc.) but `fromJson()` expects them. Tests manually add these fields:

```dart
final json = original.toJson();
json['user_is_admin'] = original.userIsAdmin;
json['user_is_fine_boss'] = original.userIsFineBoss;
json['user_is_coach'] = original.userIsCoach;
if (original.userTrainerType != null) {
  json['user_trainer_type'] = original.userTrainerType!.toJson();
}
final decoded = Team.fromJson(json);
```

### Norwegian Test Names

All test groups and descriptions use Norwegian per project decision:
- `group('KlasseNavn', () { ... })`
- `test('roundtrip med alle felt populert', () { ... })`
- `test('roundtrip med alle valgfrie felt null', () { ... })`

### Realistic Norwegian Test Data

Test data uses Norwegian names, domains, and terminology:
- Names: "Ola Nordmann", "Kari Hansen", "Per Olsen"
- Emails: "@example.no" domain
- Teams: "Rosenborg BK", "Brann FK", "Viking FK"
- Activities: "Onsdagstrening", "Kamp mot Viking"
- Fines: "For sent til trening", "Glemt utstyr"

### UTC Timestamps

All DateTime values use UTC timestamps with explicit timezone:
```dart
DateTime.parse('2024-01-15T10:30:00.000Z')
```

## Deviations from Plan

None for Task 1. Task 2 incomplete due to time/token constraints - remaining 11 files require continuation agent.

## Technical Notes

### Equatable Dependency

Tests rely on Equatable (added in plan 01-02) for structural equality. Without Equatable, `expect(decoded, equals(original))` would use reference equality and fail.

### Nested Model Construction

Models with nested objects (Fine with FineAppeal, ActivityInstance with SeriesInfo) construct nested instances in "all populated" test variant:

```dart
final appeal = FineAppeal(/* ... */);
final original = Fine(
  // ...
  appeal: appeal,
);
```

### Enum Handling

Tests import model files (not enum barrel exports) and use enum values directly:
- `ActivityType.training`
- `RecurrenceType.weekly`
- `StopwatchSessionType.stopwatch`

Enum `toApiString()` methods used for JSON serialization where available.

## Next Steps for Continuation Agent

To complete Task 2, create roundtrip tests for the remaining 11 model files:

1. **Read each model file** to identify all classes, fields, types, and optionality
2. **Check for toJson()** - use it if available, otherwise manually construct JSON maps
3. **Follow established patterns** from completed files
4. **Test enum fields** with valid enum values
5. **Nest sub-models** in "all populated" variants
6. **Run tests incrementally** to catch issues early

Estimated remaining effort: ~2-3 hours for 44 classes.

## Self-Check: PASSED (Partial)

**Verified created files:**
```
✓ app/test/models/user_test.dart (2 tests)
✓ app/test/models/team_test.dart (8 tests)
✓ app/test/models/activity_test.dart (10 tests)
✓ app/test/models/message_test.dart (2 tests)
✓ app/test/models/conversation_test.dart (2 tests)
✓ app/test/models/fine_test.dart (12 tests)
✓ app/test/models/document_test.dart (4 tests)
✓ app/test/models/absence_test.dart (6 tests)
✓ app/test/models/notification_test.dart (4 tests)
✓ app/test/models/export_log_test.dart (4 tests)
✓ app/test/models/stopwatch_test.dart (6 tests)
```

**Verified commits:**
```
✓ b3e63fb: test(01-04): add roundtrip tests for core frontend models
✓ 3e87a10: test(01-04): add roundtrip tests for stopwatch models
```

**Verified tests pass:**
```
✓ flutter test test/models/ → 60 tests passed
✓ All test names in Norwegian
✓ Each class has exactly 2 test variants
```

Task 1 fully verified. Task 2 requires continuation.
