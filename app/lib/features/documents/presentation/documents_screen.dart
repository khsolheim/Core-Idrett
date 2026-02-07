import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../data/models/document.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/document_provider.dart';
import 'upload_document_sheet.dart';

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
                      return _DocumentCard(
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
      builder: (context) => _EditDocumentDialog(
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

class _DocumentCard extends StatelessWidget {
  final TeamDocument document;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d. MMM yyyy', 'nb_NO');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // File icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getIconColor(theme),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIcon(),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              // Document info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          document.formattedSize,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(document.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    if (document.category != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          DocumentCategory.fromString(document.category)?.displayName ??
                              document.category!,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: (action) {
                  switch (action) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Rediger'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Slett', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    if (document.isImage) return Icons.image;
    if (document.isPdf) return Icons.picture_as_pdf;
    if (document.isVideo) return Icons.video_file;
    if (document.isAudio) return Icons.audio_file;

    switch (document.extension) {
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getIconColor(ThemeData theme) {
    if (document.isImage) return Colors.green;
    if (document.isPdf) return Colors.red;
    if (document.isVideo) return Colors.purple;
    if (document.isAudio) return Colors.orange;

    switch (document.extension) {
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green.shade700;
      case 'ppt':
      case 'pptx':
        return Colors.orange.shade700;
      default:
        return theme.colorScheme.primary;
    }
  }
}

class _EditDocumentDialog extends StatefulWidget {
  final TeamDocument document;
  final Function(String name, String? description, String? category) onSave;

  const _EditDocumentDialog({
    required this.document,
    required this.onSave,
  });

  @override
  State<_EditDocumentDialog> createState() => _EditDocumentDialogState();
}

class _EditDocumentDialogState extends State<_EditDocumentDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  DocumentCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.document.name);
    _descriptionController = TextEditingController(text: widget.document.description ?? '');
    _selectedCategory = DocumentCategory.fromString(widget.document.category);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rediger dokument'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Navn',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beskrivelse (valgfritt)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DocumentCategory?>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Ingen kategori'),
                ),
                ...DocumentCategory.values.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat.displayName),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            widget.onSave(
              name,
              _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              _selectedCategory?.value,
            );
          },
          child: const Text('Lagre'),
        ),
      ],
    );
  }
}
