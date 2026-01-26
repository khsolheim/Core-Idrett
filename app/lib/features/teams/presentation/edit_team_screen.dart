import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/team.dart';
import '../providers/team_provider.dart';

class EditTeamScreen extends ConsumerStatefulWidget {
  final String teamId;

  const EditTeamScreen({super.key, required this.teamId});

  @override
  ConsumerState<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends ConsumerState<EditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sportController = TextEditingController();

  late TextEditingController _attendancePointsController;
  late TextEditingController _winPointsController;
  late TextEditingController _drawPointsController;
  late TextEditingController _lossPointsController;

  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _attendancePointsController = TextEditingController(text: '1');
    _winPointsController = TextEditingController(text: '3');
    _drawPointsController = TextEditingController(text: '1');
    _lossPointsController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sportController.dispose();
    _attendancePointsController.dispose();
    _winPointsController.dispose();
    _drawPointsController.dispose();
    _lossPointsController.dispose();
    super.dispose();
  }

  void _initializeFields(Team team, TeamSettings settings) {
    if (_initialized) return;
    _initialized = true;

    _nameController.text = team.name;
    _sportController.text = team.sport ?? '';
    _attendancePointsController.text = settings.attendancePoints.toString();
    _winPointsController.text = settings.winPoints.toString();
    _drawPointsController.text = settings.drawPoints.toString();
    _lossPointsController.text = settings.lossPoints.toString();
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamDetailProvider(widget.teamId));
    final settingsAsync = ref.watch(teamSettingsProvider(widget.teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rediger lag'),
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
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Feil: $e')),
        data: (team) {
          if (team == null) {
            return const Center(child: Text('Lag ikke funnet'));
          }

          return settingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Feil: $e')),
            data: (settings) {
              _initializeFields(team, settings);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Team info section
                      Text(
                        'Laginformasjon',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Lagnavn',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lagnavn er påkrevd';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sportController,
                        decoration: const InputDecoration(
                          labelText: 'Idrett',
                          border: OutlineInputBorder(),
                          hintText: 'f.eks. Fotball, Handball, Basketball',
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Points settings section
                      Text(
                        'Poenginnstillinger',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sett hvor mange poeng spillere skal f i ulike situasjoner.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _PointsField(
                              controller: _attendancePointsController,
                              label: 'Oppmote',
                              icon: Icons.check_circle_outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _PointsField(
                              controller: _winPointsController,
                              label: 'Seier',
                              icon: Icons.emoji_events_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _PointsField(
                              controller: _drawPointsController,
                              label: 'Uavgjort',
                              icon: Icons.handshake_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _PointsField(
                              controller: _lossPointsController,
                              label: 'Tap',
                              icon: Icons.thumb_down_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final notifier = ref.read(teamNotifierProvider.notifier);

    // Update team info
    final teamUpdated = await notifier.updateTeam(
      teamId: widget.teamId,
      name: _nameController.text.trim(),
      sport: _sportController.text.trim().isNotEmpty
          ? _sportController.text.trim()
          : null,
    );

    // Update settings
    final settingsUpdated = await notifier.updateTeamSettings(
      teamId: widget.teamId,
      attendancePoints: int.tryParse(_attendancePointsController.text) ?? 1,
      winPoints: int.tryParse(_winPointsController.text) ?? 3,
      drawPoints: int.tryParse(_drawPointsController.text) ?? 1,
      lossPoints: int.tryParse(_lossPointsController.text) ?? 0,
    );

    if (mounted) {
      setState(() => _saving = false);

      if (teamUpdated != null && settingsUpdated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laginnstillinger lagret')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kunne ikke lagre endringer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _PointsField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _PointsField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Pakrevd';
        }
        if (int.tryParse(value) == null) {
          return 'Ugyldig tall';
        }
        return null;
      },
    );
  }
}
