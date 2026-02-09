import 'package:shelf_limiter/shelf_limiter.dart';

/// Rate limiter for auth endpoints (login, register).
/// Strict limits to prevent brute-force attacks.
/// 5 requests per minute per IP.
final authRateLimiter = shelfLimiter(
  RateLimiterOptions(
    maxRequests: 5,
    windowSize: const Duration(minutes: 1),
  ),
);

/// Rate limiter for data mutation endpoints (messages, fines).
/// Moderate limits to prevent abuse.
/// 30 requests per minute per IP.
final mutationRateLimiter = shelfLimiter(
  RateLimiterOptions(
    maxRequests: 30,
    windowSize: const Duration(minutes: 1),
  ),
);

/// Rate limiter for export endpoints.
/// Conservative limits since exports are resource-intensive.
/// 5 requests per 5 minutes per IP.
final exportRateLimiter = shelfLimiter(
  RateLimiterOptions(
    maxRequests: 5,
    windowSize: const Duration(minutes: 5),
  ),
);
