import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/tournament.dart';
import '../../providers/tournament_provider.dart';
import '../../../../core/services/error_display_service.dart';

/// Bottom sheet for creating/configuring a tournament
class TournamentSetupSheet extends ConsumerStatefulWidget {
  final String miniActivityId;
  final Tournament? existingTournament;

  const TournamentSetupSheet({
    super.key,
    required this.miniActivityId,
    this.existingTournament,
  });

  static Future<Tournament?> show(
    BuildContext context, {
    required String miniActivityId,
    Tournament? existingTournament,
  }) {
    return showModalBottomSheet<Tournament>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => TournamentSetupSheet(
        miniActivityId: miniActivityId,
        existingTournament: existingTournament,
      ),
    );
  }

  @override
  ConsumerState<TournamentSetupSheet> createState() => _TournamentSetupSheetState();
}

class _TournamentSetupSheetState extends ConsumerState<TournamentSetupSheet> {
  late TournamentType _tournamentType;
  late int _bestOf;
  late bool _bronzeFinal;
  late SeedingMethod _seedingMethod;
  int? _maxParticipants;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTournament;
    _tournamentType = existing?.tournamentType ?? TournamentType.singleElimination;
    _bestOf = existing?.bestOf ?? 1;
    _bronzeFinal = existing?.bronzeFinal ?? false;
    _seedingMethod = existing?.seedingMethod ?? SeedingMethod.random;
    _maxParticipants = existing?.maxParticipants;
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(tournamentNotifierProvider.notifier);

      Tournament? result;
      if (widget.existingTournament != null) {
        result = await notifier.updateTournament(
          tournamentId: widget.existingTournament!.id,
          miniActivityId: widget.miniActivityId,
          tournamentType: _tournamentType,
          bestOf: _bestOf,
          bronzeFinal: _bronzeFinal,
          seedingMethod: _seedingMethod,
          maxParticipants: _maxParticipants,
        );
      } else {
        result = await notifier.createTournament(
          miniActivityId: widget.miniActivityId,
          tournamentType: _tournamentType,
          bestOf: _bestOf,
          bronzeFinal: _bronzeFinal,
          seedingMethod: _seedingMethod,
          maxParticipants: _maxParticipants,
        );
      }

      if (mounted && result != null) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayService.showSuccess('Kunne ikke lagre turnering. Prøv igjen.');
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
    final isEditing = widget.existingTournament != null;

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
                    isEditing ? 'Rediger turnering' : 'Opprett turnering',
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
                  // Tournament type
                  Text(
                    'Turneringsformat',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _TournamentTypeSelector(
                    value: _tournamentType,
                    onChanged: (type) => setState(() => _tournamentType = type),
                  ),
                  const SizedBox(height: 24),

                  // Best of
                  Text(
                    'Antall kamper per møte',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _BestOfSelector(
                    value: _bestOf,
                    onChanged: (value) => setState(() => _bestOf = value),
                  ),
                  const SizedBox(height: 24),

                  // Seeding method
                  Text(
                    'Seeding-metode',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _SeedingMethodSelector(
                    value: _seedingMethod,
                    onChanged: (method) => setState(() => _seedingMethod = method),
                  ),
                  const SizedBox(height: 24),

                  // Bronze final (only for elimination)
                  if (_tournamentType == TournamentType.singleElimination ||
                      _tournamentType == TournamentType.groupKnockout) ...[
                    SwitchListTile(
                      title: const Text('Bronsefinale'),
                      subtitle: const Text('Kamp om 3. plass'),
                      value: _bronzeFinal,
                      onChanged: (value) => setState(() => _bronzeFinal = value),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Max participants
                  Text(
                    'Maks deltakere (valgfritt)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Ubegrenset',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: _maxParticipants?.toString() ?? '',
                    ),
                    onChanged: (value) {
                      _maxParticipants = int.tryParse(value);
                    },
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
                onPressed: _isLoading ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Lagre endringer' : 'Opprett turnering'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TournamentTypeSelector extends StatelessWidget {
  final TournamentType value;
  final ValueChanged<TournamentType> onChanged;

  const _TournamentTypeSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<TournamentType>(
      groupValue: value,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      child: Column(
        children: TournamentType.values.map((type) {
          return RadioListTile<TournamentType>(
            title: Text(type.displayName),
            subtitle: Text(_getDescription(type)),
            value: type,
            dense: true,
          );
        }).toList(),
      ),
    );
  }

  String _getDescription(TournamentType type) {
    switch (type) {
      case TournamentType.singleElimination:
        return 'Tap = ute av turneringen';
      case TournamentType.doubleElimination:
        return 'To tap før du er ute';
      case TournamentType.groupPlay:
        return 'Alle møter alle i grupper';
      case TournamentType.groupKnockout:
        return 'Gruppespill etterfulgt av sluttspill';
    }
  }
}

class _BestOfSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _BestOfSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [1, 3, 5, 7];

    return SegmentedButton<int>(
      segments: options.map((n) {
        return ButtonSegment(
          value: n,
          label: Text(n == 1 ? '1 kamp' : 'Best of $n'),
        );
      }).toList(),
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _SeedingMethodSelector extends StatelessWidget {
  final SeedingMethod value;
  final ValueChanged<SeedingMethod> onChanged;

  const _SeedingMethodSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<SeedingMethod>(
      groupValue: value,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      child: Column(
        children: SeedingMethod.values.map((method) {
          return RadioListTile<SeedingMethod>(
            title: Text(method.displayName),
            value: method,
            dense: true,
          );
        }).toList(),
      ),
    );
  }
}
