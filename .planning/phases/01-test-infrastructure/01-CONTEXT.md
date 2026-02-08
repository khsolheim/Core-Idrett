# Phase 1: Test Infrastructure - Context

**Gathered:** 2026-02-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish comprehensive test foundation for both backend and frontend: test data factories, mock database infrastructure, model roundtrip tests, and shared test helpers. This enables safe refactoring in all subsequent phases. No feature changes — pure test infrastructure.

</domain>

<decisions>
## Implementation Decisions

### Test Data Strategy
- Factories cover ALL core models from day one: User, Team, TeamMember, Activity, MiniActivity, Fine, Message, Tournament, Achievement (and sub-models)
- Test data uses realistic Norwegian names and data (e.g., 'Ola Nordmann', 'ola@example.no') — not obvious test markers
- Mocking library: Mockito (package:mockito) with @GenerateMocks

### Model Roundtrip Scope
- Roundtrip tests cover BOTH backend and frontend models
- Roundtrip = structural equality: `fromJson(toJson(model)) == model`
- Models get == operator and hashCode implementation (equatable or manual) to enable clean assertions
- Each model tested with TWO variants: all optional fields null, and all fields populated

### Test Organization & Naming
- Shared test helpers centralized: `test/helpers/` for backend, `test/helpers/` for frontend
- Test file names mirror source file names: `user_service_test.dart` for `user_service.dart`
- Test directory structure mirrors `lib/` exactly: `test/services/team_service_test.dart` for `lib/services/team_service.dart`
- Test descriptions (group/test names) in Norwegian: `group('Brukerservice')`, `test('returnerer bruker fra id')`

### Claude's Discretion
- Factory pattern: simple functions vs builder pattern — pick what fits the codebase best
- Valid-only factories vs including invalid-state helpers — determine based on test suite needs
- Mock database approach: stubbed responses vs in-memory fake — pick what catches real bugs
- Service test isolation level: full isolation vs allowing integration between services
- Auth mock infrastructure: whether to include auth middleware test helpers or test auth separately

</decisions>

<specifics>
## Specific Ideas

- Norwegian test descriptions is a deliberate choice matching the project's Norwegian-first philosophy for user/developer-facing text
- Code/comments remain in English per existing CLAUDE.md conventions — only test group/test names are Norwegian
- All core entity models should have factories ready from day one, not incrementally added

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-test-infrastructure*
*Context gathered: 2026-02-08*
