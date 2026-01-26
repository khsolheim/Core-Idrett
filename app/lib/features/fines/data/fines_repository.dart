import '../../../data/api/api_client.dart';
import '../../../data/models/fine.dart';

class FinesRepository {
  final ApiClient _client;

  FinesRepository(this._client);

  // Fine Rules
  Future<List<FineRule>> getFineRules(String teamId, {bool? activeOnly}) async {
    final queryParams = activeOnly == true ? {'active': 'true'} : null;
    final response = await _client.get(
      '/fines/teams/$teamId/fine-rules',
      queryParameters: queryParams,
    );
    final data = response.data['rules'] as List;
    return data.map((e) => FineRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FineRule> createFineRule({
    required String teamId,
    required String name,
    required double amount,
    String? description,
  }) async {
    final response = await _client.post(
      '/fines/teams/$teamId/fine-rules',
      data: {
        'name': name,
        'amount': amount,
        'description': description,
      },
    );
    return FineRule.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FineRule> updateFineRule({
    required String ruleId,
    String? name,
    double? amount,
    String? description,
    bool? active,
  }) async {
    final response = await _client.patch(
      '/fines/fine-rules/$ruleId',
      data: {
        if (name != null) 'name': name,
        if (amount != null) 'amount': amount,
        if (description != null) 'description': description,
        if (active != null) 'active': active,
      },
    );
    return FineRule.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteFineRule(String ruleId) async {
    await _client.delete('/fines/fine-rules/$ruleId');
  }

  // Fines
  Future<List<Fine>> getFines(
    String teamId, {
    String? status,
    String? offenderId,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null) params['status'] = status;
    if (offenderId != null) params['offender_id'] = offenderId;

    final response = await _client.get(
      '/fines/teams/$teamId/fines',
      queryParameters: params,
    );
    final data = response.data['fines'] as List;
    return data.map((e) => Fine.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Fine> getFine(String fineId) async {
    final response = await _client.get('/fines/fines/$fineId');
    return Fine.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Fine> createFine({
    required String teamId,
    required String offenderId,
    String? ruleId,
    required double amount,
    String? description,
    String? evidenceUrl,
  }) async {
    final response = await _client.post(
      '/fines/teams/$teamId/fines',
      data: {
        'offender_id': offenderId,
        'rule_id': ruleId,
        'amount': amount,
        'description': description,
        'evidence_url': evidenceUrl,
      },
    );
    return Fine.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Fine> approveFine(String fineId) async {
    final response = await _client.patch('/fines/fines/$fineId/approve');
    return Fine.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Fine> rejectFine(String fineId) async {
    final response = await _client.patch('/fines/fines/$fineId/reject');
    return Fine.fromJson(response.data as Map<String, dynamic>);
  }

  // Appeals
  Future<FineAppeal> createAppeal({
    required String fineId,
    required String reason,
  }) async {
    final response = await _client.post(
      '/fines/fines/$fineId/appeal',
      data: {'reason': reason},
    );
    return FineAppeal.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FineAppeal> resolveAppeal({
    required String appealId,
    required bool accepted,
    double? extraFee,
  }) async {
    final response = await _client.patch(
      '/fines/appeals/$appealId/resolve',
      data: {
        'accepted': accepted,
        if (extraFee != null) 'extra_fee': extraFee,
      },
    );
    return FineAppeal.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FineAppeal>> getPendingAppeals(String teamId) async {
    final response = await _client.get('/fines/teams/$teamId/pending-appeals');
    final data = response.data['appeals'] as List;
    return data.map((e) => FineAppeal.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Payments
  Future<FinePayment> recordPayment({
    required String fineId,
    required double amount,
  }) async {
    final response = await _client.post(
      '/fines/fines/$fineId/pay',
      data: {'amount': amount},
    );
    return FinePayment.fromJson(response.data as Map<String, dynamic>);
  }

  // Summary
  Future<TeamFinesSummary> getTeamSummary(String teamId) async {
    final response = await _client.get('/fines/teams/$teamId/fines-summary');
    return TeamFinesSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<UserFinesSummary>> getUserSummaries(String teamId) async {
    final response = await _client.get('/fines/teams/$teamId/user-fines-summary');
    final data = response.data['summaries'] as List;
    return data.map((e) => UserFinesSummary.fromJson(e as Map<String, dynamic>)).toList();
  }
}
