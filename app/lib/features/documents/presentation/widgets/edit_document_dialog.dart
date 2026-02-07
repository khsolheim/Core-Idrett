import 'package:flutter/material.dart';
import '../../../../data/models/document.dart';

/// Dialog for editing a document's name, description, and category.
class EditDocumentDialog extends StatefulWidget {
  final TeamDocument document;
  final Function(String name, String? description, String? category) onSave;

  const EditDocumentDialog({
    super.key,
    required this.document,
    required this.onSave,
  });

  @override
  State<EditDocumentDialog> createState() => _EditDocumentDialogState();
}

class _EditDocumentDialogState extends State<EditDocumentDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  DocumentCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.document.name);
    _descriptionController =
        TextEditingController(text: widget.document.description ?? '');
    _selectedCategory =
        DocumentCategory.fromString(widget.document.category);
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
