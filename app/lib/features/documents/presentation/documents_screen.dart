import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../data/models/document.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/document_provider.dart';
import 'upload_document_sheet.dart';
import 'widgets/document_card.dart';
import 'widgets/edit_document_dialog.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  final String teamId;

  const DocumentsScreen({super.key, required this.teamId});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final documentsState = ref.watch(documentNotifierProvider(widget.teamId));
    final categoriesAsync = ref.watch(documentCategoriesProvider(widget.teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokumenter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(documentNotifierProvider(widget.teamId).notifier).refresh(),
            tooltip: 'Oppdater',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          categoriesAsync.when2(
            onRetry: () => ref.invalidate(documentCategoriesProvider(widget.teamId)),
            loading: () => const SizedBox.shrink(),
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    FilterChip(
                      label: const Text('Alle'),
                      selected: _selectedCategory == null,
                      onSelected: (_) => _setCategory(null),
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('${cat.displayName} (${cat.count})'),
                        selected: _selectedCategory == cat.category,
                        onSelected: (_) => _setCategory(cat.category),
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
          // Document list
          Expanded(
            child: documentsState.when2(
              onRetry: () =>
                  ref.read(documentNotifierProvider(widget.teamId).notifier).refresh(),
              data: (documents) {
                if (documents.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.folder_open,
                    title: _selectedCategory != null
                        ? 'Ingen dokumenter i denne kategorien'
                        : 'Ingen dokumenter enna',
                    subtitle: 'Trykk + for a laste opp',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(documentNotifierProvider(widget.teamId).notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      return DocumentCard(
                        document: doc,
                        onTap: () => _openDocument(doc),
                        onDelete: () => _confirmDelete(doc),
                        onEdit: () => _editDocument(doc),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _setCategory(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    ref.read(documentNotifierProvider(widget.teamId).notifier).setCategory(category);
  }

  void _showUploadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => UploadDocumentSheet(teamId: widget.teamId),
    );
  }

  Future<void> _openDocument(TeamDocument doc) async {
    // Get download URL and open
    final url = await ref
        .read(documentNotifierProvider(widget.teamId).notifier)
        .getDownloadUrl(doc.id);

    if (url != null && mounted) {
      // In a real implementation, use url_launcher or open in app viewer
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apner ${doc.name}...')),
      );
    }
  }

  void _editDocument(TeamDocument doc) {
    showDialog(
      context: context,
      builder: (context) => EditDocumentDialog(
        document: doc,
        onSave: (name, description, category) async {
          final success = await ref
              .read(documentNotifierProvider(widget.teamId).notifier)
              .updateDocument(
                documentId: doc.id,
                name: name,
                description: description,
                category: category,
              );
          if (success && context.mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _confirmDelete(TeamDocument doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett dokument'),
        content: Text('Er du sikker pa at du vil slette "${doc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(documentNotifierProvider(widget.teamId).notifier)
                  .deleteDocument(doc.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Slett'),
          ),
        ],
      ),
    );
  }
}
