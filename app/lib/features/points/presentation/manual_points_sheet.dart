import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/error_display_service.dart';
import '../../../data/models/points_config.dart';
import '../../../data/models/team.dart';
import '../providers/points_provider.dart';

/// Bottom sheet for admin to manually adjust points for a player
class ManualPointsSheet extends ConsumerStatefulWidget {
  final String teamId;
  final List<TeamMember> members;
  final String? preselectedUserId;

  const ManualPointsSheet({
    super.key,
    required this.teamId,
    required this.members,
    this.preselectedUserId,
  });

  @override
  ConsumerState<ManualPointsSheet> createState() => _ManualPointsSheetState();
}

class _ManualPointsSheetState extends ConsumerState<ManualPointsSheet> {
  TeamMember? _selectedMember;
  AdjustmentType _adjustmentType = AdjustmentType.bonus;
  final _pointsController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedUserId != null) {
      _selectedMember = widget.members.firstWhere(
        (m) => m.userId == widget.preselectedUserId,
        orElse: () => widget.members.first,
      );
    }
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Juster poeng',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Select player
            const Text(
              'Spiller',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TeamMember>(
              initialValue: _selectedMember,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Velg spiller',
              ),
              items: widget.members.map((member) {
                return DropdownMenuItem(
                  value: member,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: member.userAvatarUrl != null
                            ? NetworkImage(member.userAvatarUrl!)
                            : null,
                        child: member.userAvatarUrl == null
                            ? Text(member.userName.substring(0, 1).toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(member.userName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedMember = value),
            ),
            const SizedBox(height: 16),

            // Adjustment type
            const Text(
              'Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<AdjustmentType>(
              segments: [
                ButtonSegment(
                  value: AdjustmentType.bonus,
                  label: const Text('Bonus'),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                ButtonSegment(
                  value: AdjustmentType.penalty,
                  label: const Text('Straff'),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                ButtonSegment(
                  value: AdjustmentType.correction,
                  label: const Text('Korreksjon'),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
              selected: {_adjustmentType},
              onSelectionChanged: (selection) {
                setState(() => _adjustmentType = selection.first);
              },
            ),
            const SizedBox(height: 16),

            // Points
            Text(
              _adjustmentType == AdjustmentType.penalty
                  ? 'Poeng (trekkes fra)'
                  : 'Poeng',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pointsController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Antall poeng',
                prefixIcon: Icon(
                  _adjustmentType == AdjustmentType.penalty
                      ? Icons.remove
                      : Icons.add,
                  color: _adjustmentType == AdjustmentType.penalty
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Reason
            const Text(
              'Begrunnelse',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Hvorfor justeres poengene?',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            Text(
              'Begrunnelse er obligatorisk',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),

            // Preview
            if (_pointsController.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _adjustmentType == AdjustmentType.penalty
                          ? Icons.trending_down
                          : Icons.trending_up,
                      color: _adjustmentType == AdjustmentType.penalty
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getPreviewText(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _adjustmentType == AdjustmentType.penalty
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submitAdjustment,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Juster poeng'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getPreviewText() {
    final points = int.tryParse(_pointsController.text.trim()) ?? 0;
    final adjustedPoints =
        _adjustmentType == AdjustmentType.penalty ? -points : points;
    return '${adjustedPoints >= 0 ? '+' : ''}$adjustedPoints poeng';
  }

  Future<void> _submitAdjustment() async {
    if (_selectedMember == null) {
      ErrorDisplayService.showWarning('Du må velge en spiller');
      return;
    }

    final points = int.tryParse(_pointsController.text.trim());
    if (points == null || points <= 0) {
      ErrorDisplayService.showWarning('Du må skrive et gyldig antall poeng');
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ErrorDisplayService.showWarning('Du må skrive en begrunnelse');
      return;
    }

    setState(() => _loading = true);

    // Adjust points based on type - penalty should be negative
    final adjustedPoints =
        _adjustmentType == AdjustmentType.penalty ? -points : points;

    final result =
        await ref.read(manualAdjustmentNotifierProvider.notifier).createAdjustment(
              teamId: widget.teamId,
              userId: _selectedMember!.userId,
              points: adjustedPoints,
              adjustmentType: _adjustmentType,
              reason: reason,
            );

    if (mounted) {
      setState(() => _loading = false);
      if (result != null) {
        Navigator.pop(context);
        ErrorDisplayService.showSuccess(
          '${_adjustmentType.displayName} på $adjustedPoints poeng gitt til ${_selectedMember!.userName}',
        );
      } else {
        ErrorDisplayService.showWarning('Kunne ikke justere poeng. Prøv igjen.');
      }
    }
  }
}

/// Show the ManualPointsSheet as a bottom sheet
Future<void> showManualPointsSheet(
  BuildContext context, {
  required String teamId,
  required List<TeamMember> members,
  String? preselectedUserId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => ManualPointsSheet(
      teamId: teamId,
      members: members,
      preselectedUserId: preselectedUserId,
    ),
  );
}
