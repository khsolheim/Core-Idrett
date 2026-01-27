import 'dart:convert';
import 'package:http/http.dart' as http;

class SupabaseClient {
  final String _baseUrl;
  final String _anonKey;
  final String _serviceKey;

  SupabaseClient({
    required String projectUrl,
    required String anonKey,
    required String serviceKey,
  })  : _baseUrl = projectUrl,
        _anonKey = anonKey,
        _serviceKey = serviceKey;

  Map<String, String> get _headers => {
        'apikey': _serviceKey,
        'Authorization': 'Bearer $_serviceKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  String get baseUrl => _baseUrl;
  String get anonKey => _anonKey;

  /// Execute a SELECT query
  Future<List<Map<String, dynamic>>> select(
    String table, {
    String? select,
    Map<String, String>? filters,
    String? order,
    int? limit,
    int? offset,
  }) async {
    final params = <String, String>{};
    if (select != null) params['select'] = select;
    if (order != null) params['order'] = order;
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();

    var url = '$_baseUrl/rest/v1/$table';

    // Add filters to URL
    final queryParams = <String>[];
    if (filters != null) {
      filters.forEach((key, value) {
        queryParams.add('$key=$value');
      });
    }
    params.forEach((key, value) {
      queryParams.add('$key=$value');
    });

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode >= 400) {
      throw SupabaseException('Select failed: ${response.body}', response.statusCode);
    }

    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Execute an INSERT query
  Future<List<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    final url = '$_baseUrl/rest/v1/$table';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode >= 400) {
      throw SupabaseException('Insert failed: ${response.body}', response.statusCode);
    }

    final result = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(result);
  }

  /// Execute an UPDATE query
  Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, String> filters,
  }) async {
    var url = '$_baseUrl/rest/v1/$table';

    final queryParams = <String>[];
    filters.forEach((key, value) {
      queryParams.add('$key=$value');
    });

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final response = await http.patch(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode >= 400) {
      throw SupabaseException('Update failed: ${response.body}', response.statusCode);
    }

    final result = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(result);
  }

  /// Execute a DELETE query
  Future<void> delete(
    String table, {
    required Map<String, String> filters,
  }) async {
    var url = '$_baseUrl/rest/v1/$table';

    final queryParams = <String>[];
    filters.forEach((key, value) {
      queryParams.add('$key=$value');
    });

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final response = await http.delete(Uri.parse(url), headers: _headers);

    if (response.statusCode >= 400) {
      throw SupabaseException('Delete failed: ${response.body}', response.statusCode);
    }
  }

  /// Execute a raw SQL query via RPC
  Future<dynamic> rpc(String functionName, {Map<String, dynamic>? params}) async {
    final url = '$_baseUrl/rest/v1/rpc/$functionName';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: params != null ? jsonEncode(params) : '{}',
    );

    if (response.statusCode >= 400) {
      throw SupabaseException('RPC failed: ${response.body}', response.statusCode);
    }

    return jsonDecode(response.body);
  }

  // ============ STORAGE API ============

  /// Generate a signed URL for downloading a file
  Future<String> createSignedUrl(String bucket, String path, int expiresIn) async {
    final url = '$_baseUrl/storage/v1/object/sign/$bucket/$path';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode({'expiresIn': expiresIn}),
    );

    if (response.statusCode >= 400) {
      throw SupabaseException('Failed to create signed URL: ${response.body}', response.statusCode);
    }

    final data = jsonDecode(response.body);
    final signedUrl = data['signedURL'] as String;
    return '$_baseUrl/storage/v1$signedUrl';
  }

  /// Upload a file to storage
  Future<String> uploadFile(String bucket, String path, List<int> bytes, String contentType) async {
    final url = '$_baseUrl/storage/v1/object/$bucket/$path';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'apikey': _serviceKey,
        'Authorization': 'Bearer $_serviceKey',
        'Content-Type': contentType,
        'x-upsert': 'true',
      },
      body: bytes,
    );

    if (response.statusCode >= 400) {
      throw SupabaseException('Upload failed: ${response.body}', response.statusCode);
    }

    return path;
  }

  /// Delete a file from storage
  Future<void> deleteFile(String bucket, String path) async {
    final url = '$_baseUrl/storage/v1/object/$bucket/$path';

    final response = await http.delete(
      Uri.parse(url),
      headers: _headers,
    );

    if (response.statusCode >= 400) {
      throw SupabaseException('Delete failed: ${response.body}', response.statusCode);
    }
  }

  /// Get public URL for a file (if bucket is public)
  String getPublicUrl(String bucket, String path) {
    return '$_baseUrl/storage/v1/object/public/$bucket/$path';
  }
}

class SupabaseException implements Exception {
  final String message;
  final int statusCode;

  SupabaseException(this.message, this.statusCode);

  @override
  String toString() => 'SupabaseException: $message (status: $statusCode)';
}
