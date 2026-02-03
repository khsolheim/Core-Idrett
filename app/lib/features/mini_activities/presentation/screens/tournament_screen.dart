import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/tournament.dart';
import '../../providers/tournament_provider.dart';
import '../widgets/tournament_bracket.dart';
import '../widgets/match_card.dart';
import '../widgets/match_result_sheet.dart';
import '../widgets/tournament_setup_sheet.dart';

/// Screen for viewing and managing a tournament
class TournamentScreen extends ConsumerWidget {
  final String tournamentId;
  final String miniActivityId;

  const TournamentScreen({
    super.key,
    required this.tournamentId,
    required this.miniActivityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentAsync = ref.watch(tournamentProvider(tournamentId));

    return tournamentAsync.when(
      data: (tournament) => _TournamentContent(
        tournament: tournament,
        miniActivityId: miniActivityId,
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Turnering')),
        body: Center(
          child: Text('Feil: $error'),
        ),
      ),
    );
  }
}

class _TournamentContent extends ConsumerStatefulWidget {
  final Tournament tournament;
  final String miniActivityId;

  const _TournamentContent({
    required this.tournament,
    required this.miniActivityId,
  });

  @override
  ConsumerState<_TournamentContent> createState() => _TournamentContentState();
}

class _TournamentContentState extends ConsumerState<_TournamentContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final hasGroups = widget.tournament.tournamentType == TournamentType.groupPlay ||
        widget.tournament.tournamentType == TournamentType.groupKnockout;
    _tabController = TabController(
      length: hasGroups ? 3 : 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditSheet() async {
    final result = await TournamentSetupSheet.show(
      context,
      miniActivityId: widget.miniActivityId,
      existingTournament: widget.tournament,
    );
    if (result != null && mounted) {
      // Refresh
      ref.invalidate(tournamentProvider(widget.tournament.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasGroups = widget.tournament.tournamentType == TournamentType.groupPlay ||
        widget.tournament.tournamentType == TournamentType.groupKnockout;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournament.tournamentType.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showEditSheet,
            tooltip: 'Innstillinger',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Bracket'),
            const Tab(text: 'Kamper'),
            if (hasGroups) const Tab(text: 'Grupper'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BracketTab(tournament: widget.tournament),
          _MatchesTab(tournament: widget.tournament),
          if (hasGroups) _GroupsTab(tournament: widget.tournament),
        ],
      ),
      floatingActionButton: widget.tournament.status == TournamentStatus.draft
          ? FloatingActionButton.extended(
              onPressed: () => _generateBracket(context, ref),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Generer bracket'),
            )
          : null,
    );
  }

  Future<void> _generateBracket(BuildContext context, WidgetRef ref) async {
    // Show participant selection dialog
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Velg deltakere for å generere bracket')),
    );
  }
}

class _BracketTab extends ConsumerWidget {
  final Tournament tournament;

  const _BracketTab({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roundsAsync = ref.watch(tournamentRoundsProvider(tournament.id));
    final matchesAsync = ref.watch(tournamentMatchesProvider(tournament.id));

    return roundsAsync.when(
      data: (rounds) => matchesAsync.when(
        data: (matches) => TournamentBracket(
          tournament: tournament,
          rounds: rounds,
          matches: matches,
          onMatchTap: (match) => _showMatchResult(context, match),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Feil: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Feil: $e')),
    );
  }

  void _showMatchResult(BuildContext context, TournamentMatch match) async {
    await MatchResultSheet.show(
      context,
      match: match,
      tournamentId: tournament.id,
      teamAName: match.teamAName,
      teamBName: match.teamBName,
    );
  }
}

class _MatchesTab extends ConsumerWidget {
  final Tournament tournament;

  const _MatchesTab({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(tournamentMatchesProvider(tournament.id));

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sports_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ingen kamper ennå',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        // Group matches by status
        final upcoming = matches.where((m) => m.status == MatchStatus.scheduled).toList();
        final inProgress = matches.where((m) => m.status == MatchStatus.inProgress).toList();
        final completed = matches.where((m) => m.status == MatchStatus.completed).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (inProgress.isNotEmpty) ...[
              _SectionHeader(title: 'Pågår (${inProgress.length})'),
              const SizedBox(height: 8),
              ...inProgress.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MatchCard(
                      match: m,
                      onTap: () => _showMatchResult(context, m),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            if (upcoming.isNotEmpty) ...[
              _SectionHeader(title: 'Kommende (${upcoming.length})'),
              const SizedBox(height: 8),
              ...upcoming.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MatchCard(
                      match: m,
                      onTap: () => _showMatchResult(context, m),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            if (completed.isNotEmpty) ...[
              _SectionHeader(title: 'Fullført (${completed.length})'),
              const SizedBox(height: 8),
              ...completed.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MatchCard(
                      match: m,
                      onTap: () => _showMatchResult(context, m),
                    ),
                  )),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Feil: $e')),
    );
  }

  void _showMatchResult(BuildContext context, TournamentMatch match) async {
    await MatchResultSheet.show(
      context,
      match: match,
      tournamentId: tournament.id,
      teamAName: match.teamAName,
      teamBName: match.teamBName,
    );
  }
}

class _GroupsTab extends ConsumerWidget {
  final Tournament tournament;

  const _GroupsTab({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(tournamentGroupsProvider(tournament.id));

    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.group_work_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ingen grupper ennå',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _GroupSection(
                group: group,
                tournamentId: tournament.id,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Feil: $e')),
    );
  }
}

class _GroupSection extends ConsumerWidget {
  final TournamentGroup group;
  final String tournamentId;

  const _GroupSection({
    required this.group,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final standings = group.sortedStandings;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.primaryContainer,
            child: Text(
              group.name,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Standings
          if (standings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Ingen lag i gruppen',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            )
          else
            ...standings.asMap().entries.map((entry) {
              final position = entry.key + 1;
              final standing = entry.value;
              final advances = position <= group.advanceCount;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: advances
                      ? theme.colorScheme.primaryContainer.withAlpha(77)
                      : null,
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$position.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        standing.teamName ?? 'Lag',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${standing.points}p',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
