import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/tournament.dart';
import '../../providers/tournament_provider.dart';
import '../../../../core/services/error_display_service.dart';

/// Bottom sheet for recording match results
class MatchResultSheet extends ConsumerStatefulWidget {
  final TournamentMatch match;
  final String tournamentId;
  final String? teamAName;
  final String? teamBName;

  const MatchResultSheet({
    super.key,
    required this.match,
    required this.tournamentId,
    this.teamAName,
    this.teamBName,
  });

  static Future<TournamentMatch?> show(
    BuildContext context, {
    required TournamentMatch match,
    required String tournamentId,
    String? teamAName,
    String? teamBName,
  }) {
    return showModalBottomSheet<TournamentMatch>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => MatchResultSheet(
        match: match,
        tournamentId: tournamentId,
        teamAName: teamAName,
        teamBName: teamBName,
      ),
    );
  }

  @override
  ConsumerState<MatchResultSheet> createState() => _MatchResultSheetState();
}

class _MatchResultSheetState extends ConsumerState<MatchResultSheet> {
  late int _teamAScore;
  late int _teamBScore;
  bool _isWalkover = false;
  String? _walkoverWinner;
  String _walkoverReason = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _teamAScore = widget.match.teamAScore;
    _teamBScore = widget.match.teamBScore;
    _isWalkover = widget.match.isWalkover;
    _walkoverReason = widget.match.walkoverReason ?? '';
    if (_isWalkover && widget.match.winnerId != null) {
      _walkoverWinner = widget.match.winnerId;
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(matchNotifierProvider.notifier);

      TournamentMatch? result;
      if (_isWalkover && _walkoverWinner != null) {
        result = await notifier.declareWalkover(
          matchId: widget.match.id,
          tournamentId: widget.tournamentId,
          winnerId: _walkoverWinner!,
          reason: _walkoverReason.isNotEmpty ? _walkoverReason : null,
        );
      } else {
        result = await notifier.updateMatch(
          matchId: widget.match.id,
          tournamentId: widget.tournamentId,
          teamAScore: _teamAScore,
          teamBScore: _teamBScore,
        );
      }

      if (mounted && result != null) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayService.showSuccess('Kunne ikke lagre resultat. Prøv igjen.');
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
    final teamAName = widget.teamAName ?? 'Lag A';
    final teamBName = widget.teamBName ?? 'Lag B';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                    'Registrer resultat',
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
                  // Walkover toggle
                  SwitchListTile(
                    title: const Text('Walkover'),
                    subtitle: const Text('Motstanderen møtte ikke'),
                    value: _isWalkover,
                    onChanged: (value) {
                      setState(() {
                        _isWalkover = value;
                        if (value && _walkoverWinner == null) {
                          _walkoverWinner = widget.match.teamAId;
                        }
                      });
                    },
                  ),

                  if (_isWalkover) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Hvem vinner?',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String?>(
                      segments: [
                        ButtonSegment(
                          value: widget.match.teamAId,
                          label: Text(teamAName),
                        ),
                        ButtonSegment(
                          value: widget.match.teamBId,
                          label: Text(teamBName),
                        ),
                      ],
                      selected: {_walkoverWinner},
                      onSelectionChanged: (selection) {
                        setState(() => _walkoverWinner = selection.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Årsak (valgfritt)',
                        hintText: 'F.eks. møtte ikke',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _walkoverReason = value,
                    ),
                  ] else ...[
                    const SizedBox(height: 24),

                    // Score entry
                    Row(
                      children: [
                        Expanded(
                          child: _ScoreEntry(
                            teamName: teamAName,
                            score: _teamAScore,
                            onChanged: (value) => setState(() => _teamAScore = value),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '-',
                            style: theme.textTheme.headlineLarge,
                          ),
                        ),
                        Expanded(
                          child: _ScoreEntry(
                            teamName: teamBName,
                            score: _teamBScore,
                            onChanged: (value) => setState(() => _teamBScore = value),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick score buttons
                    Text(
                      'Hurtigvalg',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _QuickScoreChip(
                          label: '1-0',
                          onTap: () => setState(() {
                            _teamAScore = 1;
                            _teamBScore = 0;
                          }),
                        ),
                        _QuickScoreChip(
                          label: '2-0',
                          onTap: () => setState(() {
                            _teamAScore = 2;
                            _teamBScore = 0;
                          }),
                        ),
                        _QuickScoreChip(
                          label: '2-1',
                          onTap: () => setState(() {
                            _teamAScore = 2;
                            _teamBScore = 1;
                          }),
                        ),
                        _QuickScoreChip(
                          label: '0-1',
                          onTap: () => setState(() {
                            _teamAScore = 0;
                            _teamBScore = 1;
                          }),
                        ),
                        _QuickScoreChip(
                          label: '0-2',
                          onTap: () => setState(() {
                            _teamAScore = 0;
                            _teamBScore = 2;
                          }),
                        ),
                        _QuickScoreChip(
                          label: '1-2',
                          onTap: () => setState(() {
                            _teamAScore = 1;
                            _teamBScore = 2;
                          }),
                        ),
                        _QuickScoreChip(
                          label: '1-1',
                          onTap: () => setState(() {
                            _teamAScore = 1;
                            _teamBScore = 1;
                          }),
                        ),
                      ],
                    ),
                  ],
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
                    : const Text('Lagre resultat'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScoreEntry extends StatelessWidget {
  final String teamName;
  final int score;
  final ValueChanged<int> onChanged;

  const _ScoreEntry({
    required this.teamName,
    required this.score,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          teamName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              onPressed: score > 0 ? () => onChanged(score - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$score',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton.filled(
              onPressed: () => onChanged(score + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickScoreChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickScoreChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
