import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/export_log.dart';
import '../data/export_repository.dart';

/// Provider for export history
final exportHistoryProvider = FutureProvider.family<List<ExportLog>, String>((ref, teamId) async {
  final repo = ref.watch(exportRepositoryProvider);
  return repo.getExportHistory(teamId);
});

/// State for export operations
class ExportState {
  final bool isExporting;
  final String? currentType;
  final String? error;
  final ExportData? lastExport;

  const ExportState({
    this.isExporting = false,
    this.currentType,
    this.error,
    this.lastExport,
  });

  ExportState copyWith({
    bool? isExporting,
    String? currentType,
    String? error,
    ExportData? lastExport,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      currentType: currentType ?? this.currentType,
      error: error,
      lastExport: lastExport ?? this.lastExport,
    );
  }
}

/// Export notifier
class ExportNotifier extends Notifier<ExportState> {
  ExportNotifier(this._teamId);
  final String _teamId;
  late final ExportRepository _repo;

  @override
  ExportState build() {
    _repo = ref.watch(exportRepositoryProvider);
    return const ExportState();
  }

  Future<ExportData?> exportLeaderboard({
    String? seasonId,
    String? leaderboardId,
  }) async {
    state = state.copyWith(isExporting: true, currentType: 'leaderboard', error: null);

    try {
      final data = await _repo.exportLeaderboard(
        _teamId,
        seasonId: seasonId,
        leaderboardId: leaderboardId,
      );
      state = state.copyWith(isExporting: false, lastExport: data);
      ref.invalidate(exportHistoryProvider(_teamId));
      return data;
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
      return null;
    }
  }

  Future<ExportData?> exportAttendance({
    String? seasonId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    state = state.copyWith(isExporting: true, currentType: 'attendance', error: null);

    try {
      final data = await _repo.exportAttendance(
        _teamId,
        seasonId: seasonId,
        fromDate: fromDate,
        toDate: toDate,
      );
      state = state.copyWith(isExporting: false, lastExport: data);
      ref.invalidate(exportHistoryProvider(_teamId));
      return data;
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
      return null;
    }
  }

  Future<ExportData?> exportFines({
    bool? paidOnly,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    state = state.copyWith(isExporting: true, currentType: 'fines', error: null);

    try {
      final data = await _repo.exportFines(
        _teamId,
        paidOnly: paidOnly,
        fromDate: fromDate,
        toDate: toDate,
      );
      state = state.copyWith(isExporting: false, lastExport: data);
      ref.invalidate(exportHistoryProvider(_teamId));
      return data;
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
      return null;
    }
  }

  Future<ExportData?> exportActivities({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    state = state.copyWith(isExporting: true, currentType: 'activities', error: null);

    try {
      final data = await _repo.exportActivities(
        _teamId,
        fromDate: fromDate,
        toDate: toDate,
      );
      state = state.copyWith(isExporting: false, lastExport: data);
      ref.invalidate(exportHistoryProvider(_teamId));
      return data;
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
      return null;
    }
  }

  Future<ExportData?> exportMembers() async {
    state = state.copyWith(isExporting: true, currentType: 'members', error: null);

    try {
      final data = await _repo.exportMembers(_teamId);
      state = state.copyWith(isExporting: false, lastExport: data);
      ref.invalidate(exportHistoryProvider(_teamId));
      return data;
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
      return null;
    }
  }

  Future<String?> exportToCsv(
    ExportType type, {
    Map<String, String>? extraParams,
  }) async {
    state = state.copyWith(isExporting: true, currentType: type.value, error: null);

    try {
      final csv = await _repo.exportToCsv(_teamId, type, extraParams: extraParams);
      state = state.copyWith(isExporting: false);
      ref.invalidate(exportHistoryProvider(_teamId));
      return csv;
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final exportNotifierProvider =
    NotifierProvider.family<ExportNotifier, ExportState, String>(ExportNotifier.new);
