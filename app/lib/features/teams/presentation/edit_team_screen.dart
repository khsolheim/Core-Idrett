import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../data/models/team.dart';
import '../providers/team_provider.dart';
import 'widgets/edit_team_general_tab.dart';
import 'widgets/edit_team_members_tab.dart';
import 'widgets/edit_team_trainer_types_tab.dart';
import '../../../core/services/error_display_service.dart';

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
      body: teamAsync.when2(
        onRetry: () => ref.invalidate(teamDetailProvider(widget.teamId)),
        data: (team) {
          if (team == null) {
            return const Center(child: Text('Lag ikke funnet'));
          }

          return settingsAsync.when2(
            onRetry: () => ref.invalidate(teamSettingsProvider(widget.teamId)),
            data: (settings) {
              _initializeFields(team, settings);

              return Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        EditTeamGeneralTab(
                          formKey: _formKey,
                          nameController: _nameController,
                          sportController: _sportController,
                          attendancePointsController:
                              _attendancePointsController,
                          winPointsController: _winPointsController,
                          drawPointsController: _drawPointsController,
                          lossPointsController: _lossPointsController,
                          appealFeeController: _appealFeeController,
                          gameDayMultiplierController:
                              _gameDayMultiplierController,
                          team: team,
                          settings: settings,
                          onRegenerateInviteCode: _regenerateInviteCode,
                        ),
                        EditTeamMembersTab(teamId: widget.teamId),
                        EditTeamTrainerTypesTab(teamId: widget.teamId),
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
      gameDayMultiplier:
          double.tryParse(_gameDayMultiplierController.text) ?? 1.0,
    );

    if (mounted) {
      setState(() => _saving = false);

      if (teamUpdated != null && settingsUpdated != null) {
        ErrorDisplayService.showSuccess('Laginnstillinger lagret');
        context.pop();
      } else {
        ErrorDisplayService.showWarning('Kunne ikke lagre endringer');
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
          ErrorDisplayService.showSuccess('Ny invitasjonskode generert');
        }
      }
    }
  }
}
