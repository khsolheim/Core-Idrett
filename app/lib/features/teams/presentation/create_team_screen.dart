import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/team_provider.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sportController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sportController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final team = await ref.read(teamNotifierProvider.notifier).createTeam(
      name: _nameController.text.trim(),
      sport: _sportController.text.trim().isNotEmpty
          ? _sportController.text.trim()
          : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (team != null) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke opprette lag. Prøv igjen.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opprett lag'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Lagnavn',
                  prefixIcon: Icon(Icons.group),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vennligst skriv inn lagnavn';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sportController,
                decoration: const InputDecoration(
                  labelText: 'Idrett (valgfritt)',
                  prefixIcon: Icon(Icons.sports),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _createTeam,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Opprett lag'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
