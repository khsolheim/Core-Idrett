import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _EditTeamScreenState extends ConsumerState<EditTeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sportController = TextEditingController();

  late TextEditingController _attendancePointsController;
  late TextEditingController _winPointsController;
  late TextEditingController _drawPointsController;
  late TextEditingController _lossPointsController;
  late TextEditingController _appealFeeController;
  late TextEditingController _gameDayMultiplierController;

  bool _saving = false;
  bool _initialized = false;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _attendancePointsController = TextEditingController(text: '1');
    _winPointsController = TextEditingController(text: '3');
    _drawPointsController = TextEditingController(text: '1');
    _lossPointsController = TextEditingController(text: '0');
    _appealFeeController = TextEditingController(text: '0');
    _gameDayMultiplierController = TextEditingController(text: '1.0');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _sportController.dispose();
    _attendancePointsController.dispose();
    _winPointsController.dispose();
    _drawPointsController.dispose();
    _lossPointsController.dispose();
    _appealFeeController.dispose();
    _gameDayMultiplierController.dispose();
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
    _appealFeeController.text = settings.appealFee.toStringAsFixed(0);
    _gameDayMultiplierController.text = settings.gameDayMultiplier.toString();
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamDetailProvider(widget.teamId));
    final settingsAsync = ref.watch(teamSettingsProvider(widget.teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laginnstillinger'),
        actions: [
          if (_tabController.index == 0)
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
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Generelt', icon: Icon(Icons.settings)),
            Tab(text: 'Medlemmer', icon: Icon(Icons.people)),
            Tab(text: 'Trenertyper', icon: Icon(Icons.sports)),
          ],
        ),
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

              return Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGeneralTab(team, settings),
                        _buildMembersTab(team),
                        _buildTrainerTypesTab(team),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGeneralTab(Team team, TeamSettings settings) {
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
                  return 'Lagnavn er pakrevd';
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

            const SizedBox(height: 24),

            // Invite code section
            Text(
              'Invitasjonskode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: Text(
                  team.inviteCode ?? 'Ingen kode',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('Del denne koden for a invitere nye medlemmer'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        if (team.inviteCode != null) {
                          Clipboard.setData(ClipboardData(text: team.inviteCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kode kopiert')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _regenerateInviteCode,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Points settings section
            Text(
              'Poenginnstillinger',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sett hvor mange poeng spillere skal fa i ulike situasjoner.',
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

            const SizedBox(height: 24),

            // Fine settings section
            Text(
              'Boteinnstillinger',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Innstillinger for boter og klager.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _appealFeeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Klagegebyr',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.gavel),
                suffixText: 'kr',
                helperText: 'Legges til ved avslatt klage',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Ugyldig belop';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gameDayMultiplierController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Kampdagsmultiplikator',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_soccer),
                suffixText: 'x',
                helperText: 'F.eks. 2.0 = dobbelt belop pa kampdag',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed < 1.0) {
                    return 'Ma vare minst 1.0';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab(Team team) {
    final membersProvider = _showInactive
        ? teamMembersWithInactiveProvider(widget.teamId)
        : teamMembersProvider(widget.teamId);

    final membersAsync = ref.watch(membersProvider);
    final trainerTypesAsync = ref.watch(trainerTypesProvider(widget.teamId));

    return Column(
      children: [
        // Filter toggle
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Medlemmer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              FilterChip(
                label: const Text('Vis inaktive'),
                selected: _showInactive,
                onSelected: (value) => setState(() => _showInactive = value),
              ),
            ],
          ),
        ),

        Expanded(
          child: membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Feil: $e')),
            data: (members) {
              if (members.isEmpty) {
                return const Center(child: Text('Ingen medlemmer'));
              }

              return trainerTypesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) =>
                      _buildMemberTile(members[index], []),
                ),
                data: (trainerTypes) => ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) =>
                      _buildMemberTile(members[index], trainerTypes),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemberTile(TeamMember member, List<TrainerType> trainerTypes) {
    final isInactive = !member.isActive;

    return Opacity(
      opacity: isInactive ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundImage: member.userAvatarUrl != null
                ? NetworkImage(member.userAvatarUrl!)
                : null,
            child: member.userAvatarUrl == null
                ? Text(member.userName[0].toUpperCase())
                : null,
          ),
          title: Row(
            children: [
              Text(member.userName),
              if (isInactive) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Inaktiv',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(member.roleDisplayName),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin toggle
                  SwitchListTile(
                    title: const Text('Administrator'),
                    subtitle: const Text('Kan administrere laget'),
                    value: member.isAdmin,
                    onChanged: (value) => _updateMemberPermissions(
                      member,
                      isAdmin: value,
                    ),
                  ),

                  // Fine boss toggle
                  SwitchListTile(
                    title: const Text('Botesjef'),
                    subtitle: const Text('Kan godkjenne boter'),
                    value: member.isFineBoss,
                    onChanged: (value) => _updateMemberPermissions(
                      member,
                      isFineBoss: value,
                    ),
                  ),

                  const Divider(),

                  // Trainer type dropdown
                  ListTile(
                    title: const Text('Trenerrolle'),
                    trailing: DropdownButton<String?>(
                      value: member.trainerType?.id,
                      hint: const Text('Ingen'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Ingen'),
                        ),
                        ...trainerTypes.map((tt) => DropdownMenuItem(
                              value: tt.id,
                              child: Text(tt.name),
                            )),
                      ],
                      onChanged: (value) => _updateMemberPermissions(
                        member,
                        trainerTypeId: value,
                        clearTrainerType: value == null,
                      ),
                    ),
                  ),

                  const Divider(),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isInactive)
                        TextButton.icon(
                          icon: const Icon(Icons.restore),
                          label: const Text('Reaktiver'),
                          onPressed: () => _reactivateMember(member),
                        )
                      else
                        TextButton.icon(
                          icon: const Icon(Icons.person_off),
                          label: const Text('Deaktiver'),
                          onPressed: () => _deactivateMember(member),
                        ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Fjern',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () => _removeMember(member),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerTypesTab(Team team) {
    final trainerTypesAsync = ref.watch(trainerTypesProvider(widget.teamId));

    return trainerTypesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Feil: $e')),
      data: (trainerTypes) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Trenertyper',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Legg til'),
                    onPressed: _addTrainerType,
                  ),
                ],
              ),
            ),
            Expanded(
              child: trainerTypes.isEmpty
                  ? const Center(child: Text('Ingen trenertyper'))
                  : ListView.builder(
                      itemCount: trainerTypes.length,
                      itemBuilder: (context, index) {
                        final tt = trainerTypes[index];
                        return ListTile(
                          leading: const Icon(Icons.sports),
                          title: Text(tt.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteTrainerType(tt),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // Actions
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
      appealFee: double.tryParse(_appealFeeController.text) ?? 0,
      gameDayMultiplier: double.tryParse(_gameDayMultiplierController.text) ?? 1.0,
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

  Future<void> _regenerateInviteCode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ny invitasjonskode?'),
        content: const Text(
          'Den gamle koden vil slutte a fungere. Vil du fortsette?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generer ny'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final notifier = ref.read(teamNotifierProvider.notifier);
      final newCode = await notifier.generateInviteCode(widget.teamId);
      if (newCode != null) {
        ref.invalidate(teamDetailProvider(widget.teamId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ny invitasjonskode generert')),
          );
        }
      }
    }
  }

  Future<void> _updateMemberPermissions(
    TeamMember member, {
    bool? isAdmin,
    bool? isFineBoss,
    String? trainerTypeId,
    bool clearTrainerType = false,
  }) async {
    final notifier = ref.read(teamNotifierProvider.notifier);
    final success = await notifier.updateMemberPermissions(
      teamId: widget.teamId,
      memberId: member.id,
      isAdmin: isAdmin,
      isFineBoss: isFineBoss,
      trainerTypeId: trainerTypeId,
      clearTrainerType: clearTrainerType,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunne ikke oppdatere tilganger'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deactivateMember(TeamMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deaktiver medlem?'),
        content: Text(
          '${member.userName} vil ikke lenger kunne se laget. Du kan reaktivere dem senere.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deaktiver'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final notifier = ref.read(teamNotifierProvider.notifier);
      final success = await notifier.deactivateMember(widget.teamId, member.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Medlem deaktivert' : 'Kunne ikke deaktivere medlem',
            ),
            backgroundColor: success ? null : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reactivateMember(TeamMember member) async {
    final notifier = ref.read(teamNotifierProvider.notifier);
    final success = await notifier.reactivateMember(widget.teamId, member.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Medlem reaktivert' : 'Kunne ikke reaktivere medlem',
          ),
          backgroundColor: success ? null : Colors.red,
        ),
      );
    }
  }

  Future<void> _removeMember(TeamMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fjern medlem permanent?'),
        content: Text(
          'Er du sikker pa at du vil fjerne ${member.userName} fra laget? Dette kan ikke angres.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Fjern'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final notifier = ref.read(teamNotifierProvider.notifier);
      final success = await notifier.removeMember(widget.teamId, member.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Medlem fjernet' : 'Kunne ikke fjerne medlem',
            ),
            backgroundColor: success ? null : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addTrainerType() async {
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ny trenertype'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Navn',
            hintText: 'f.eks. Keepertrener',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Legg til'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final notifier = ref.read(teamNotifierProvider.notifier);
      final result = await notifier.createTrainerType(
        teamId: widget.teamId,
        name: name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result != null ? 'Trenertype opprettet' : 'Kunne ikke opprette trenertype',
            ),
            backgroundColor: result != null ? null : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTrainerType(TrainerType trainerType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett trenertype?'),
        content: Text(
          'Er du sikker pa at du vil slette "${trainerType.name}"? Medlemmer med denne rollen vil miste den.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Slett'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final notifier = ref.read(teamNotifierProvider.notifier);
      final success = await notifier.deleteTrainerType(widget.teamId, trainerType.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Trenertype slettet' : 'Kunne ikke slette trenertype',
            ),
            backgroundColor: success ? null : Colors.red,
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
