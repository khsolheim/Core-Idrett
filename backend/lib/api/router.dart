import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db/database.dart';
import '../services/auth_service.dart';
import '../services/team_service.dart';
import '../services/activity_service.dart';
import '../services/activity_instance_service.dart';
import '../services/mini_activity_service.dart';
import '../services/mini_activity_template_service.dart';
import '../services/mini_activity_division_service.dart';
import '../services/mini_activity_result_service.dart';
import '../services/statistics_service.dart';
import '../services/fine_service.dart';
import '../services/season_service.dart';
import '../services/leaderboard_service.dart';
import '../services/leaderboard_entry_service.dart';
import '../services/team_member_service.dart';
import '../services/test_service.dart';
import '../services/notification_service.dart';
import '../services/message_service.dart';
import '../services/document_service.dart';
import '../services/export_service.dart';
import '../services/tournament_service.dart';
import '../services/tournament_group_service.dart';
import '../services/stopwatch_service.dart';
import '../services/mini_activity_statistics_service.dart';
import '../services/points_config_service.dart';
import '../services/absence_service.dart';
import '../services/achievement_service.dart';
import 'middleware/auth_middleware.dart';
import 'auth_handler.dart';
import 'teams_handler.dart';
import 'activities_handler.dart';
import 'mini_activities_handler.dart';
import 'statistics_handler.dart';
import 'fines_handler.dart';
import 'seasons_handler.dart';
import 'leaderboards_handler.dart';
import 'tests_handler.dart';
import 'notifications_handler.dart';
import 'messages_handler.dart';
import 'documents_handler.dart';
import 'exports_handler.dart';
import 'tournaments_handler.dart';
import 'stopwatch_handler.dart';
import 'mini_activity_statistics_handler.dart';
import 'points_config_handler.dart';
import 'absence_handler.dart';
import 'achievements_handler.dart';

Router createRouter(Database db) {
  final authService = AuthService(db);
  final teamService = TeamService(db);
  final teamMemberService = TeamMemberService(db);
  final seasonService = SeasonService(db);
  final leaderboardEntryService = LeaderboardEntryService(db);
  final leaderboardService = LeaderboardService(db, leaderboardEntryService);
  final activityService = ActivityService(db);
  final activityInstanceService = ActivityInstanceService(db, leaderboardService, seasonService);
  final miniActivityService = MiniActivityService(db);
  final miniActivityTemplateService = MiniActivityTemplateService(db);
  final miniActivityDivisionService = MiniActivityDivisionService(db);
  final miniActivityResultService = MiniActivityResultService(db, leaderboardService, seasonService);
  final statisticsService = StatisticsService(db);
  final fineService = FineService(db);
  final testService = TestService(db);
  final notificationService = NotificationService(db);
  final messageService = MessageService(db);
  final documentService = DocumentService(db);
  final exportService = ExportService(db);
  final tournamentGroupService = TournamentGroupService(db);
  final tournamentService = TournamentService(db, tournamentGroupService);
  final stopwatchService = StopwatchService(db);
  final miniActivityStatisticsService = MiniActivityStatisticsService(db);
  final pointsConfigService = PointsConfigService(db);
  final absenceService = AbsenceService(db);
  final achievementService = AchievementService(db);

  // Auth middleware for protected routes
  final auth = requireAuth(authService);

  final router = Router();

  // Auth routes (no middleware - handles its own auth)
  final authHandler = AuthHandler(authService);
  router.mount('/auth', authHandler.router.call);

  // Protected routes - wrapped with auth middleware
  final teamsHandler = TeamsHandler(teamService, teamMemberService);
  router.mount('/teams', const Pipeline().addMiddleware(auth).addHandler(teamsHandler.router.call).call);

  final activitiesHandler = ActivitiesHandler(activityService, activityInstanceService, teamService);
  router.mount('/activities', const Pipeline().addMiddleware(auth).addHandler(activitiesHandler.router.call).call);

  final miniActivitiesHandler = MiniActivitiesHandler(
    miniActivityService,
    miniActivityTemplateService,
    miniActivityDivisionService,
    miniActivityResultService,
    teamService,
    miniActivityStatisticsService,
  );
  router.mount('/mini-activities', const Pipeline().addMiddleware(auth).addHandler(miniActivitiesHandler.router.call).call);

  final tournamentsHandler = TournamentsHandler(tournamentService, tournamentGroupService, teamService);
  router.mount('/tournaments', const Pipeline().addMiddleware(auth).addHandler(tournamentsHandler.router.call).call);

  final stopwatchHandler = StopwatchHandler(stopwatchService, teamService);
  router.mount('/stopwatch', const Pipeline().addMiddleware(auth).addHandler(stopwatchHandler.router.call).call);

  final miniActivityStatsHandler = MiniActivityStatisticsHandler(
    miniActivityStatisticsService,
    teamService,
  );
  router.mount('/mini-activity-stats', const Pipeline().addMiddleware(auth).addHandler(miniActivityStatsHandler.router.call).call);

  final statisticsHandler = StatisticsHandler(statisticsService, teamService);
  router.mount('/statistics', const Pipeline().addMiddleware(auth).addHandler(statisticsHandler.router.call).call);

  final finesHandler = FinesHandler(fineService, teamService);
  router.mount('/fines', const Pipeline().addMiddleware(auth).addHandler(finesHandler.router.call).call);

  final seasonsHandler = SeasonsHandler(seasonService, teamService);
  router.mount('/seasons', const Pipeline().addMiddleware(auth).addHandler(seasonsHandler.router.call).call);

  final leaderboardsHandler = LeaderboardsHandler(leaderboardService, teamService);
  router.mount('/leaderboards', const Pipeline().addMiddleware(auth).addHandler(leaderboardsHandler.router.call).call);

  final pointsConfigHandler = PointsConfigHandler(pointsConfigService, teamService);
  router.mount('/points', const Pipeline().addMiddleware(auth).addHandler(pointsConfigHandler.router.call).call);

  final absenceHandler = AbsenceHandler(absenceService, teamService);
  router.mount('/absence', const Pipeline().addMiddleware(auth).addHandler(absenceHandler.router.call).call);

  final achievementsHandler = AchievementsHandler(achievementService, teamService);
  router.mount('/achievements', const Pipeline().addMiddleware(auth).addHandler(achievementsHandler.router.call).call);

  final testsHandler = TestsHandler(testService, teamService);
  router.mount('/tests', const Pipeline().addMiddleware(auth).addHandler(testsHandler.router.call).call);

  final notificationsHandler = NotificationsHandler(notificationService);
  router.mount('/notifications', const Pipeline().addMiddleware(auth).addHandler(notificationsHandler.router.call).call);

  final messagesHandler = MessagesHandler(messageService, teamService);
  router.mount('/messages', const Pipeline().addMiddleware(auth).addHandler(messagesHandler.router.call).call);

  final documentsHandler = DocumentsHandler(documentService, teamService);
  router.mount('/documents', const Pipeline().addMiddleware(auth).addHandler(documentsHandler.router.call).call);

  final exportsHandler = ExportsHandler(exportService, teamService);
  router.mount('/exports', const Pipeline().addMiddleware(auth).addHandler(exportsHandler.router.call).call);

  // Health check (no auth)
  router.get('/health', (request) {
    return Response.ok('{"status": "ok"}');
  });

  return router;
}
