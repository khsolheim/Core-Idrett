import 'package:test/test.dart';
import 'package:core_idrett_backend/models/test.dart';

void main() {
  group('TestTemplate', () {
    test('roundtrip med alle felt populert', () {
      final original = TestTemplate(
        id: 'template-1',
        teamId: 'team-1',
        name: 'Cooper-test',
        description: 'Løp så langt du kan på 12 minutter',
        unit: 'meter',
        higherIsBetter: true,
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TestTemplate.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = TestTemplate(
        id: 'template-2',
        teamId: 'team-2',
        name: '60 meter sprint',
        // description is null
        unit: 'sekunder',
        higherIsBetter: false,
        createdAt: DateTime.parse('2024-02-15T14:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TestTemplate.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('TestResult', () {
    test('roundtrip med alle felt populert', () {
      final original = TestResult(
        id: 'result-1',
        testTemplateId: 'template-1',
        userId: 'user-1',
        instanceId: 'instance-1',
        value: 2850.5,
        recordedAt: DateTime.parse('2024-03-15T16:00:00.000Z'),
        notes: 'Godt resultat, bedre enn forrige',
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/avatars/ola.jpg',
        testName: 'Cooper-test',
        testUnit: 'meter',
      );

      final json = original.toJson();
      final decoded = TestResult.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = TestResult(
        id: 'result-2',
        testTemplateId: 'template-2',
        userId: 'user-2',
        // instanceId is null
        value: 8.45,
        recordedAt: DateTime.parse('2024-03-16T10:30:00.000Z'),
        // notes is null
        // userName is null
        // userAvatarUrl is null
        // testName is null
        // testUnit is null
      );

      final json = original.toJson();
      final decoded = TestResult.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
