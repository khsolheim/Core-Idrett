import 'package:test/test.dart';
import 'package:core_idrett_backend/models/mini_activity_team.dart';

void main() {
  group('MiniActivityTeam', () {
    test('roundtrip med alle felt populert', () {
      final original = MiniActivityTeam(
        id: 'mini-team-1',
        miniActivityId: 'mini-1',
        name: 'Team Alpha',
        finalScore: 42,
      );

      final json = original.toJson();
      final decoded = MiniActivityTeam.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MiniActivityTeam(
        id: 'mini-team-2',
        miniActivityId: 'mini-2',
        // name is null
        // finalScore is null
      );

      final json = original.toJson();
      final decoded = MiniActivityTeam.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('MiniActivityParticipant', () {
    test('roundtrip med alle felt populert', () {
      final original = MiniActivityParticipant(
        id: 'participant-1',
        miniTeamId: 'mini-team-1',
        miniActivityId: 'mini-1',
        userId: 'user-1',
        points: 10,
      );

      final json = original.toJson();
      final decoded = MiniActivityParticipant.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MiniActivityParticipant(
        id: 'participant-2',
        // miniTeamId is null (individual activity)
        miniActivityId: 'mini-2',
        userId: 'user-2',
        points: 5,
      );

      final json = original.toJson();
      final decoded = MiniActivityParticipant.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
