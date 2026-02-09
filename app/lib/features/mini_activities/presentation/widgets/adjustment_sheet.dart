import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/mini_activity.dart';
import '../../providers/mini_activity_provider.dart';
import '../../../../core/services/error_display_service.dart';

/// Bottom sheet for awarding bonus or penalty points
class AdjustmentSheet extends ConsumerStatefulWidget {
  final String miniActivityId;
  final List<AdjustmentTarget> availableTargets;
  final bool initialIsBonus;

  const AdjustmentSheet({
    super.key,
    required this.miniActivityId,
    required this.availableTargets,
    this.initialIsBonus = true,
  });

  static Future<MiniActivityAdjustment?> show(
    BuildContext context, {
    required String miniActivityId,
    required List<AdjustmentTarget> availableTargets,
    bool initialIsBonus = true,
  }) {
    return showModalBottomSheet<MiniActivityAdjustment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AdjustmentSheet(
        miniActivityId: miniActivityId,
        availableTargets: availableTargets,
        initialIsBonus: initialIsBonus,
      ),
    );
  }

  @override
  ConsumerState<AdjustmentSheet> createState() => _AdjustmentSheetState();
}

class _AdjustmentSheetState extends ConsumerState<AdjustmentSheet> {
  late bool _isBonus;
  int _points = 1;
  String? _selectedTeamId;
  String? _selectedUserId;
  String _reason = '';
  bool _isLoading = false;

  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isBonus = widget.initialIsBonus;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _canSave {
    return (_selectedTeamId != null || _selectedUserId != null) && _points > 0;
  }

  Future<void> _save() async {
    if (!_canSave) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(adjustmentProvider.notifier);
      final result = await notifier.awardAdjustment(
        miniActivityId: widget.miniActivityId,
        miniTeamId: _selectedTeamId,
        userId: _selectedUserId,
        points: _isBonus ? _points : -_points,
        reason: _reason.isNotEmpty ? _reason : null,
      );

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayService.showSuccess('Kunne ikke lagre justering. Prøv igjen.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final teams = widget.availableTargets.where((t) => t.isTeam).toList();
    final users = widget.availableTargets.where((t) => !t.isTeam).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withAlpha(102),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _isBonus ? 'Gi bonus' : 'Gi straff',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Bonus/Penalty toggle
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Bonus'),
                        icon: Icon(Icons.add_circle),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Straff'),
                        icon: Icon(Icons.remove_circle),
                      ),
                    ],
                    selected: {_isBonus},
                    onSelectionChanged: (selection) {
                      setState(() => _isBonus = selection.first);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Points
                  Text(
                    'Antall poeng',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        onPressed: _points > 1 ? () => setState(() => _points--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isBonus
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_isBonus ? '+' : '-'}$_points',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isBonus ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () => setState(() => _points++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [1, 2, 3, 5, 10].map((n) {
                      return ActionChip(
                        label: Text('$n'),
                        onPressed: () => setState(() => _points = n),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Target selection
                  Text(
                    'Hvem skal få ${_isBonus ? 'bonus' : 'straff'}?',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  if (teams.isNotEmpty) ...[
                    Text(
                      'Lag',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: teams.map((team) {
                        final isSelected = _selectedTeamId == team.id;
                        return ChoiceChip(
                          label: Text(team.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTeamId = team.id;
                                _selectedUserId = null;
                              } else {
                                _selectedTeamId = null;
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (users.isNotEmpty) ...[
                    Text(
                      'Spillere',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: users.map((user) {
                        final isSelected = _selectedUserId == user.id;
                        return ChoiceChip(
                          label: Text(user.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedUserId = user.id;
                                _selectedTeamId = null;
                              } else {
                                _selectedUserId = null;
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Reason
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: 'Årsak (valgfritt)',
                      hintText: _isBonus ? 'F.eks. Beste innsats' : 'F.eks. Kom for sent',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => _reason = value,
                  ),
                ],
              ),
            ),

            // Save button
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: FilledButton(
                onPressed: _canSave && !_isLoading ? _save : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: _isBonus ? Colors.green : Colors.red.shade700,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isBonus ? 'Gi bonus' : 'Gi straff'),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Model for adjustment target (team or user)
class AdjustmentTarget {
  final String id;
  final String name;
  final bool isTeam;

  const AdjustmentTarget({
    required this.id,
    required this.name,
    required this.isTeam,
  });

  factory AdjustmentTarget.team({required String id, required String name}) {
    return AdjustmentTarget(id: id, name: name, isTeam: true);
  }

  factory AdjustmentTarget.user({required String id, required String name}) {
    return AdjustmentTarget(id: id, name: name, isTeam: false);
  }
}
