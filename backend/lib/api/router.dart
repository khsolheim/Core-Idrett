import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db/database.dart';
import '../services/auth_service.dart';
import '../services/team_service.dart';
import '../services/activity_service.dart';
import '../services/mini_activity_service.dart';
import '../services/statistics_service.dart';
import '../services/fine_service.dart';
import '../services/season_service.dart';
import '../services/leaderboard_service.dart';
import '../services/test_service.dart';
import '../services/notification_service.dart';
import '../services/message_service.dart';
import '../services/document_service.dart';
import '../services/export_service.dart';
import '../services/tournament_service.dart';
import '../services/stopwatch_service.dart';
import '../services/mini_activity_statistics_service.dart';
import '../services/points_config_service.dart';
import '../services/absence_service.dart';
import '../services/achievement_service.dart';
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
  final seasonService = SeasonService(db);
  final leaderboardService = LeaderboardService(db);
  final activityService = ActivityService(db, leaderboardService, seasonService);
  final miniActivityService = MiniActivityService(db, leaderboardService, seasonService);
  final statisticsService = StatisticsService(db);
  final fineService = FineService(db);
  final testService = TestService(db);
  final notificationService = NotificationService(db);
  final messageService = MessageService(db);
  final documentService = DocumentService(db);
  final exportService = ExportService(db);
  final tournamentService = TournamentService(db);
  final stopwatchService = StopwatchService(db);
  final miniActivityStatisticsService = MiniActivityStatisticsService(db);
  final pointsConfigService = PointsConfigService(db);
  final absenceService = AbsenceService(db);
  final achievementService = AchievementService(db);

  final router = Router();

  // Auth routes
  final authHandler = AuthHandler(authService);
  router.mount('/auth', authHandler.router.call);

  // Team routes
  final teamsHandler = TeamsHandler(teamService, authService);
  router.mount('/teams', teamsHandler.router.call);

  // Activity routes
  final activitiesHandler = ActivitiesHandler(activityService, authService, teamService);
  router.mount('/activities', activitiesHandler.router.call);

  // Mini-activity routes
  final miniActivitiesHandler = MiniActivitiesHandler(
    miniActivityService,
    authService,
    teamService,
    miniActivityStatisticsService,
  );
  router.mount('/mini-activities', miniActivitiesHandler.router.call);

  // Tournament routes
  final tournamentsHandler = TournamentsHandler(tournamentService, authService, teamService);
  router.mount('/tournaments', tournamentsHandler.router.call);

  // Stopwatch routes
  final stopwatchHandler = StopwatchHandler(stopwatchService, authService, teamService);
  router.mount('/stopwatch', stopwatchHandler.router.call);

  // Mini-activity statistics routes
  final miniActivityStatsHandler = MiniActivityStatisticsHandler(
    miniActivityStatisticsService,
    authService,
    teamService,
  );
  router.mount('/mini-activity-stats', miniActivityStatsHandler.router.call);

  // Statistics routes
  final statisticsHandler = StatisticsHandler(statisticsService);
  router.mount('/statistics', statisticsHandler.router.call);

  // Fines routes
  final finesHandler = FinesHandler(fineService, authService);
  router.mount('/fines', finesHandler.router.call);

  // Season routes
  final seasonsHandler = SeasonsHandler(seasonService, authService, teamService);
  router.mount('/seasons', seasonsHandler.router.call);

  // Leaderboard routes
  final leaderboardsHandler = LeaderboardsHandler(leaderboardService, authService, teamService);
  router.mount('/leaderboards', leaderboardsHandler.router.call);

  // Points config routes
  final pointsConfigHandler = PointsConfigHandler(pointsConfigService, authService, teamService);
  router.mount('/points', pointsConfigHandler.router.call);

  // Absence routes
  final absenceHandler = AbsenceHandler(absenceService, authService, teamService);
  router.mount('/absence', absenceHandler.router.call);

  // Achievement routes
  final achievementsHandler = AchievementsHandler(achievementService, authService, teamService);
  router.mount('/achievements', achievementsHandler.router.call);

  // Test routes
  final testsHandler = TestsHandler(testService, authService, teamService);
  router.mount('/tests', testsHandler.router.call);

  // Notification routes
  final notificationsHandler = NotificationsHandler(notificationService, authService);
  router.mount('/notifications', notificationsHandler.router.call);

  // Message routes
  final messagesHandler = MessagesHandler(messageService, authService, teamService);
  router.mount('/messages', messagesHandler.router.call);

  // Document routes
  final documentsHandler = DocumentsHandler(documentService, teamService);
  router.mount('/documents', documentsHandler.router.call);

  // Export routes
  final exportsHandler = ExportsHandler(exportService, teamService);
  router.mount('/exports', exportsHandler.router.call);

  // Health check
  router.get('/health', (request) {
    return Response.ok('{"status": "ok"}');
  });

  return router;
}
