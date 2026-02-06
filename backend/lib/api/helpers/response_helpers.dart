import 'dart:convert';
import 'package:shelf/shelf.dart';

const _jsonHeaders = {'Content-Type': 'application/json'};

Response ok(dynamic data) => Response.ok(
      jsonEncode(data),
      headers: _jsonHeaders,
    );

Response unauthorized([String? msg]) => Response(401,
      body: jsonEncode({'error': msg ?? 'Ikke autentisert'}),
      headers: _jsonHeaders,
    );

Response forbidden([String? msg]) => Response(403,
      body: jsonEncode({'error': msg ?? 'Ingen tilgang'}),
      headers: _jsonHeaders,
    );

Response badRequest(String msg) => Response(400,
      body: jsonEncode({'error': msg}),
      headers: _jsonHeaders,
    );

Response notFound([String? msg]) => Response(404,
      body: jsonEncode({'error': msg ?? 'Ikke funnet'}),
      headers: _jsonHeaders,
    );

Response serverError([String? msg]) => Response.internalServerError(
      body: jsonEncode({'error': msg ?? 'En feil oppstod'}),
      headers: _jsonHeaders,
    );
