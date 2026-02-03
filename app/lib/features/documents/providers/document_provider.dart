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
class DocumentNotifier extends AsyncNotifier<List<TeamDocument>> {
  DocumentNotifier(this._teamId);
  final String _teamId;

  late final DocumentRepository _repo;
  String? _currentCategory;

  @override
  Future<List<TeamDocument>> build() async {
    _repo = ref.watch(documentRepositoryProvider);

    // Load documents
    return await _repo.getDocuments(
      _teamId,
      category: _currentCategory,
    );
  }

  String? get currentCategory => _currentCategory;

  Future<void> setCategory(String? category) async {
    _currentCategory = category;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getDocuments(
      _teamId,
      category: _currentCategory,
    ));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getDocuments(
      _teamId,
      category: _currentCategory,
    ));
    ref.invalidate(documentCategoriesProvider(_teamId));
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

      final currentDocs = state.value ?? [];
      state = AsyncValue.data([document, ...currentDocs]);
      ref.invalidate(documentCategoriesProvider(_teamId));
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

      final currentDocs = state.value ?? [];
      state = AsyncValue.data([document, ...currentDocs]);
      ref.invalidate(documentCategoriesProvider(_teamId));
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

      final currentDocs = state.value ?? [];
      final index = currentDocs.indexWhere((d) => d.id == documentId);
      if (index != -1) {
        final updatedList = List<TeamDocument>.from(currentDocs);
        updatedList[index] = updated;
        state = AsyncValue.data(updatedList);
      }
      ref.invalidate(documentCategoriesProvider(_teamId));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDocument(String documentId) async {
    try {
      await _repo.deleteDocument(documentId);

      final currentDocs = state.value ?? [];
      state = AsyncValue.data(
        currentDocs.where((d) => d.id != documentId).toList(),
      );
      ref.invalidate(documentCategoriesProvider(_teamId));
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
    AsyncNotifierProvider.family<DocumentNotifier, List<TeamDocument>, String>(
        DocumentNotifier.new);
