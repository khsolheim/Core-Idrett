import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db/database.dart';
import '../services/auth_service.dart';
import '../services/team_service.dart';
import '../services/activity_service.dart';
import '../services/mini_activity_service.dart';
import '../services/statistics_service.dart';
import '../services/fine_service.dart';
import 'auth_handler.dart';
import 'teams_handler.dart';
import 'activities_handler.dart';
import 'mini_activities_handler.dart';
import 'statistics_handler.dart';
import 'fines_handler.dart';

Router createRouter(Database db) {
  final authService = AuthService(db);
  final teamService = TeamService(db);
  final activityService = ActivityService(db);
  final miniActivityService = MiniActivityService(db);
  final statisticsService = StatisticsService(db);
  final fineService = FineService(db);

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
  final miniActivitiesHandler = MiniActivitiesHandler(miniActivityService, authService, teamService);
  router.mount('/mini-activities', miniActivitiesHandler.router.call);

  // Statistics routes
  final statisticsHandler = StatisticsHandler(statisticsService);
  router.mount('/statistics', statisticsHandler.router.call);

  // Fines routes
  final finesHandler = FinesHandler(fineService);
  router.mount('/fines', finesHandler.router.call);

  // Health check
  router.get('/health', (request) {
    return Response.ok('{"status": "ok"}');
  });

  return router;
}
