import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/document.dart';
import '../data/document_repository.dart';

/// Provider for documents by team
final documentsProvider = FutureProvider.family<List<TeamDocument>, DocumentsParams>((ref, params) async {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.getDocuments(
    params.teamId,
    category: params.category,
  );
});

/// Provider for document categories
final documentCategoriesProvider = FutureProvider.family<List<DocumentCategoryCount>, String>((ref, teamId) async {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.getCategories(teamId);
});

/// Params for documents query
class DocumentsParams {
  final String teamId;
  final String? category;

  DocumentsParams({required this.teamId, this.category});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentsParams &&
          runtimeType == other.runtimeType &&
          teamId == other.teamId &&
          category == other.category;

  @override
  int get hashCode => teamId.hashCode ^ category.hashCode;
}

/// Document notifier for managing document state
class DocumentNotifier extends StateNotifier<AsyncValue<List<TeamDocument>>> {
  final DocumentRepository _repo;
  final String _teamId;
  final Ref _ref;
  String? _currentCategory;

  DocumentNotifier(this._repo, this._teamId, this._ref)
      : super(const AsyncValue.loading()) {
    _loadDocuments();
  }

  String? get currentCategory => _currentCategory;

  Future<void> _loadDocuments() async {
    try {
      state = const AsyncValue.loading();
      final documents = await _repo.getDocuments(
        _teamId,
        category: _currentCategory,
      );
      state = AsyncValue.data(documents);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setCategory(String? category) async {
    _currentCategory = category;
    await _loadDocuments();
  }

  Future<void> refresh() async {
    await _loadDocuments();
    _ref.invalidate(documentCategoriesProvider(_teamId));
  }

  Future<bool> uploadDocument({
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    String? description,
    String? category,
  }) async {
    try {
      final document = await _repo.uploadDocument(
        teamId: _teamId,
        fileName: fileName,
        fileBytes: fileBytes,
        mimeType: mimeType,
        description: description,
        category: category,
      );

      final currentDocs = state.valueOrNull ?? [];
      state = AsyncValue.data([document, ...currentDocs]);
      _ref.invalidate(documentCategoriesProvider(_teamId));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createDocument({
    required String name,
    required String filePath,
    required int fileSize,
    required String mimeType,
    String? description,
    String? category,
  }) async {
    try {
      final document = await _repo.createDocument(
        teamId: _teamId,
        name: name,
        filePath: filePath,
        fileSize: fileSize,
        mimeType: mimeType,
        description: description,
        category: category,
      );

      final currentDocs = state.valueOrNull ?? [];
      state = AsyncValue.data([document, ...currentDocs]);
      _ref.invalidate(documentCategoriesProvider(_teamId));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateDocument({
    required String documentId,
    String? name,
    String? description,
    String? category,
  }) async {
    try {
      final updated = await _repo.updateDocument(
        documentId: documentId,
        name: name,
        description: description,
        category: category,
      );

      final currentDocs = state.valueOrNull ?? [];
      final index = currentDocs.indexWhere((d) => d.id == documentId);
      if (index != -1) {
        final updatedList = List<TeamDocument>.from(currentDocs);
        updatedList[index] = updated;
        state = AsyncValue.data(updatedList);
      }
      _ref.invalidate(documentCategoriesProvider(_teamId));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDocument(String documentId) async {
    try {
      await _repo.deleteDocument(documentId);

      final currentDocs = state.valueOrNull ?? [];
      state = AsyncValue.data(
        currentDocs.where((d) => d.id != documentId).toList(),
      );
      _ref.invalidate(documentCategoriesProvider(_teamId));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getDownloadUrl(String documentId) async {
    try {
      return await _repo.getDownloadUrl(documentId);
    } catch (e) {
      return null;
    }
  }
}

final documentNotifierProvider =
    StateNotifierProvider.family<DocumentNotifier, AsyncValue<List<TeamDocument>>, String>(
        (ref, teamId) {
  final repo = ref.watch(documentRepositoryProvider);
  return DocumentNotifier(repo, teamId, ref);
});
