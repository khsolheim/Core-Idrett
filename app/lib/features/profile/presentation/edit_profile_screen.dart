import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  DateTime? _birthDate;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    if (_initialized) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    _initialized = true;
    _nameController.text = user.name;
    _avatarUrlController.text = user.avatarUrl ?? '';
    _birthDate = user.birthDate;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rediger profil'),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Feil: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Ikke innlogget'));
          }

          _initializeFields();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar preview
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _avatarUrlController.text.isNotEmpty
                              ? NetworkImage(_avatarUrlController.text)
                              : null,
                          child: _avatarUrlController.text.isEmpty
                              ? Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 32),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Profilbilde',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Name field
                  Text(
                    'Personlig informasjon',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Navn',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Navn er pakrevd';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // Birth date picker
                  InkWell(
                    onTap: _selectBirthDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fodselsdato',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _birthDate != null
                                ? DateFormat('d. MMMM yyyy', 'nb_NO')
                                    .format(_birthDate!)
                                : 'Velg dato',
                            style: _birthDate == null
                                ? TextStyle(
                                    color: Theme.of(context).hintColor,
                                  )
                                : null,
                          ),
                          if (_birthDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _birthDate = null),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Avatar URL field
                  TextFormField(
                    controller: _avatarUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Profilbilde URL',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image),
                      hintText: 'https://example.com/avatar.jpg',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 32),

                  // Email (read-only)
                  Text(
                    'Kontoinformasjon',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: user.email,
                    decoration: const InputDecoration(
                      labelText: 'E-post',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    enabled: false,
                  ),

                  const SizedBox(height: 16),

                  // Password change button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.lock),
                      label: const Text('Endre passord'),
                      onPressed: _showChangePasswordDialog,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthDate ?? DateTime(now.year - 25, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('nb', 'NO'),
    );

    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final notifier = ref.read(authStateProvider.notifier);
    final result = await notifier.updateProfile(
      name: _nameController.text.trim(),
      avatarUrl: _avatarUrlController.text.trim().isNotEmpty
          ? _avatarUrlController.text.trim()
          : null,
      // Note: birthDate would need backend support to update
    );

    if (mounted) {
      setState(() => _saving = false);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil oppdatert')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kunne ikke oppdatere profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Endre passord'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Navarende passord',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Nytt passord',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Bekreft nytt passord',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passordene stemmer ikke overens'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Endre'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await ref.read(authRepositoryProvider).changePassword(
          currentPassword: currentPasswordController.text,
          newPassword: newPasswordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passord endret')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }
}
