import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/document.dart';
import '../providers/document_provider.dart';

class UploadDocumentSheet extends ConsumerStatefulWidget {
  final String teamId;

  const UploadDocumentSheet({super.key, required this.teamId});

  @override
  ConsumerState<UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends ConsumerState<UploadDocumentSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DocumentCategory? _selectedCategory;
  PlatformFile? _selectedFile;
  Uint8List? _fileBytes;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last opp dokument',
                style: theme.textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // File picker area
          InkWell(
            onTap: _isUploading ? null : _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedFile != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: _selectedFile != null ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFile != null ? Icons.check_circle : Icons.cloud_upload,
                    size: 48,
                    color: _selectedFile != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFile != null
                        ? _selectedFile!.name
                        : 'Trykk for a velge fil',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _selectedFile != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatFileSize(_selectedFile!.size),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Navn (valgfritt)',
              hintText: 'Filnavn brukes som standard',
              border: OutlineInputBorder(),
            ),
            enabled: !_isUploading,
          ),
          const SizedBox(height: 16),

          // Description field
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Beskrivelse (valgfritt)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            enabled: !_isUploading,
          ),
          const SizedBox(height: 16),

          // Category dropdown
          DropdownButtonFormField<DocumentCategory?>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Kategori (valgfritt)',
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
            onChanged: _isUploading
                ? null
                : (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
          ),
          const SizedBox(height: 24),

          // Upload button
          FilledButton(
            onPressed: _canUpload ? _upload : null,
            child: _isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Last opp'),
          ),
        ],
      ),
    );
  }

  bool get _canUpload => _selectedFile != null && _fileBytes != null && !_isUploading;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
        _fileBytes = result.files.first.bytes;
        if (_nameController.text.isEmpty) {
          _nameController.text = result.files.first.name;
        }
      });
    }
  }

  Future<void> _upload() async {
    if (!_canUpload) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final name = _nameController.text.trim().isEmpty
          ? _selectedFile!.name
          : _nameController.text.trim();

      final success = await ref
          .read(documentNotifierProvider(widget.teamId).notifier)
          .uploadDocument(
            fileName: name,
            fileBytes: _fileBytes!,
            mimeType: _getMimeType(_selectedFile!.name),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            category: _selectedCategory?.value,
          );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dokument lastet opp')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kunne ikke laste opp dokument'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isUploading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kunne ikke laste opp dokument. Prøv igjen.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      // Video
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      // Archives
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      default:
        return 'application/octet-stream';
    }
  }
}
