import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../data/models/points_config.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/points_provider.dart';
import 'widgets/points_config_fields.dart';

class PointsConfigScreen extends ConsumerStatefulWidget {
  final String teamId;

  const PointsConfigScreen({super.key, required this.teamId});

  @override
  ConsumerState<PointsConfigScreen> createState() => _PointsConfigScreenState();
}

class _PointsConfigScreenState extends ConsumerState<PointsConfigScreen> {
  late TextEditingController _trainingPointsController;
  late TextEditingController _matchPointsController;
  late TextEditingController _socialPointsController;
  late TextEditingController _trainingWeightController;
  late TextEditingController _matchWeightController;
  late TextEditingController _socialWeightController;
  late TextEditingController _competitionWeightController;

  MiniActivityDistribution _miniActivityDistribution =
      MiniActivityDistribution.topThree;
  LeaderboardVisibility _visibility = LeaderboardVisibility.all;
  NewPlayerStartMode _newPlayerStartMode = NewPlayerStartMode.fromJoin;
  bool _autoAwardAttendance = true;
  bool _allowOptOut = false;
  bool _requireAbsenceReason = false;
  bool _requireAbsenceApproval = false;
  bool _excludeValidAbsence = true;

  bool _isLoading = false;
  bool _hasLoadedInitialConfig = false;

  @override
  void initState() {
    super.initState();
    _trainingPointsController = TextEditingController(text: '1');
    _matchPointsController = TextEditingController(text: '2');
    _socialPointsController = TextEditingController(text: '1');
    _trainingWeightController = TextEditingController(text: '1.0');
    _matchWeightController = TextEditingController(text: '1.5');
    _socialWeightController = TextEditingController(text: '0.5');
    _competitionWeightController = TextEditingController(text: '1.0');
  }

  @override
  void dispose() {
    _trainingPointsController.dispose();
    _matchPointsController.dispose();
    _socialPointsController.dispose();
    _trainingWeightController.dispose();
    _matchWeightController.dispose();
    _socialWeightController.dispose();
    _competitionWeightController.dispose();
    super.dispose();
  }

  void _loadConfig(TeamPointsConfig config) {
    _trainingPointsController.text = config.trainingPoints.toString();
    _matchPointsController.text = config.matchPoints.toString();
    _socialPointsController.text = config.socialPoints.toString();
    _trainingWeightController.text = config.trainingWeight.toString();
    _matchWeightController.text = config.matchWeight.toString();
    _socialWeightController.text = config.socialWeight.toString();
    _competitionWeightController.text = config.competitionWeight.toString();
    _miniActivityDistribution = config.miniActivityDistribution;
    _visibility = config.visibility;
    _newPlayerStartMode = config.newPlayerStartMode;
    _autoAwardAttendance = config.autoAwardAttendance;
    _allowOptOut = config.allowOptOut;
    _requireAbsenceReason = config.requireAbsenceReason;
    _requireAbsenceApproval = config.requireAbsenceApproval;
    _excludeValidAbsence = config.excludeValidAbsenceFromPercentage;
    _hasLoadedInitialConfig = true;
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(pointsConfigNotifierProvider.notifier).createOrUpdateConfig(
            teamId: widget.teamId,
            trainingPoints: int.tryParse(_trainingPointsController.text) ?? 1,
            matchPoints: int.tryParse(_matchPointsController.text) ?? 2,
            socialPoints: int.tryParse(_socialPointsController.text) ?? 1,
            trainingWeight:
                double.tryParse(_trainingWeightController.text) ?? 1.0,
            matchWeight: double.tryParse(_matchWeightController.text) ?? 1.5,
            socialWeight: double.tryParse(_socialWeightController.text) ?? 0.5,
            competitionWeight:
                double.tryParse(_competitionWeightController.text) ?? 1.0,
            miniActivityDistribution: _miniActivityDistribution,
            autoAwardAttendance: _autoAwardAttendance,
            visibility: _visibility,
            allowOptOut: _allowOptOut,
            requireAbsenceReason: _requireAbsenceReason,
            requireAbsenceApproval: _requireAbsenceApproval,
            excludeValidAbsenceFromPercentage: _excludeValidAbsence,
            newPlayerStartMode: _newPlayerStartMode,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Innstillinger lagret')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kunne ikke lagre innstillinger. Prøv igjen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(teamPointsConfigProvider(widget.teamId));
    final teamAsync = ref.watch(teamDetailProvider(widget.teamId));
    final theme = Theme.of(context);

    // Admin guard
    final isAdmin = teamAsync.value?.userIsAdmin ?? false;
    if (teamAsync.hasValue && !isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Poenginnstillinger')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Du har ikke tilgang til denne siden',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Kun administratorer kan endre poenginnstillinger',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poenginnstillinger'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveConfig,
            ),
        ],
      ),
      body: configAsync.when2(
        onRetry: () => ref.invalidate(teamPointsConfigProvider(widget.teamId)),
        data: (config) {
          // Load config values only once when data first arrives
          // Using addPostFrameCallback to avoid setState during build
          if (!_hasLoadedInitialConfig) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasLoadedInitialConfig) {
                setState(() {
                  _loadConfig(config);
                });
              }
            });
            // Return loading indicator while waiting for config to load
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Points per activity type
              SectionHeader(title: 'Poeng per aktivitet'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      NumberField(
                        controller: _trainingPointsController,
                        label: 'Trening',
                        icon: Icons.fitness_center,
                      ),
                      const SizedBox(height: 12),
                      NumberField(
                        controller: _matchPointsController,
                        label: 'Kamp',
                        icon: Icons.sports_soccer,
                      ),
                      const SizedBox(height: 12),
                      NumberField(
                        controller: _socialPointsController,
                        label: 'Sosialt',
                        icon: Icons.celebration,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Weights
              SectionHeader(title: 'Vekting for hovedleaderboard'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DecimalField(
                        controller: _trainingWeightController,
                        label: 'Trening-vekt',
                      ),
                      const SizedBox(height: 12),
                      DecimalField(
                        controller: _matchWeightController,
                        label: 'Kamp-vekt',
                      ),
                      const SizedBox(height: 12),
                      DecimalField(
                        controller: _socialWeightController,
                        label: 'Sosial-vekt',
                      ),
                      const SizedBox(height: 12),
                      DecimalField(
                        controller: _competitionWeightController,
                        label: 'Konkurranse-vekt',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Mini-activity distribution
              SectionHeader(title: 'Mini-aktiviteter'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poengfordeling',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<MiniActivityDistribution>(
                        segments: const [
                          ButtonSegment(
                            value: MiniActivityDistribution.winnerOnly,
                            label: Text('Kun vinner'),
                          ),
                          ButtonSegment(
                            value: MiniActivityDistribution.topThree,
                            label: Text('Topp 3'),
                          ),
                          ButtonSegment(
                            value: MiniActivityDistribution.allParticipants,
                            label: Text('Alle'),
                          ),
                        ],
                        selected: {_miniActivityDistribution},
                        onSelectionChanged: (set) {
                          setState(() {
                            _miniActivityDistribution = set.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Visibility
              SectionHeader(title: 'Synlighet'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hvem kan se poeng?',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<LeaderboardVisibility>(
                        segments: const [
                          ButtonSegment(
                            value: LeaderboardVisibility.all,
                            label: Text('Alle'),
                          ),
                          ButtonSegment(
                            value: LeaderboardVisibility.rankingOnly,
                            label: Text('Rangering'),
                          ),
                          ButtonSegment(
                            value: LeaderboardVisibility.ownOnly,
                            label: Text('Kun egen'),
                          ),
                        ],
                        selected: {_visibility},
                        onSelectionChanged: (set) {
                          setState(() {
                            _visibility = set.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // New player start
              SectionHeader(title: 'Nye spillere'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Starter med poeng fra',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<NewPlayerStartMode>(
                        segments: const [
                          ButtonSegment(
                            value: NewPlayerStartMode.fromJoin,
                            label: Text('Fra start'),
                          ),
                          ButtonSegment(
                            value: NewPlayerStartMode.wholeSeason,
                            label: Text('Hele sesong'),
                          ),
                          ButtonSegment(
                            value: NewPlayerStartMode.adminChooses,
                            label: Text('Admin velger'),
                          ),
                        ],
                        selected: {_newPlayerStartMode},
                        onSelectionChanged: (set) {
                          setState(() {
                            _newPlayerStartMode = set.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Toggle settings
              SectionHeader(title: 'Automatisering'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Automatisk poengtildeling'),
                      subtitle: const Text(
                        'Gi poeng automatisk ved oppmøteregistrering',
                      ),
                      value: _autoAwardAttendance,
                      onChanged: (value) {
                        setState(() => _autoAwardAttendance = value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Tillat opt-out'),
                      subtitle: const Text(
                        'Spillere kan velge å skjule seg fra leaderboard',
                      ),
                      value: _allowOptOut,
                      onChanged: (value) {
                        setState(() => _allowOptOut = value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Absence settings
              SectionHeader(title: 'Fravær'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Krev begrunnelse'),
                      subtitle: const Text(
                        'Spillere må oppgi årsak ved fravær',
                      ),
                      value: _requireAbsenceReason,
                      onChanged: (value) {
                        setState(() => _requireAbsenceReason = value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Krev godkjenning'),
                      subtitle: const Text(
                        'Admin må godkjenne fravær før det teller',
                      ),
                      value: _requireAbsenceApproval,
                      onChanged: (value) {
                        setState(() => _requireAbsenceApproval = value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Ekskluder gyldig fravær'),
                      subtitle: const Text(
                        'Gyldig fravær tas ikke med i prosentberegning',
                      ),
                      value: _excludeValidAbsence,
                      onChanged: (value) {
                        setState(() => _excludeValidAbsence = value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save button
              FilledButton.icon(
                onPressed: _isLoading ? null : _saveConfig,
                icon: const Icon(Icons.save),
                label: const Text('Lagre innstillinger'),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}
