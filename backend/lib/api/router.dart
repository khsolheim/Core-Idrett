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
import '../services/match_stats_service.dart';
import '../services/fine_service.dart';
import '../services/season_service.dart';
import '../services/leaderboard_service.dart';
import '../services/leaderboard_entry_service.dart';
import '../services/team_member_service.dart';
import '../services/test_service.dart';
import '../services/notification_service.dart';
import '../services/message_service.dart';
import '../services/team_chat_service.dart';
import '../services/direct_message_service.dart';
import '../services/document_service.dart';
import '../services/export_service.dart';
import '../services/tournament_service.dart';
import '../services/tournament_group_service.dart';
import '../services/stopwatch_service.dart';
import '../services/mini_activity_statistics_service.dart';
import '../services/points_config_service.dart';
import '../services/absence_service.dart';
import '../services/achievement_service.dart';
import '../services/achievement_definition_service.dart';
import '../services/achievement_progress_service.dart';
import '../services/user_service.dart';
import '../services/dashboard_service.dart';
import '../services/player_rating_service.dart';
import 'middleware/auth_middleware.dart';
import 'middleware/rate_limit_middleware.dart';
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
  final userService = UserService(db);
  final teamService = TeamService(db);
  final dashboardService = DashboardService(db, userService);
  final teamMemberService = TeamMemberService(db);
  final seasonService = SeasonService(db);
  final leaderboardEntryService = LeaderboardEntryService(db, userService);
  final leaderboardCrudService = LeaderboardCrudService(db, leaderboardEntryService);
  final leaderboardCategoryService = LeaderboardCategoryService(db);
  final leaderboardRankingService = LeaderboardRankingService(
    db, leaderboardCrudService, leaderboardCategoryService, teamService,
  );
  final activityCrudService = ActivityCrudService(db);
  final activityQueryService = ActivityQueryService(db, userService);
  final activityInstanceService = ActivityInstanceService(db, leaderboardCrudService, seasonService);
  final miniActivityService = MiniActivityService(db, userService);
  final miniActivityTemplateService = MiniActivityTemplateService(db);
  final miniActivityDivisionAlgorithmService = MiniActivityDivisionAlgorithmService(db);
  final miniActivityDivisionManagementService = MiniActivityDivisionManagementService(db);
  final miniActivityResultService = MiniActivityResultService(db, leaderboardCrudService, seasonService);
  final playerRatingService = PlayerRatingService(db);
  final matchStatsService = MatchStatsService(db, userService);
  final statisticsService = StatisticsService(db, userService, teamService, playerRatingService);
  final fineRuleService = FineRuleService(db);
  final fineCrudService = FineCrudService(db, userService);
  final fineSummaryService = FineSummaryService(db, userService, teamService);
  final testService = TestService(db, userService);
  final notificationService = NotificationService(db);
  final teamChatService = TeamChatService(db, userService);
  final directMessageService = DirectMessageService(db, userService);
  final messageService = MessageService(db, userService);
  final documentService = DocumentService(db, userService);
  final exportDataService = ExportDataService(db);
  final exportUtilityService = ExportUtilityService(db);
  final tournamentGroupService = TournamentGroupService(db);
  final tournamentCrudService = TournamentCrudService(db);
  final tournamentRoundsService = TournamentRoundsService(db);
  final tournamentMatchesService = TournamentMatchesService(db);
  final tournamentBracketService = TournamentBracketService(
    db, tournamentCrudService, tournamentRoundsService, tournamentMatchesService, tournamentGroupService,
  );
  final stopwatchService = StopwatchService(db, userService);
  final miniActivityPlayerStatsService = MiniActivityPlayerStatsService(db);
  final miniActivityHeadToHeadService = MiniActivityHeadToHeadService(db);
  final miniActivityStatsAggregationService = MiniActivityStatsAggregationService(
    db, miniActivityPlayerStatsService, miniActivityHeadToHeadService, userService,
  );
  final pointsConfigCrudService = PointsConfigCrudService(db);
  final attendancePointsService = AttendancePointsService(db);
  final manualAdjustmentService = ManualAdjustmentService(db);
  final absenceService = AbsenceService(db);
  final achievementDefinitionService = AchievementDefinitionService(db);
  final achievementService = AchievementService(db, achievementDefinitionService);
  final achievementProgressService = AchievementProgressService(
    db,
    achievementDefinitionService,
    achievementService,
  );

  // Auth middleware for protected routes
  final auth = requireAuth(authService);

  final router = Router();

  // Auth routes (rate limited to prevent brute-force)
  final authHandler = AuthHandler(authService);
  router.mount('/auth',
    const Pipeline()
      .addMiddleware(authRateLimiter)
      .addHandler(authHandler.router.call)
      .call
  );

  // Protected routes - wrapped with auth middleware
  final teamsHandler = TeamsHandler(teamService, teamMemberService, dashboardService);
  router.mount('/teams', const Pipeline().addMiddleware(auth).addHandler(teamsHandler.router.call).call);

  final activitiesHandler = ActivitiesHandler(activityCrudService, activityQueryService, activityInstanceService, teamService);
  router.mount('/activities', const Pipeline().addMiddleware(auth).addHandler(activitiesHandler.router.call).call);

  final miniActivitiesHandler = MiniActivitiesHandler(
    miniActivityService,
    miniActivityTemplateService,
    miniActivityDivisionAlgorithmService,
    miniActivityDivisionManagementService,
    miniActivityResultService,
    teamService,
    miniActivityStatsAggregationService,
  );
  router.mount('/mini-activities', const Pipeline().addMiddleware(auth).addHandler(miniActivitiesHandler.router.call).call);

  final tournamentsHandler = TournamentsHandler(
    tournamentCrudService, tournamentRoundsService, tournamentMatchesService,
    tournamentBracketService, tournamentGroupService, teamService,
  );
  router.mount('/tournaments', const Pipeline().addMiddleware(auth).addHandler(tournamentsHandler.router.call).call);

  final stopwatchHandler = StopwatchHandler(stopwatchService, teamService);
  router.mount('/stopwatch', const Pipeline().addMiddleware(auth).addHandler(stopwatchHandler.router.call).call);

  final miniActivityStatsHandler = MiniActivityStatisticsHandler(
    miniActivityPlayerStatsService,
    miniActivityHeadToHeadService,
    miniActivityStatsAggregationService,
    teamService,
  );
  router.mount('/mini-activity-stats', const Pipeline().addMiddleware(auth).addHandler(miniActivityStatsHandler.router.call).call);

  final statisticsHandler = StatisticsHandler(statisticsService, matchStatsService, teamService);
  router.mount('/statistics', const Pipeline().addMiddleware(auth).addHandler(statisticsHandler.router.call).call);

  final finesHandler = FinesHandler(fineRuleService, fineCrudService, fineSummaryService, teamService);
  router.mount('/fines', const Pipeline().addMiddleware(auth).addMiddleware(mutationRateLimiter).addHandler(finesHandler.router.call).call);

  final seasonsHandler = SeasonsHandler(seasonService, teamService);
  router.mount('/seasons', const Pipeline().addMiddleware(auth).addHandler(seasonsHandler.router.call).call);

  final leaderboardsHandler = LeaderboardsHandler(
    leaderboardCrudService, leaderboardRankingService, teamService,
  );
  router.mount('/leaderboards', const Pipeline().addMiddleware(auth).addHandler(leaderboardsHandler.router.call).call);

  final pointsConfigHandler = PointsConfigHandler(
    pointsConfigCrudService, attendancePointsService, manualAdjustmentService, teamService,
  );
  router.mount('/points', const Pipeline().addMiddleware(auth).addHandler(pointsConfigHandler.router.call).call);

  final absenceHandler = AbsenceHandler(absenceService, teamService);
  router.mount('/absence', const Pipeline().addMiddleware(auth).addHandler(absenceHandler.router.call).call);

  final achievementsHandler = AchievementsHandler(
    achievementDefinitionService,
    achievementService,
    achievementProgressService,
    teamService,
  );
  router.mount('/achievements', const Pipeline().addMiddleware(auth).addHandler(achievementsHandler.router.call).call);

  final testsHandler = TestsHandler(testService, teamService);
  router.mount('/tests', const Pipeline().addMiddleware(auth).addHandler(testsHandler.router.call).call);

  final notificationsHandler = NotificationsHandler(notificationService);
  router.mount('/notifications', const Pipeline().addMiddleware(auth).addHandler(notificationsHandler.router.call).call);

  final messagesHandler = MessagesHandler(messageService, teamChatService, directMessageService, teamService);
  router.mount('/messages', const Pipeline().addMiddleware(auth).addMiddleware(mutationRateLimiter).addHandler(messagesHandler.router.call).call);

  final documentsHandler = DocumentsHandler(documentService, teamService);
  router.mount('/documents', const Pipeline().addMiddleware(auth).addHandler(documentsHandler.router.call).call);

  final exportsHandler = ExportsHandler(exportDataService, exportUtilityService, teamService);
  router.mount('/exports', const Pipeline().addMiddleware(auth).addMiddleware(exportRateLimiter).addHandler(exportsHandler.router.call).call);

  // Health check (no auth)
  router.get('/health', (request) {
    return Response.ok('{"status": "ok"}');
  });

  return router;
}
