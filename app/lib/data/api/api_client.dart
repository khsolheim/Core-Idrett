import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config.dart';
import '../../core/errors/app_exceptions.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio _dio;
  String? _token;

  /// Callback for handling token expiration (set by auth provider)
  void Function()? onTokenExpired;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final exception = _mapDioError(error);

        // Handle token expiration
        if (error.response?.statusCode == 401) {
          _token = null;
          await clearToken();
          onTokenExpired?.call();
        }

        // Reject with our custom exception wrapped in DioException
        return handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: exception,
          ),
        );
      },
    ));
  }

  /// Map Dio errors to AppException types
  AppException _mapDioError(DioException error) {
    // Check connection/timeout errors first
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NoInternetException();

      case DioExceptionType.badCertificate:
        return const ConnectionFailedException();

      case DioExceptionType.cancel:
        return const NetworkException('Forespørselen ble avbrutt', code: 'CANCELLED');

      case DioExceptionType.badResponse:
        return _mapHttpError(error);

      case DioExceptionType.unknown:
        // Check if it's a network-related error
        if (error.error != null) {
          final errorString = error.error.toString().toLowerCase();
          if (errorString.contains('socketexception') ||
              errorString.contains('connection refused') ||
              errorString.contains('network is unreachable')) {
            return const NoInternetException();
          }
        }
        return ServerException(error.message);
    }
  }

  /// Map HTTP status codes to AppException types
  AppException _mapHttpError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    // Extract server error details
    String? serverCode;
    String? serverMessage;
    Map<String, String>? fieldErrors;

    if (responseData is Map<String, dynamic>) {
      serverCode = responseData['code'] as String?;
      serverMessage = responseData['message'] as String?;

      // Parse field-specific validation errors
      if (responseData['errors'] is Map) {
        fieldErrors = (responseData['errors'] as Map).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    }

    switch (statusCode) {
      case 400:
        return ValidationException(
          serverMessage ?? 'Ugyldig forespørsel',
          fieldErrors: fieldErrors,
        );

      case 401:
        // Check for specific auth error codes
        if (serverCode == 'INVALID_CREDENTIALS') {
          return const InvalidCredentialsException();
        }
        if (serverCode == 'SESSION_INVALIDATED') {
          return const SessionInvalidatedException();
        }
        return const TokenExpiredException();

      case 403:
        if (serverCode == 'REMOVED_FROM_TEAM') {
          return const RemovedFromTeamException();
        }
        if (serverCode == 'ROLE_CHANGED') {
          return const RoleChangedException();
        }
        return const UnauthorizedException();

      case 404:
        // Map specific resource types
        if (serverCode == 'TEAM_NOT_FOUND') {
          return const TeamNotFoundException();
        }
        if (serverCode == 'ACTIVITY_DELETED') {
          return const ActivityDeletedException();
        }
        return NotFoundException(serverMessage ?? 'Ressurs');

      case 409:
        // Conflict errors
        if (serverCode == 'FINE_PROCESSED') {
          return const FineAlreadyProcessedException();
        }
        if (serverCode == 'INVITE_USED') {
          return const InviteCodeUsedException();
        }
        return ConflictException(serverMessage ?? 'En konflikt oppstod');

      case 410:
        // Resource deleted (Gone)
        if (serverCode == 'ACTIVITY_CANCELLED') {
          return const ActivityCancelledException();
        }
        return ResourceDeletedException(serverMessage ?? 'Ressurs');

      case 422:
        // Validation/business logic errors
        if (serverCode == 'INVALID_INVITE') {
          return const InvalidInviteCodeException();
        }
        if (serverCode == 'DEADLINE_EXPIRED') {
          return const DeadlineExpiredException();
        }
        if (serverCode == 'APPEAL_NOT_ALLOWED') {
          return const AppealNotAllowedException();
        }
        if (serverCode == 'RULE_DELETED') {
          return const FineRuleDeletedException();
        }
        return ValidationException(
          serverMessage ?? 'Valideringsfeil',
          fieldErrors: fieldErrors,
        );

      case 429:
        // Rate limited
        final retryAfterHeader = error.response?.headers['retry-after']?.first;
        Duration? retryAfter;
        if (retryAfterHeader != null) {
          final seconds = int.tryParse(retryAfterHeader);
          if (seconds != null) {
            retryAfter = Duration(seconds: seconds);
          }
        }
        return RateLimitException(retryAfter: retryAfter);

      case 500:
        return ServerException(serverMessage);

      case 502:
      case 503:
      case 504:
        return const ServiceUnavailableException();

      default:
        return ServerException(serverMessage ?? 'En uventet feil oppstod');
    }
  }

  void setToken(String? token) {
    _token = token;
  }

  bool get hasToken => _token != null;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Wrapper to extract AppException from DioException
  Future<T> _handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      // If our interceptor already mapped it, throw that exception
      if (e.error is AppException) {
        throw e.error as AppException;
      }
      // Otherwise map it now
      throw _mapDioError(e);
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _handleRequest(() => _dio.get(path, queryParameters: queryParameters));
  }

  Future<Response> post(String path, {dynamic data}) {
    return _handleRequest(() => _dio.post(path, data: data));
  }

  Future<Response> put(String path, {dynamic data}) {
    return _handleRequest(() => _dio.put(path, data: data));
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _handleRequest(() => _dio.patch(path, data: data));
  }

  Future<Response> delete(String path) {
    return _handleRequest(() => _dio.delete(path));
  }
}
