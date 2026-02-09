# Phase 4: Backend Security & Input Validation - Research

**Researched:** 2026-02-09
**Domain:** Backend API Security, Rate Limiting, Input Validation
**Confidence:** HIGH

## Summary

This phase focuses on hardening backend security through four key areas: consolidating admin role checks to a single authoritative source, implementing rate limiting on sensitive endpoints, adding fine_boss permission checks, and ensuring comprehensive input validation. The Dart/Shelf ecosystem provides mature solutions for rate limiting through shelf_limiter, and the codebase already has strong foundations with existing auth middleware, validation helpers, and parsing utilities.

The current dual-check pattern (user_is_admin OR user_role=='admin') exists in auth_helpers.dart as backwards compatibility during a role system migration. The team_members table now uses boolean flags (is_admin, is_fine_boss, is_coach) alongside the legacy role string. Consolidation means removing the OR check and using only the boolean flags as the authoritative source.

**Primary recommendation:** Use shelf_limiter for rate limiting (flexible, endpoint-specific configuration), extend existing validation_helpers.dart for consistent validation patterns, create an isFinesManager() helper function for fine_boss checks, and establish comprehensive test coverage for all security changes.

## Standard Stack

### Core Dependencies
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| shelf_limiter | ^2.0.1 | Rate limiting middleware | Most actively maintained, endpoint-specific limits, customizable client identification, 429 responses |
| shelf | ^1.4.2 | HTTP server framework | Already in use, core Dart web server middleware |
| test | latest | Testing framework | Standard Dart testing library |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| mocktail | latest | Test mocking | Testing middleware in isolation, mocking RequestContext |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| shelf_limiter | shelf_rate_limiter | Less flexible (no endpoint-specific limits), last updated 2022 |
| shelf_limiter | shelf_throttle | Global throttling only, no per-endpoint configuration |
| shelf_limiter | Custom implementation | Avoids dependency but misses edge cases (distributed state, memory leaks, clock skew) |

**Installation:**
```bash
cd backend
dart pub add shelf_limiter
dart pub add --dev mocktail  # if not already present
```

## Architecture Patterns

### Recommended Project Structure
```
backend/lib/api/
├── middleware/
│   ├── auth_middleware.dart     # Existing
│   └── rate_limit_middleware.dart  # New: rate limit configurations
├── helpers/
│   ├── auth_helpers.dart        # Consolidate admin check here
│   ├── validation_helpers.dart  # Extend with new validators
│   └── permission_helpers.dart  # New: fine_boss and other permission checks
└── [handlers]                    # Use permission helpers consistently
```

### Pattern 1: Rate Limiting Middleware Configuration
**What:** Create reusable rate limiters for different endpoint categories (auth, mutation, export)
**When to use:** At router setup, wrap routes in Pipeline with rate limit middleware
**Example:**
```dart
// rate_limit_middleware.dart
import 'package:shelf_limiter/shelf_limiter.dart';

// Auth endpoints: stricter limits to prevent brute force
final authRateLimiter = shelfLimiter(
  RateLimiterOptions(
    maxRequests: 5,
    windowSize: Duration(minutes: 1),
  ),
);

// Data mutation endpoints: moderate limits
final mutationRateLimiter = shelfLimiter(
  RateLimiterOptions(
    maxRequests: 20,
    windowSize: Duration(minutes: 1),
  ),
);

// Export endpoints: low limits (resource intensive)
final exportRateLimiter = shelfLimiter(
  RateLimiterOptions(
    maxRequests: 5,
    windowSize: Duration(minutes: 5),
  ),
);
```

**Application in router:**
```dart
// Auth routes with rate limiting (no auth middleware)
final authHandler = AuthHandler(authService);
router.mount('/auth',
  const Pipeline()
    .addMiddleware(authRateLimiter)
    .addHandler(authHandler.router.call)
    .call
);

// Protected routes with auth + rate limiting for mutations
final messagesHandler = MessagesHandler(...);
router.mount('/messages',
  const Pipeline()
    .addMiddleware(auth)
    .addMiddleware(mutationRateLimiter)
    .addHandler(messagesHandler.router.call)
    .call
);
```

### Pattern 2: Consolidated Admin Check
**What:** Single authoritative source for admin permissions using boolean flags only
**When to use:** All handlers requiring admin access
**Example:**
```dart
// auth_helpers.dart - BEFORE (dual-check with backwards compatibility)
bool isAdmin(Map<String, dynamic> team) {
  return team['user_is_admin'] == true || team['user_role'] == 'admin';
}

// auth_helpers.dart - AFTER (single authoritative source)
bool isAdmin(Map<String, dynamic> team) {
  return team['user_is_admin'] == true;
}
```

**Why consolidate:** The dual-check creates inconsistency risk. If user_is_admin is false but user_role is 'admin', which is authoritative? The boolean flags are the new system; the role string is deprecated. Using only the flags makes the authorization decision unambiguous and prevents security issues from inconsistent data.

### Pattern 3: Fine Boss Permission Check
**What:** Dedicated helper for fine_boss role checks, separate from admin
**When to use:** Fine mutation endpoints (create, approve, reject, appeal resolution, payment recording)
**Example:**
```dart
// permission_helpers.dart (new file)
bool isFinesManager(Map<String, dynamic> team) {
  // Admin has all permissions including fines
  // OR user is explicitly a fine_boss
  return team['user_is_admin'] == true || team['user_is_fine_boss'] == true;
}

// Usage in fines_handler.dart
Future<Response> _createFine(Request request, String teamId) async {
  final userId = getUserId(request);
  if (userId == null) return resp.unauthorized();

  final team = await requireTeamMember(_teamService, teamId, userId);
  if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

  if (!isFinesManager(team)) {
    return resp.forbidden('Kun admin eller bøtesjef kan opprette bøter');
  }

  // ... rest of handler
}
```

### Pattern 4: Input Validation at Handler Boundary
**What:** Validate all inputs at handler level before calling service layer
**When to use:** Every POST/PATCH/PUT endpoint
**Example:**
```dart
// Extend validation_helpers.dart
String requireNonEmptyString(Map<String, dynamic> body, String key, {int? maxLength}) {
  final value = body[key];
  if (value == null || value is! String || value.trim().isEmpty) {
    throw BadRequestException('$key er påkrevd og kan ikke være tom');
  }
  if (maxLength != null && value.length > maxLength) {
    throw BadRequestException('$key kan ikke være lengre enn $maxLength tegn');
  }
  return value.trim();
}

// Usage in handler
Future<Response> _createActivity(Request request, String teamId) async {
  try {
    final body = await parseBody(request);

    // Validate at boundary
    final title = requireNonEmptyString(body, 'title', maxLength: 200);
    final type = requireEnum(body, 'type', ActivityType.fromString);
    final date = body['date'] != null
      ? DateTime.tryParse(body['date']) ?? throw BadRequestException('Ugyldig dato format')
      : throw BadRequestException('date er påkrevd');

    // Now pass validated data to service
    final activity = await _activityService.create(...);
    return resp.ok(activity.toJson());
  } on BadRequestException catch (e) {
    return resp.badRequest(e.message);
  }
}
```

### Anti-Patterns to Avoid

- **Inconsistent permission checks:** Don't check isAdmin() in one place and user_role in another. Use helpers consistently.
- **Service-layer validation:** Don't defer validation to services. Handlers are the boundary; validate there.
- **Global rate limiting only:** Don't apply same rate limit to login and health check. Use endpoint-specific limits.
- **Forgetting 429 headers:** Rate limit responses should include `Retry-After` header (shelf_limiter does this automatically).
- **IP-only rate limiting for authed routes:** For authenticated endpoints, consider user-based rate limiting using clientIdentifierExtractor.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Rate limiting | Custom request counter with Map<IP, List<Timestamp>> | shelf_limiter | Clock skew, memory leaks, distributed state, proper 429 responses, sliding windows |
| Input validation | Scattered if/throw checks | validation_helpers.dart extensions | Consistency, reusability, centralized error messages |
| Request mocking in tests | Manual Request construction with all headers | mocktail package | Type safety, auto-stubbing, cleaner test code |
| Permission checks | Inline role string comparisons | Helper functions in auth_helpers/permission_helpers | Single source of truth, easier refactoring, audit trail |

**Key insight:** Rate limiting is deceptively complex. Edge cases include distributed servers (need shared state like Redis), clock skew between servers, memory growth from tracking too many IPs, and sliding vs fixed windows. shelf_limiter handles these correctly; custom solutions miss edge cases and become maintenance burdens.

## Common Pitfalls

### Pitfall 1: Rate Limiting After Authentication
**What goes wrong:** Placing rate limiter after auth middleware means attackers can attempt unlimited logins without rate limits.
**Why it happens:** Natural pipeline order is auth → rate limit → handler, but auth endpoints need rate limiting before/without auth.
**How to avoid:** Apply rate limiting to auth routes BEFORE or WITHOUT auth middleware. Auth routes should be: rate limit → handler.
**Warning signs:** Brute force attacks succeed, login endpoint has no 429 responses in logs.

### Pitfall 2: Forgetting fine_boss on All Mutation Endpoints
**What goes wrong:** Adding permission check to createFine but forgetting approveFine, rejectFine, resolveAppeal, recordPayment leaves authorization gaps.
**Why it happens:** Many small mutation endpoints scattered across handlers.
**How to avoid:** Audit all fine-related POST/PATCH/DELETE endpoints systematically. Create checklist from fines_handler.dart router.
**Warning signs:** Regular users can approve fines, payment endpoints accessible to players.

### Pitfall 3: Dual-Check Inconsistency After Consolidation
**What goes wrong:** Removing user_role check from isAdmin() but database still has rows where user_is_admin=false AND user_role='admin', breaking access.
**Why it happens:** Data migration lag behind code changes.
**How to avoid:** Run data consistency check: `SELECT * FROM team_members WHERE role='admin' AND is_admin=false;` Fix inconsistencies BEFORE deploying consolidated check.
**Warning signs:** Existing admins suddenly lose access, support tickets about "I'm admin but can't access".

### Pitfall 4: Validation on Wrong Layer
**What goes wrong:** Handler passes raw body to service, service validates and throws, error bubbles up as generic 500 instead of 400.
**Why it happens:** Trying to keep handlers thin by pushing logic to services.
**How to avoid:** Handlers own the HTTP boundary. Validate inputs, return 400s. Services own business logic, assume valid inputs.
**Warning signs:** Users see "En feil oppstod" for invalid inputs instead of specific field errors.

### Pitfall 5: Testing Rate Limits Without Time Simulation
**What goes wrong:** Tests call endpoint 6 times expecting 429 on 6th, but test clock doesn't advance, all requests in same window.
**Why it happens:** Rate limiter uses Duration, tests don't mock/control time.
**How to avoid:** Use fake timers or sleep() in tests. Better: shelf_limiter's window tracking allows testing by making requests, waiting windowSize+1ms, making more requests.
**Warning signs:** Rate limit tests flaky or passing when they shouldn't.

## Code Examples

Verified patterns from official sources and codebase:

### Basic Rate Limiter Setup
```dart
// Source: https://pub.dev/packages/shelf_limiter
import 'package:shelf_limiter/shelf_limiter.dart';

final rateLimiter = shelfLimiter(
  RateLimiterOptions(
    maxRequests: 5,
    windowSize: Duration(minutes: 1),
    onRateLimitExceeded: (request, identifier) {
      print('Rate limit exceeded for $identifier');
    },
  ),
);

// Apply to route
router.mount('/auth',
  const Pipeline()
    .addMiddleware(rateLimiter)
    .addHandler(authHandler.router.call)
    .call
);
```

### Endpoint-Specific Rate Limiting
```dart
// Source: https://pub.dev/packages/shelf_limiter
final limiters = {
  '/auth/login': RateLimiterOptions(maxRequests: 5, windowSize: Duration(minutes: 1)),
  '/auth/register': RateLimiterOptions(maxRequests: 3, windowSize: Duration(hours: 1)),
  '/messages/*': RateLimiterOptions(maxRequests: 20, windowSize: Duration(minutes: 1)),
  '/exports/*': RateLimiterOptions(maxRequests: 5, windowSize: Duration(minutes: 5)),
};

final endpointLimiter = shelfLimiterByEndpoint(limiters);
```

### User-Based Rate Limiting (Not IP)
```dart
// Source: https://pub.dev/documentation/shelf_limiter/latest/
final userBasedLimiter = shelfLimiter(
  RateLimiterOptions(
    maxRequests: 100,
    windowSize: Duration(hours: 1),
    clientIdentifierExtractor: (request) {
      // For authenticated routes, use userId instead of IP
      final userId = request.context['userId'] as String?;
      return userId ?? request.headers['x-forwarded-for'] ?? 'unknown';
    },
  ),
);
```

### Testing Shelf Middleware
```dart
// Source: https://dart-frog.dev/basics/testing/ (Dart Frog builds on Shelf)
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shelf/shelf.dart';

class MockRequest extends Mock implements Request {}

void main() {
  test('rate limiter blocks after maxRequests', () async {
    final limiter = shelfLimiter(
      RateLimiterOptions(maxRequests: 2, windowSize: Duration(seconds: 60)),
    );

    final handler = limiter((request) => Response.ok('success'));

    final request = Request('GET', Uri.parse('http://localhost/test'));

    // First two succeed
    expect((await handler(request)).statusCode, equals(200));
    expect((await handler(request)).statusCode, equals(200));

    // Third fails
    expect((await handler(request)).statusCode, equals(429));
  });
}
```

### Consolidated Permission Checks
```dart
// Current state in auth_helpers.dart
bool isAdmin(Map<String, dynamic> team) {
  return team['user_is_admin'] == true || team['user_role'] == 'admin';
}

// After consolidation (remove OR check)
bool isAdmin(Map<String, dynamic> team) {
  return team['user_is_admin'] == true;
}

// New helper in permission_helpers.dart
bool isFinesManager(Map<String, dynamic> team) {
  return team['user_is_admin'] == true || team['user_is_fine_boss'] == true;
}

bool isCoachOrAdmin(Map<String, dynamic> team) {
  return team['user_is_admin'] == true || team['user_is_coach'] == true;
}
```

### Extended Validation Helpers
```dart
// Add to existing validation_helpers.dart
String requireEmail(Map<String, dynamic> body, String key) {
  final value = requireString(body, key);
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) {
    throw BadRequestException('Ugyldig e-postadresse');
  }
  return value;
}

String requireNonEmptyString(Map<String, dynamic> body, String key, {int? maxLength}) {
  final value = requireString(body, key);
  if (value.trim().isEmpty) {
    throw BadRequestException('$key kan ikke være tom');
  }
  if (maxLength != null && value.length > maxLength) {
    throw BadRequestException('$key kan ikke være lengre enn $maxLength tegn');
  }
  return value.trim();
}

List<String> requireNonEmptyList(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value == null || value is! List || value.isEmpty) {
    throw BadRequestException('$key må være en liste med minst ett element');
  }
  return value.cast<String>();
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Role string enum (admin/coach/player) | Boolean permission flags (is_admin, is_fine_boss, is_coach) | Phase 2 (completed) | More granular permissions, admin can grant fine_boss without full admin |
| No rate limiting | shelf_limiter middleware | This phase | Prevents brute force, abuse, DoS |
| Scattered validation in services | Validation at handler boundary | Phase 15 (partial) | This phase completes it |
| user_role string comparisons | Helper functions (isAdmin, isFinesManager) | Phase 1 (isAdmin), this phase (rest) | Single source of truth, easier auditing |

**Deprecated/outdated:**
- **user_role string field:** Still in database for backwards compatibility but not authoritative. Use boolean flags.
- **shelf_rate_limiter package:** Last updated 2022, superseded by shelf_limiter for better features.
- **Global throttling:** shelf_throttle offers only global limits; endpoint-specific is now standard.

## Open Questions

1. **Should rate limiting be user-based or IP-based for authenticated routes?**
   - What we know: shelf_limiter supports both via clientIdentifierExtractor. IP-based is default, user-based prevents single user with multiple IPs from bypassing limits.
   - What's unclear: Performance impact of user-based tracking (more keys in memory), and whether mobile clients with changing IPs cause UX issues.
   - Recommendation: Start with IP-based for auth endpoints (pre-authentication), user-based for authenticated mutation endpoints. Monitor and adjust.

2. **How to handle data consistency for existing team_members with role='admin' but is_admin=false?**
   - What we know: Dual-check exists for backwards compatibility. Need to remove it.
   - What's unclear: How many inconsistent rows exist, whether they're from old bugs or intentional partial migrations.
   - Recommendation: Run SQL audit query, fix inconsistencies with UPDATE statement before deploying consolidated check. Add migration script to planning.

3. **Which fine endpoints need fine_boss checks vs admin-only?**
   - What we know: Create, approve, reject, resolve appeals, record payments are mutations. Viewing fines/history is read-only.
   - What's unclear: Should fine_boss be able to delete fine rules, or is that admin-only?
   - Recommendation: Fine rules are configuration → admin-only. Fine operations (CRUD on individual fines) → fine_boss. Document in permission matrix.

4. **Should export endpoints have stricter rate limiting than data queries?**
   - What we know: Exports are GET requests but resource-intensive (aggregate data, potentially large responses).
   - What's unclear: Actual resource usage, whether 5 per 5 minutes is too strict or too lenient.
   - Recommendation: Start conservative (5 per 5 min), monitor backend logs for export frequency patterns, adjust if UX suffers.

## Sources

### Primary (HIGH confidence)
- [shelf_limiter package](https://pub.dev/packages/shelf_limiter) - rate limiting configuration, examples
- [RateLimiterOptions API docs](https://pub.dev/documentation/shelf_limiter/latest/shelf_limiter/RateLimiterOptions-class.html) - configuration parameters
- [Dart linter rules](https://dart.dev/tools/linter-rules) - static analysis best practices
- Codebase files: `auth_helpers.dart`, `validation_helpers.dart`, `fines_handler.dart`, `team_service.dart`, `parsing_helpers.dart`

### Secondary (MEDIUM confidence)
- [Dart Frog testing guide](https://dart-frog.dev/basics/testing/) - middleware testing patterns
- [Backend validation fundamentals](https://docs.globe.dev/tutorials/what-is-backend-validation) - three-level validation approach
- [API security best practices 2026](https://www.levo.ai/resources/blogs/rest-api-security-best-practices) - authentication, authorization patterns
- [Rate limiting concepts](https://www.cloudflare.com/learning/bots/what-is-rate-limiting/) - IP vs user-based approaches

### Tertiary (LOW confidence)
- [shelf_rate_limiter](https://pub.dev/documentation/shelf_rate_limiter/latest/) - alternative rate limiter (older)
- [shelf_throttle](https://pub.dev/packages/shelf_throttle) - global throttling alternative

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - shelf_limiter is actively maintained, well-documented, widely used
- Architecture: HIGH - patterns verified against existing codebase structure and Shelf documentation
- Pitfalls: MEDIUM-HIGH - based on general API security best practices, some project-specific (data consistency)
- Input validation: HIGH - extends existing patterns from validation_helpers.dart

**Research date:** 2026-02-09
**Valid until:** March 2026 (stable domain, rate limiting patterns well-established)

**Notes:**
- Existing codebase has strong validation foundation (parsing_helpers, validation_helpers)
- Auth middleware and helper functions already established
- Role system mid-migration (dual-check exists for backwards compatibility)
- 268 backend tests passing, strong test coverage foundation
- No existing rate limiting or fine_boss permission checks (greenfield for these features)
