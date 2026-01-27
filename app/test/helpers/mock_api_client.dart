/// Mock API client for testing
library;

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

/// Mock Dio response helper
class MockResponse<T> extends Mock implements Response<T> {
  MockResponse({
    required T data,
    int statusCode = 200,
    Map<String, List<String>>? headers,
  }) {
    _data = data;
    _statusCode = statusCode;
    _headers = Headers.fromMap(headers ?? {});
  }

  late final T _data;
  late final int _statusCode;
  late final Headers _headers;

  @override
  T get data => _data;

  @override
  int get statusCode => _statusCode;

  @override
  Headers get headers => _headers;
}

/// Simulates API responses without actual HTTP calls
class MockApiResponses {
  /// Auth responses
  static Map<String, dynamic> loginSuccess({
    String token = 'mock-token-123',
    String userId = 'user-1',
    String email = 'test@test.com',
    String name = 'Test User',
  }) {
    return {
      'token': token,
      'user': {
        'id': userId,
        'email': email,
        'name': name,
        'avatar_url': null,
        'birth_date': null,
        'created_at': DateTime.now().toIso8601String(),
      },
    };
  }

  static Map<String, dynamic> registerSuccess({
    String token = 'mock-token-123',
    String userId = 'user-1',
    String email = 'test@test.com',
    String name = 'Test User',
  }) {
    return loginSuccess(
      token: token,
      userId: userId,
      email: email,
      name: name,
    );
  }

  static Map<String, dynamic> authError({
    String code = 'INVALID_CREDENTIALS',
    String message = 'Invalid email or password',
  }) {
    return {
      'code': code,
      'message': message,
    };
  }

  /// Team responses
  static List<Map<String, dynamic>> teamsList({int count = 2}) {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < count; i++) {
      result.add({
        'id': 'team-${i + 1}',
        'name': 'Team ${i + 1}',
        'sport': i == 0 ? 'Fotball' : 'Håndball',
        'invite_code': 'INVITE${i + 1}',
        'created_at': DateTime.now().toIso8601String(),
        'user_is_admin': i == 0,
        'user_is_fine_boss': true,
      });
    }
    return result;
  }

  static Map<String, dynamic> team({
    String id = 'team-1',
    String name = 'Test Team',
    String? sport,
    bool userIsAdmin = true,
    bool userIsFineBoss = true,
  }) {
    return {
      'id': id,
      'name': name,
      'sport': sport,
      'invite_code': 'TESTINVITE',
      'created_at': DateTime.now().toIso8601String(),
      'user_is_admin': userIsAdmin,
      'user_is_fine_boss': userIsFineBoss,
    };
  }

  static List<Map<String, dynamic>> teamMembers({
    String teamId = 'team-1',
    int count = 3,
  }) {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < count; i++) {
      result.add({
        'id': 'member-${i + 1}',
        'user_id': 'user-${i + 1}',
        'team_id': teamId,
        'user_name': 'Member ${i + 1}',
        'user_avatar_url': null,
        'user_birth_date': null,
        'role': i == 0 ? 'admin' : 'player',
        'is_admin': i == 0,
        'is_fine_boss': i <= 1,
        'is_active': true,
        'joined_at': DateTime.now().toIso8601String(),
      });
    }
    return result;
  }

  /// Activity responses
  static List<Map<String, dynamic>> activitiesList({
    String teamId = 'team-1',
    int count = 3,
  }) {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < count; i++) {
      result.add({
        'id': 'activity-${i + 1}',
        'team_id': teamId,
        'title': 'Activity ${i + 1}',
        'type': i == 0 ? 'training' : (i == 1 ? 'match' : 'social'),
        'location': 'Location ${i + 1}',
        'description': 'Description ${i + 1}',
        'recurrence_type': 'once',
        'response_type': 'yes_no',
        'created_at': DateTime.now().toIso8601String(),
        'instance_count': 1,
      });
    }
    return result;
  }

  static List<Map<String, dynamic>> activityInstances({
    String teamId = 'team-1',
    int count = 3,
  }) {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < count; i++) {
      final date = DateTime.now().add(Duration(days: i + 1));
      result.add({
        'id': 'instance-${i + 1}',
        'activity_id': 'activity-${i + 1}',
        'team_id': teamId,
        'date': date.toIso8601String().split('T')[0],
        'start_time': '18:00',
        'end_time': '20:00',
        'status': 'scheduled',
        'title': 'Activity ${i + 1}',
        'type': i == 0 ? 'training' : (i == 1 ? 'match' : 'social'),
        'location': 'Location ${i + 1}',
        'response_type': 'yes_no',
        'user_response': null,
        'yes_count': i * 2,
        'no_count': i,
        'maybe_count': 0,
      });
    }
    return result;
  }

  static Map<String, dynamic> activityInstance({
    String id = 'instance-1',
    String activityId = 'activity-1',
    String teamId = 'team-1',
    String title = 'Test Activity',
    String? userResponse,
  }) {
    final date = DateTime.now().add(const Duration(days: 1));
    return {
      'id': id,
      'activity_id': activityId,
      'team_id': teamId,
      'date': date.toIso8601String().split('T')[0],
      'start_time': '18:00',
      'end_time': '20:00',
      'status': 'scheduled',
      'title': title,
      'type': 'training',
      'location': 'Test Location',
      'description': 'Test description',
      'response_type': 'yes_no',
      'user_response': userResponse,
      'yes_count': 5,
      'no_count': 2,
      'maybe_count': 1,
      'responses': <Map<String, dynamic>>[],
    };
  }

  /// Fines responses
  static List<Map<String, dynamic>> finesList({
    String teamId = 'team-1',
    int count = 3,
  }) {
    final statuses = ['pending', 'approved', 'paid'];
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < count; i++) {
      result.add({
        'id': 'fine-${i + 1}',
        'rule_id': 'rule-1',
        'team_id': teamId,
        'offender_id': 'user-${i + 2}',
        'reporter_id': 'user-1',
        'status': statuses[i % statuses.length],
        'amount': (i + 1) * 50.0,
        'description': 'Fine ${i + 1}',
        'created_at': DateTime.now().toIso8601String(),
        'offender_name': 'Offender ${i + 1}',
        'reporter_name': 'Reporter',
        'rule_name': 'Rule ${i + 1}',
      });
    }
    return result;
  }

  static List<Map<String, dynamic>> fineRules({
    String teamId = 'team-1',
    int count = 3,
  }) {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < count; i++) {
      result.add({
        'id': 'rule-${i + 1}',
        'team_id': teamId,
        'name': 'Rule ${i + 1}',
        'amount': (i + 1) * 50.0,
        'description': 'Rule description ${i + 1}',
        'active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    return result;
  }

  /// Messages responses
  static List<Map<String, dynamic>> messagesList({
    String teamId = 'team-1',
    int count = 5,
  }) {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < count; i++) {
      final now = DateTime.now().subtract(Duration(minutes: (count - i) * 5));
      result.add({
        'id': 'message-${i + 1}',
        'team_id': teamId,
        'user_id': 'user-${(i % 3) + 1}',
        'content': 'Message ${i + 1}',
        'reply_to_id': null,
        'is_edited': false,
        'is_deleted': false,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'user_name': 'User ${(i % 3) + 1}',
        'user_avatar_url': null,
      });
    }
    return result;
  }
}

/// DioException builder for testing error scenarios
class MockDioError {
  static DioException badRequest({
    String? code,
    String? message,
    Map<String, String>? fieldErrors,
  }) {
    final data = <String, dynamic>{};
    if (code != null) data['code'] = code;
    if (message != null) data['message'] = message;
    if (fieldErrors != null) data['errors'] = fieldErrors;

    return DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 400,
        data: data,
      ),
      type: DioExceptionType.badResponse,
    );
  }

  static DioException unauthorized({
    String code = 'INVALID_CREDENTIALS',
    String message = 'Invalid credentials',
  }) {
    return DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 401,
        data: {
          'code': code,
          'message': message,
        },
      ),
      type: DioExceptionType.badResponse,
    );
  }

  static DioException notFound({
    String? code,
    String message = 'Resource not found',
  }) {
    final data = <String, dynamic>{'message': message};
    if (code != null) data['code'] = code;

    return DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 404,
        data: data,
      ),
      type: DioExceptionType.badResponse,
    );
  }

  static DioException serverError({
    String message = 'Internal server error',
  }) {
    return DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 500,
        data: {
          'message': message,
        },
      ),
      type: DioExceptionType.badResponse,
    );
  }

  static DioException connectionError() {
    return DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionError,
    );
  }

  static DioException timeout() {
    return DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionTimeout,
    );
  }
}
