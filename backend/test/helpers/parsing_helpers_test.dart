import 'package:test/test.dart';
import 'package:core_idrett_backend/helpers/parsing_helpers.dart';

void main() {
  group('safeString', () {
    test('returnerer verdi når tilstede', () {
      final map = {'name': 'Test'};
      expect(safeString(map, 'name'), equals('Test'));
    });

    test('kaster FormatException når mangler uten default', () {
      final map = <String, dynamic>{};
      expect(
        () => safeString(map, 'name'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('Missing required field: name'))),
      );
    });

    test('returnerer defaultValue når mangler', () {
      final map = <String, dynamic>{};
      expect(safeString(map, 'name', defaultValue: 'fallback'), equals('fallback'));
    });

    test('kaster FormatException når feil type', () {
      final map = {'name': 123};
      expect(
        () => safeString(map, 'name'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('must be String'))),
      );
    });

    test('kaster FormatException når null uten default', () {
      final map = {'name': null};
      expect(
        () => safeString(map, 'name'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('safeStringNullable', () {
    test('returnerer verdi når tilstede', () {
      final map = {'name': 'Test'};
      expect(safeStringNullable(map, 'name'), equals('Test'));
    });

    test('returnerer null når mangler', () {
      final map = <String, dynamic>{};
      expect(safeStringNullable(map, 'name'), isNull);
    });

    test('returnerer null når null', () {
      final map = {'name': null};
      expect(safeStringNullable(map, 'name'), isNull);
    });

    test('kaster FormatException når feil type', () {
      final map = {'name': 123};
      expect(
        () => safeStringNullable(map, 'name'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('safeInt', () {
    test('returnerer verdi når tilstede', () {
      final map = {'count': 42};
      expect(safeInt(map, 'count'), equals(42));
    });

    test('returnerer default (0) når mangler', () {
      final map = <String, dynamic>{};
      expect(safeInt(map, 'count'), equals(0));
    });

    test('returnerer custom defaultValue når mangler', () {
      final map = <String, dynamic>{};
      expect(safeInt(map, 'count', defaultValue: 10), equals(10));
    });

    test('returnerer default når null', () {
      final map = {'count': null};
      expect(safeInt(map, 'count'), equals(0));
    });

    test('kaster FormatException når feil type', () {
      final map = {'count': 'not-a-number'};
      expect(
        () => safeInt(map, 'count'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('must be int'))),
      );
    });
  });

  group('safeIntNullable', () {
    test('returnerer verdi når tilstede', () {
      final map = {'count': 42};
      expect(safeIntNullable(map, 'count'), equals(42));
    });

    test('returnerer null når mangler', () {
      final map = <String, dynamic>{};
      expect(safeIntNullable(map, 'count'), isNull);
    });

    test('returnerer null når null', () {
      final map = {'count': null};
      expect(safeIntNullable(map, 'count'), isNull);
    });

    test('kaster FormatException når feil type', () {
      final map = {'count': 'not-a-number'};
      expect(
        () => safeIntNullable(map, 'count'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('safeDouble', () {
    test('returnerer verdi når tilstede (double)', () {
      final map = {'rate': 3.14};
      expect(safeDouble(map, 'rate'), equals(3.14));
    });

    test('returnerer verdi når tilstede (int konvertert til double)', () {
      final map = {'rate': 5};
      expect(safeDouble(map, 'rate'), equals(5.0));
    });

    test('returnerer default (0.0) når mangler', () {
      final map = <String, dynamic>{};
      expect(safeDouble(map, 'rate'), equals(0.0));
    });

    test('returnerer custom defaultValue når mangler', () {
      final map = <String, dynamic>{};
      expect(safeDouble(map, 'rate', defaultValue: 1.5), equals(1.5));
    });

    test('returnerer default når null', () {
      final map = {'rate': null};
      expect(safeDouble(map, 'rate'), equals(0.0));
    });

    test('kaster FormatException når feil type', () {
      final map = {'rate': 'not-a-number'};
      expect(
        () => safeDouble(map, 'rate'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('must be num'))),
      );
    });
  });

  group('safeDoubleNullable', () {
    test('returnerer verdi når tilstede (double)', () {
      final map = {'rate': 3.14};
      expect(safeDoubleNullable(map, 'rate'), equals(3.14));
    });

    test('returnerer verdi når tilstede (int konvertert til double)', () {
      final map = {'rate': 5};
      expect(safeDoubleNullable(map, 'rate'), equals(5.0));
    });

    test('returnerer null når mangler', () {
      final map = <String, dynamic>{};
      expect(safeDoubleNullable(map, 'rate'), isNull);
    });

    test('returnerer null når null', () {
      final map = {'rate': null};
      expect(safeDoubleNullable(map, 'rate'), isNull);
    });

    test('kaster FormatException når feil type', () {
      final map = {'rate': 'not-a-number'};
      expect(
        () => safeDoubleNullable(map, 'rate'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('safeBool', () {
    test('returnerer verdi når tilstede', () {
      final map = {'active': true};
      expect(safeBool(map, 'active'), isTrue);
    });

    test('returnerer default (false) når mangler', () {
      final map = <String, dynamic>{};
      expect(safeBool(map, 'active'), isFalse);
    });

    test('returnerer custom defaultValue når mangler', () {
      final map = <String, dynamic>{};
      expect(safeBool(map, 'active', defaultValue: true), isTrue);
    });

    test('returnerer default når null', () {
      final map = {'active': null};
      expect(safeBool(map, 'active'), isFalse);
    });

    test('kaster FormatException når feil type', () {
      final map = {'active': 'yes'};
      expect(
        () => safeBool(map, 'active'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('must be bool'))),
      );
    });
  });

  group('safeBoolNullable', () {
    test('returnerer verdi når tilstede', () {
      final map = {'active': true};
      expect(safeBoolNullable(map, 'active'), isTrue);
    });

    test('returnerer null når mangler', () {
      final map = <String, dynamic>{};
      expect(safeBoolNullable(map, 'active'), isNull);
    });

    test('returnerer null når null', () {
      final map = {'active': null};
      expect(safeBoolNullable(map, 'active'), isNull);
    });

    test('kaster FormatException når feil type', () {
      final map = {'active': 'yes'};
      expect(
        () => safeBoolNullable(map, 'active'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('safeNum', () {
    test('returnerer verdi når tilstede (int)', () {
      final map = {'value': 42};
      expect(safeNum(map, 'value'), equals(42));
    });

    test('returnerer verdi når tilstede (double)', () {
      final map = {'value': 3.14};
      expect(safeNum(map, 'value'), equals(3.14));
    });

    test('returnerer default (0) når mangler', () {
      final map = <String, dynamic>{};
      expect(safeNum(map, 'value'), equals(0));
    });

    test('returnerer custom defaultValue når mangler', () {
      final map = <String, dynamic>{};
      expect(safeNum(map, 'value', defaultValue: 10), equals(10));
    });

    test('returnerer default når null', () {
      final map = {'value': null};
      expect(safeNum(map, 'value'), equals(0));
    });

    test('kaster FormatException når feil type', () {
      final map = {'value': 'not-a-number'};
      expect(
        () => safeNum(map, 'value'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('must be num'))),
      );
    });
  });

  group('safeNumNullable', () {
    test('returnerer verdi når tilstede (int)', () {
      final map = {'value': 42};
      expect(safeNumNullable(map, 'value'), equals(42));
    });

    test('returnerer verdi når tilstede (double)', () {
      final map = {'value': 3.14};
      expect(safeNumNullable(map, 'value'), equals(3.14));
    });

    test('returnerer null når mangler', () {
      final map = <String, dynamic>{};
      expect(safeNumNullable(map, 'value'), isNull);
    });

    test('returnerer null når null', () {
      final map = {'value': null};
      expect(safeNumNullable(map, 'value'), isNull);
    });

    test('kaster FormatException når feil type', () {
      final map = {'value': 'not-a-number'};
      expect(
        () => safeNumNullable(map, 'value'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('requireDateTime', () {
    test('returnerer DateTime når tilstede som DateTime', () {
      final dt = DateTime.parse('2024-01-15T10:00:00.000Z');
      final map = {'created_at': dt};
      expect(requireDateTime(map, 'created_at'), equals(dt));
    });

    test('returnerer DateTime når tilstede som String', () {
      final map = {'created_at': '2024-01-15T10:00:00.000Z'};
      final result = requireDateTime(map, 'created_at');
      expect(result, isA<DateTime>());
      expect(result.year, equals(2024));
      expect(result.month, equals(1));
      expect(result.day, equals(15));
    });

    test('kaster FormatException når mangler', () {
      final map = <String, dynamic>{};
      expect(
        () => requireDateTime(map, 'created_at'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('Missing required field: created_at'))),
      );
    });

    test('kaster FormatException når null', () {
      final map = {'created_at': null};
      expect(
        () => requireDateTime(map, 'created_at'),
        throwsA(isA<FormatException>()),
      );
    });

    test('kaster FormatException når ugyldig string', () {
      final map = {'created_at': 'not-a-date'};
      expect(
        () => requireDateTime(map, 'created_at'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('Invalid DateTime format'))),
      );
    });

    test('kaster FormatException når feil type', () {
      final map = {'created_at': 12345};
      expect(
        () => requireDateTime(map, 'created_at'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('must be DateTime or String'))),
      );
    });
  });

  group('safeDateTimeNullable', () {
    test('returnerer DateTime når tilstede som DateTime', () {
      final dt = DateTime.parse('2024-01-15T10:00:00.000Z');
      final map = {'updated_at': dt};
      expect(safeDateTimeNullable(map, 'updated_at'), equals(dt));
    });

    test('returnerer DateTime når tilstede som String', () {
      final map = {'updated_at': '2024-01-15T10:00:00.000Z'};
      final result = safeDateTimeNullable(map, 'updated_at');
      expect(result, isA<DateTime>());
      expect(result?.year, equals(2024));
    });

    test('returnerer null når mangler', () {
      final map = <String, dynamic>{};
      expect(safeDateTimeNullable(map, 'updated_at'), isNull);
    });

    test('returnerer null når null', () {
      final map = {'updated_at': null};
      expect(safeDateTimeNullable(map, 'updated_at'), isNull);
    });

    test('kaster FormatException når ugyldig string', () {
      final map = {'updated_at': 'not-a-date'};
      expect(
        () => safeDateTimeNullable(map, 'updated_at'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('Invalid DateTime format'))),
      );
    });

    test('kaster FormatException når feil type', () {
      final map = {'updated_at': 12345};
      expect(
        () => safeDateTimeNullable(map, 'updated_at'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('safeMap', () {
    test('returnerer Map når tilstede', () {
      final map = {
        'data': {'nested': 'value'}
      };
      expect(safeMap(map, 'data'), equals({'nested': 'value'}));
    });

    test('kaster FormatException når mangler', () {
      final map = <String, dynamic>{};
      expect(
        () => safeMap(map, 'data'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('Missing required field: data'))),
      );
    });

    test('kaster FormatException når null', () {
      final map = {'data': null};
      expect(
        () => safeMap(map, 'data'),
        throwsA(isA<FormatException>()),
      );
    });

    test('kaster FormatException når feil type', () {
      final map = {'data': 'not-a-map'};
      expect(
        () => safeMap(map, 'data'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('must be Map'))),
      );
    });
  });

  group('safeMapNullable', () {
    test('returnerer Map når tilstede', () {
      final map = {
        'data': {'nested': 'value'}
      };
      expect(safeMapNullable(map, 'data'), equals({'nested': 'value'}));
    });

    test('returnerer null når mangler', () {
      final map = <String, dynamic>{};
      expect(safeMapNullable(map, 'data'), isNull);
    });

    test('returnerer null når null', () {
      final map = {'data': null};
      expect(safeMapNullable(map, 'data'), isNull);
    });

    test('kaster FormatException når feil type', () {
      final map = {'data': 'not-a-map'};
      expect(
        () => safeMapNullable(map, 'data'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('safeList', () {
    test('returnerer List når tilstede', () {
      final map = {
        'items': [1, 2, 3]
      };
      expect(safeList(map, 'items'), equals([1, 2, 3]));
    });

    test('kaster FormatException når mangler', () {
      final map = <String, dynamic>{};
      expect(
        () => safeList(map, 'items'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('Missing required field: items'))),
      );
    });

    test('kaster FormatException når null', () {
      final map = {'items': null};
      expect(
        () => safeList(map, 'items'),
        throwsA(isA<FormatException>()),
      );
    });

    test('kaster FormatException når feil type', () {
      final map = {'items': 'not-a-list'};
      expect(
        () => safeList(map, 'items'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('must be List'))),
      );
    });
  });

  group('safeListNullable', () {
    test('returnerer List når tilstede', () {
      final map = {
        'items': [1, 2, 3]
      };
      expect(safeListNullable(map, 'items'), equals([1, 2, 3]));
    });

    test('returnerer null når mangler', () {
      final map = <String, dynamic>{};
      expect(safeListNullable(map, 'items'), isNull);
    });

    test('returnerer null når null', () {
      final map = {'items': null};
      expect(safeListNullable(map, 'items'), isNull);
    });

    test('kaster FormatException når feil type', () {
      final map = {'items': 'not-a-list'};
      expect(
        () => safeListNullable(map, 'items'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
