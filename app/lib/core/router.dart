import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/teams/presentation/teams_screen.dart';
import '../features/teams/presentation/team_detail_screen.dart';
import '../features/teams/presentation/create_team_screen.dart';
import '../features/teams/presentation/edit_team_screen.dart';
import '../features/activities/presentation/activities_screen.dart';
import '../features/activities/presentation/activity_detail_screen.dart';
import '../features/activities/presentation/create_activity_screen.dart';
import '../features/activities/presentation/edit_instance_screen.dart';
import '../features/activities/presentation/calendar_screen.dart';
import '../data/models/activity.dart';
import '../features/mini_activities/presentation/templates_screen.dart';
import '../features/mini_activities/presentation/mini_activity_detail_screen.dart';
import '../features/statistics/presentation/leaderboard_screen.dart';
import '../features/statistics/presentation/attendance_screen.dart';
import '../features/statistics/presentation/player_profile_screen.dart';
import '../features/fines/presentation/fines_screen.dart';
import '../features/fines/presentation/fine_rules_screen.dart';
import '../features/fines/presentation/fine_boss_screen.dart';
import '../features/fines/presentation/my_fines_screen.dart';
import '../features/fines/presentation/team_accounting_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/chat/presentation/unified_chat_screen.dart';
import '../features/documents/presentation/documents_screen.dart';
import '../features/export/presentation/export_screen.dart';
import '../features/tests/presentation/tests_screen.dart';
import '../features/tests/presentation/test_detail_screen.dart';
import '../features/points/presentation/points_config_screen.dart';
import '../features/achievements/presentation/achievements_screen.dart';
import '../features/achievements/presentation/achievement_admin_screen.dart';
import '../features/absence/presentation/absence_management_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation.startsWith('/invite/');

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/teams';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/invite/:code',
        name: 'invite',
        builder: (context, state) {
          final code = state.pathParameters['code']!;
          return RegisterScreen(inviteCode: code);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/teams',
        name: 'teams',
        builder: (context, state) => const TeamsScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'create-team',
            builder: (context, state) => const CreateTeamScreen(),
          ),
          GoRoute(
            path: ':teamId',
            name: 'team-detail',
            builder: (context, state) {
              final teamId = state.pathParameters['teamId']!;
              return TeamDetailScreen(teamId: teamId);
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: 'edit-team',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  return EditTeamScreen(teamId: teamId);
                },
              ),
              GoRoute(
                path: 'templates',
                name: 'templates',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  return TemplatesScreen(teamId: teamId);
                },
              ),
              GoRoute(
                path: 'leaderboard',
                name: 'leaderboard',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  return LeaderboardScreen(teamId: teamId);
                },
              ),
              GoRoute(
                path: 'attendance',
                name: 'attendance',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  return AttendanceScreen(teamId: teamId);
                },
              ),
              GoRoute(
                path: 'player/:userId',
                name: 'player-profile',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  final userId = state.pathParameters['userId']!;
                  return PlayerProfileScreen(teamId: teamId, userId: userId);
                },
              ),
              GoRoute(
                path: 'calendar',
                name: 'calendar',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  return CalendarScreen(teamId: teamId);
                },
              ),
              GoRoute(
                path: 'chat',
                name: 'chat',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  return UnifiedChatScreen(teamId: teamId);
                },
              ),
              GoRoute(
                path: 'documents',
                name: 'documents',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  return DocumentsScreen(teamId: teamId);
                },
              ),
              GoRoute(
                path: 'export',
                name: 'export',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  final isAdmin = state.uri.queryParameters['admin'] == 'true';
                  return ExportScreen(teamId: teamId, isAdmin: isAdmin);
                },
              ),
              GoRoute(
                path: 'tests',
                name: 'tests',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  final isAdmin = state.uri.queryParameters['admin'] == 'true';
                  return TestsScreen(teamId: teamId, isAdmin: isAdmin);
                },
                routes: [
                  GoRoute(
                    path: ':templateId',
                    name: 'test-detail',
                    builder: (context, state) {
                      final teamId = state.pathParameters['teamId']!;
                      final templateId = state.pathParameters['templateId']!;
                      final isAdmin = state.uri.queryParameters['admin'] == 'true';
                      return TestDetailScreen(
                        teamId: teamId,
                        templateId: templateId,
                        isAdmin: isAdmin,
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'activities',
                name: 'activities',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  return ActivitiesScreen(teamId: teamId);
                },
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'create-activity',
                    builder: (context, state) {
                      final teamId = state.pathParameters['teamId']!;
                      return CreateActivityScreen(teamId: teamId);
                    },
                  ),
                  GoRoute(
                    path: ':instanceId',
                    name: 'activity-detail',
                    builder: (context, state) {
                      final teamId = state.pathParameters['teamId']!;
                      final instanceId = state.pathParameters['instanceId']!;
                      return ActivityDetailScreen(
                        teamId: teamId,
                        instanceId: instanceId,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: 'edit-instance',
                        builder: (context, state) {
                          final teamId = state.pathParameters['teamId']!;
                          final instanceId = state.pathParameters['instanceId']!;
                          final extra = state.extra as Map<String, dynamic>?;
                          final scope = extra?['scope'] as EditScope? ?? EditScope.single;
                          return EditInstanceScreen(
                            teamId: teamId,
                            instanceId: instanceId,
                            scope: scope,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'mini/:miniActivityId',
                        name: 'mini-activity-detail',
                        builder: (context, state) {
                          final teamId = state.pathParameters['teamId']!;
                          final instanceId = state.pathParameters['instanceId']!;
                          final miniActivityId = state.pathParameters['miniActivityId']!;
                          return MiniActivityDetailScreen(
                            miniActivityId: miniActivityId,
                            instanceId: instanceId,
                            teamId: teamId,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'fines',
                name: 'fines',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  return FinesScreen(teamId: teamId);
                },
                routes: [
                  GoRoute(
                    path: 'rules',
                    name: 'fine-rules',
                    builder: (context, state) {
                      final teamId = state.pathParameters['teamId']!;
                      return FineRulesScreen(teamId: teamId);
                    },
                  ),
                  GoRoute(
                    path: 'boss',
                    name: 'fine-boss',
                    builder: (context, state) {
                      final teamId = state.pathParameters['teamId']!;
                      return FineBossScreen(teamId: teamId);
                    },
                  ),
                  GoRoute(
                    path: 'mine',
                    name: 'my-fines',
                    builder: (context, state) {
                      final teamId = state.pathParameters['teamId']!;
                      return MyFinesScreen(teamId: teamId);
                    },
                  ),
                  GoRoute(
                    path: 'accounting',
                    name: 'team-accounting',
                    builder: (context, state) {
                      final teamId = state.pathParameters['teamId']!;
                      return TeamAccountingScreen(teamId: teamId);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'points-config',
                name: 'points-config',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  return PointsConfigScreen(teamId: teamId);
                },
              ),
              GoRoute(
                path: 'achievements',
                name: 'achievements',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  return AchievementsScreen(teamId: teamId);
                },
              ),
              GoRoute(
                path: 'achievements-admin',
                name: 'achievements-admin',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  return AchievementAdminScreen(teamId: teamId);
                },
              ),
              GoRoute(
                path: 'absence-management',
                name: 'absence-management',
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  return AbsenceManagementScreen(teamId: teamId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Side ikke funnet: ${state.error}'),
      ),
    ),
  );
});
