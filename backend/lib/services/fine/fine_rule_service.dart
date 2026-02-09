import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/fine.dart';

class FineRuleService {
  final Database _db;
  final _uuid = const Uuid();

  FineRuleService(this._db);

  Future<List<FineRule>> getFineRules(String teamId, {bool? activeOnly}) async {
    final filters = <String, String>{'team_id': 'eq.$teamId'};
    if (activeOnly == true) {
      filters['active'] = 'eq.true';
    }

    final result = await _db.client.select(
      'fine_rules',
      filters: filters,
      order: 'name.asc',
    );

    return result.map((row) => FineRule.fromJson(row)).toList();
  }

  Future<FineRule> createFineRule({
    required String teamId,
    required String name,
    required double amount,
    String? description,
  }) async {
    final id = _uuid.v4();

    final result = await _db.client.insert('fine_rules', {
      'id': id,
      'team_id': teamId,
      'name': name,
      'amount': amount,
      'description': description,
    });

    return FineRule.fromJson(result.first);
  }

  Future<FineRule?> updateFineRule({
    required String ruleId,
    String? name,
    double? amount,
    String? description,
    bool? active,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (amount != null) updates['amount'] = amount;
    if (description != null) updates['description'] = description;
    if (active != null) updates['active'] = active;

    if (updates.isEmpty) return null;

    final result = await _db.client.update(
      'fine_rules',
      updates,
      filters: {'id': 'eq.$ruleId'},
    );

    if (result.isEmpty) return null;
    return FineRule.fromJson(result.first);
  }

  Future<bool> deleteFineRule(String ruleId) async {
    try {
      await _db.client.delete(
        'fine_rules',
        filters: {'id': 'eq.$ruleId'},
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
