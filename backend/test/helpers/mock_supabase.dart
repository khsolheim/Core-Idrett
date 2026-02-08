/// Manual mock SupabaseClient for backend unit tests
/// Provides a simple in-memory database simulation for testing

import 'dart:async';

/// Simple in-memory mock of SupabaseClient for testing
/// Simulates basic Postgrest operations without actual database
class MockSupabaseClient {
  final _tables = <String, List<Map<String, dynamic>>>{};

  /// Get or create table data storage
  List<Map<String, dynamic>> _getTable(String tableName) {
    return _tables.putIfAbsent(tableName, () => []);
  }

  /// Create query builder for a table
  MockQueryBuilder from(String tableName) {
    return MockQueryBuilder(this, tableName);
  }

  /// Clear all mock data
  void clearAll() {
    _tables.clear();
  }

  /// Seed table with initial data
  void seedTable(String tableName, List<Map<String, dynamic>> data) {
    _tables[tableName] = List.from(data);
  }

  /// Get current data from a table
  List<Map<String, dynamic>> getTableData(String tableName) {
    return List.from(_getTable(tableName));
  }
}

/// Mock query builder that simulates Postgrest query chain
class MockQueryBuilder {
  final MockSupabaseClient _client;
  final String _tableName;
  // ignore: unused_field
  String? _selectColumns;
  final List<_Filter> _filters = [];
  Map<String, dynamic>? _insertData;
  Map<String, dynamic>? _updateData;
  bool _isDelete = false;
  bool _isSingle = false;
  int? _limit;
  String? _orderColumn;
  bool _orderAscending = true;

  MockQueryBuilder(this._client, this._tableName);

  /// SELECT query
  MockQueryBuilder select([String columns = '*']) {
    _selectColumns = columns;
    return this;
  }

  /// INSERT query
  MockQueryBuilder insert(dynamic data) {
    if (data is Map<String, dynamic>) {
      _insertData = data;
    } else if (data is List<Map<String, dynamic>>) {
      // For batch insert, just use first for simplicity in tests
      _insertData = data.isNotEmpty ? data.first : {};
    }
    return this;
  }

  /// UPDATE query
  MockQueryBuilder update(Map<String, dynamic> data) {
    _updateData = data;
    return this;
  }

  /// DELETE query
  MockQueryBuilder delete() {
    _isDelete = true;
    return this;
  }

  /// Filter: equals
  MockQueryBuilder eq(String column, dynamic value) {
    _filters.add(_Filter(column, _FilterOp.eq, value));
    return this;
  }

  /// Filter: not equals
  MockQueryBuilder neq(String column, dynamic value) {
    _filters.add(_Filter(column, _FilterOp.neq, value));
    return this;
  }

  /// Filter: greater than
  MockQueryBuilder gt(String column, dynamic value) {
    _filters.add(_Filter(column, _FilterOp.gt, value));
    return this;
  }

  /// Filter: less than
  MockQueryBuilder lt(String column, dynamic value) {
    _filters.add(_Filter(column, _FilterOp.lt, value));
    return this;
  }

  /// Filter: in list
  MockQueryBuilder inFilter(String column, List<dynamic> values) {
    _filters.add(_Filter(column, _FilterOp.inList, values));
    return this;
  }

  /// Single result expectation
  MockQueryBuilder single() {
    _isSingle = true;
    return this;
  }

  /// Limit results
  MockQueryBuilder limit(int count) {
    _limit = count;
    return this;
  }

  /// Order results
  MockQueryBuilder order(String column, {bool ascending = true}) {
    _orderColumn = column;
    _orderAscending = ascending;
    return this;
  }

  /// Execute query and return Future (for async/await compatibility)
  Future<dynamic> then<T>(FutureOr<T> Function(dynamic) onValue, {Function? onError}) async {
    final result = _execute();
    return onValue(result);
  }

  /// Execute the query
  dynamic _execute() {
    final table = _client._getTable(_tableName);

    // INSERT
    if (_insertData != null) {
      final newRow = Map<String, dynamic>.from(_insertData!);
      // Auto-generate ID if not provided
      if (!newRow.containsKey('id')) {
        newRow['id'] = 'mock-id-${DateTime.now().millisecondsSinceEpoch}';
      }
      // Auto-generate timestamps if not provided
      if (!newRow.containsKey('created_at')) {
        newRow['created_at'] = DateTime.now().toIso8601String();
      }
      table.add(newRow);
      return _isSingle ? newRow : [newRow];
    }

    // UPDATE
    if (_updateData != null) {
      final filtered = _applyFilters(table);
      for (final row in filtered) {
        row.addAll(_updateData!);
        if (!row.containsKey('updated_at')) {
          row['updated_at'] = DateTime.now().toIso8601String();
        }
      }
      return _isSingle && filtered.isNotEmpty ? filtered.first : filtered;
    }

    // DELETE
    if (_isDelete) {
      final filtered = _applyFilters(table);
      for (final row in filtered) {
        table.remove(row);
      }
      return null;
    }

    // SELECT
    var results = _applyFilters(table);

    // Apply ordering
    if (_orderColumn != null) {
      results.sort((a, b) {
        final aVal = a[_orderColumn];
        final bVal = b[_orderColumn];
        if (aVal == null) return _orderAscending ? -1 : 1;
        if (bVal == null) return _orderAscending ? 1 : -1;

        final comparison = Comparable.compare(aVal as Comparable, bVal as Comparable);
        return _orderAscending ? comparison : -comparison;
      });
    }

    // Apply limit
    if (_limit != null && results.length > _limit!) {
      results = results.sublist(0, _limit);
    }

    return _isSingle ? (results.isNotEmpty ? results.first : null) : results;
  }

  /// Apply all filters to the data
  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> data) {
    var filtered = List<Map<String, dynamic>>.from(data);

    for (final filter in _filters) {
      filtered = filtered.where((row) {
        final value = row[filter.column];
        switch (filter.op) {
          case _FilterOp.eq:
            return value == filter.value;
          case _FilterOp.neq:
            return value != filter.value;
          case _FilterOp.gt:
            return value != null && (value as Comparable).compareTo(filter.value) > 0;
          case _FilterOp.lt:
            return value != null && (value as Comparable).compareTo(filter.value) < 0;
          case _FilterOp.inList:
            return (filter.value as List).contains(value);
        }
      }).toList();
    }

    return filtered;
  }
}

/// Filter operation types
enum _FilterOp { eq, neq, gt, lt, inList }

/// Filter representation
class _Filter {
  final String column;
  final _FilterOp op;
  final dynamic value;

  _Filter(this.column, this.op, this.value);
}

/// Helper to create and configure mock Supabase client for tests
class MockSupabaseHelper {
  final MockSupabaseClient client;

  MockSupabaseHelper() : client = MockSupabaseClient();

  /// Seed a table with test data
  void seedTable(String tableName, List<Map<String, dynamic>> data) {
    client.seedTable(tableName, data);
  }

  /// Clear all data
  void clearAll() {
    client.clearAll();
  }

  /// Get current table data (for assertions)
  List<Map<String, dynamic>> getTableData(String tableName) {
    return client.getTableData(tableName);
  }

  /// Verify that table contains expected number of rows
  bool verifyTableRowCount(String tableName, int expectedCount) {
    return getTableData(tableName).length == expectedCount;
  }

  /// Verify that a row with specified ID exists
  bool verifyRowExists(String tableName, String id) {
    return getTableData(tableName).any((row) => row['id'] == id);
  }

  /// Find a row by ID
  Map<String, dynamic>? findRowById(String tableName, String id) {
    try {
      return getTableData(tableName).firstWhere((row) => row['id'] == id);
    } catch (_) {
      return null;
    }
  }
}
