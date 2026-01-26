import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:core_idrett_backend/api/router.dart';
import 'package:core_idrett_backend/db/database.dart';

Future<void> main() async {
  final db = Database();
  await db.connect();

  final app = createRouter(db);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addMiddleware(_jsonContentType())
      .addHandler(app.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  print('Server running on http://${server.address.host}:${server.port}');
}

Middleware _corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }

      final response = await handler(request);
      return response.change(headers: _corsHeaders);
    };
  };
}

Middleware _jsonContentType() {
  return (Handler handler) {
    return (Request request) async {
      final response = await handler(request);
      if (response.headers['content-type'] == null) {
        return response.change(headers: {'content-type': 'application/json'});
      }
      return response;
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};
