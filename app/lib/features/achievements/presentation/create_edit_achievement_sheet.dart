import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/error_display_service.dart';
import '../../../data/models/achievement.dart';
import '../providers/achievement_provider.dart';

/// Bottom sheet for creating or editing an achievement definition
class CreateEditAchievementSheet extends ConsumerStatefulWidget {
  final String teamId;
  final AchievementDefinition? existingDefinition;

  const CreateEditAchievementSheet({
    super.key,
    required this.teamId,
    this.existingDefinition,
  });

  @override
  ConsumerState<CreateEditAchievementSheet> createState() =>
      _CreateEditAchievementSheetState();
}

class _CreateEditAchievementSheetState
    extends ConsumerState<CreateEditAchievementSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _iconController;
  late final TextEditingController _bonusPointsController;
  late final TextEditingController _thresholdController;

  late AchievementCategory _category;
  late AchievementTier _tier;
  late AchievementCriteriaType _criteriaType;
  late bool _isActive;
  late bool _isSecret;
  late bool _isRepeatable;

  bool _loading = false;

  bool get isEditing => widget.existingDefinition != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingDefinition;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _codeController = TextEditingController(text: existing?.code ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _iconController = TextEditingController(text: existing?.icon ?? '');
    _bonusPointsController =
        TextEditingController(text: (existing?.bonusPoints ?? 0).toString());
    _thresholdController = TextEditingController(
        text: (existing?.criteria.threshold ?? 10).toString());

    _category = existing?.category ?? AchievementCategory.milestone;
    _tier = existing?.tier ?? AchievementTier.bronze;
    _criteriaType =
        existing?.criteria.type ?? AchievementCriteriaType.attendanceStreak;
    _isActive = existing?.isActive ?? true;
    _isSecret = existing?.isSecret ?? false;
    _isRepeatable = existing?.isRepeatable ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    _bonusPointsController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: Text(
                    isEditing ? 'Rediger achievement' : 'Ny achievement',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Navn',
                border: OutlineInputBorder(),
                hintText: 'F.eks. "Treningsstrek"',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Code (only for new)
            if (!isEditing) ...[
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Kode (unik)',
                  border: OutlineInputBorder(),
                  hintText: 'F.eks. "training_streak_10"',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beskrivelse',
                border: OutlineInputBorder(),
                hintText: 'Hva må spilleren gjøre?',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Icon and Bonus Points row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _iconController,
                    decoration: const InputDecoration(
                      labelText: 'Ikon (emoji)',
                      border: OutlineInputBorder(),
                      hintText: 'F.eks. 🔥',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _bonusPointsController,
                    decoration: const InputDecoration(
                      labelText: 'Bonuspoeng',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category
            const Text('Kategori',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AchievementCategory.values.map((cat) {
                return ChoiceChip(
                  label: Text('${cat.icon} ${cat.displayName}'),
                  selected: _category == cat,
                  onSelected: (_) => setState(() => _category = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Tier
            const Text('Nivå', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<AchievementTier>(
              segments: AchievementTier.values.map((tier) {
                return ButtonSegment(
                  value: tier,
                  label: Text(tier.emoji),
                  tooltip: tier.displayName,
                );
              }).toList(),
              selected: {_tier},
              onSelectionChanged: (selection) {
                setState(() => _tier = selection.first);
              },
            ),
            const SizedBox(height: 16),

            // Criteria type
            const Text('Kriteriumtype',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<AchievementCriteriaType>(
              initialValue: _criteriaType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: AchievementCriteriaType.values
                  .where((t) => t != AchievementCriteriaType.custom)
                  .map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getCriteriaTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _criteriaType = value);
              },
            ),
            const SizedBox(height: 16),

            // Threshold
            if (_criteriaType != AchievementCriteriaType.perfectAttendance) ...[
              TextField(
                controller: _thresholdController,
                decoration: InputDecoration(
                  labelText: _getThresholdLabel(_criteriaType),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],

            // Flags
            const Text('Innstillinger',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Aktiv'),
                  selected: _isActive,
                  onSelected: (value) => setState(() => _isActive = value),
                ),
                FilterChip(
                  label: const Text('Hemmelig'),
                  selected: _isSecret,
                  onSelected: (value) => setState(() => _isSecret = value),
                ),
                FilterChip(
                  label: const Text('Kan gjentas'),
                  selected: _isRepeatable,
                  onSelected: (value) => setState(() => _isRepeatable = value),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Lagre endringer' : 'Opprett achievement'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getCriteriaTypeLabel(AchievementCriteriaType type) {
    switch (type) {
      case AchievementCriteriaType.attendanceStreak:
        return 'Oppmøte-streak (antall på rad)';
      case AchievementCriteriaType.attendanceTotal:
        return 'Totalt antall oppmøter';
      case AchievementCriteriaType.attendanceRate:
        return 'Oppmøteprosent';
      case AchievementCriteriaType.pointsTotal:
        return 'Totalt antall poeng';
      case AchievementCriteriaType.miniActivityWins:
        return 'Mini-aktivitet seire';
      case AchievementCriteriaType.perfectAttendance:
        return '100% oppmøte i sesong';
      case AchievementCriteriaType.socialEvents:
        return 'Sosiale arrangementer';
      case AchievementCriteriaType.custom:
        return 'Egendefinert';
    }
  }

  String _getThresholdLabel(AchievementCriteriaType type) {
    switch (type) {
      case AchievementCriteriaType.attendanceStreak:
        return 'Antall aktiviteter på rad';
      case AchievementCriteriaType.attendanceTotal:
        return 'Antall oppmøter';
      case AchievementCriteriaType.attendanceRate:
        return 'Prosent (0-100)';
      case AchievementCriteriaType.pointsTotal:
        return 'Antall poeng';
      case AchievementCriteriaType.miniActivityWins:
        return 'Antall seire';
      case AchievementCriteriaType.socialEvents:
        return 'Antall arrangementer';
      default:
        return 'Terskelverdi';
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final description = _descriptionController.text.trim();
    final icon = _iconController.text.trim();
    final bonusPoints = int.tryParse(_bonusPointsController.text.trim()) ?? 0;
    final threshold = int.tryParse(_thresholdController.text.trim()) ?? 10;

    if (name.isEmpty) {
      ErrorDisplayService.showWarning('Navn er påkrevd');
      return;
    }

    if (!isEditing && code.isEmpty) {
      ErrorDisplayService.showWarning('Kode er påkrevd');
      return;
    }

    setState(() => _loading = true);

    final criteria = AchievementCriteria(
      type: _criteriaType,
      threshold: _criteriaType == AchievementCriteriaType.perfectAttendance
          ? null
          : threshold,
      percentage: _criteriaType == AchievementCriteriaType.attendanceRate
          ? threshold.toDouble()
          : null,
    );

    if (isEditing) {
      final result = await ref
          .read(achievementDefinitionNotifierProvider.notifier)
          .updateDefinition(
            teamId: widget.teamId,
            definitionId: widget.existingDefinition!.id,
            name: name,
            description: description.isNotEmpty ? description : null,
            clearDescription: description.isEmpty,
            icon: icon.isNotEmpty ? icon : null,
            tier: _tier,
            criteria: criteria,
            bonusPoints: bonusPoints,
            isActive: _isActive,
            isSecret: _isSecret,
            isRepeatable: _isRepeatable,
          );

      if (mounted) {
        setState(() => _loading = false);
        if (result != null) {
          Navigator.pop(context);
          ErrorDisplayService.showSuccess('Achievement oppdatert');
        } else {
          ErrorDisplayService.showWarning('Kunne ikke oppdatere achievement');
        }
      }
    } else {
      final result = await ref
          .read(achievementDefinitionNotifierProvider.notifier)
          .createDefinition(
            teamId: widget.teamId,
            code: code,
            name: name,
            description: description.isNotEmpty ? description : null,
            icon: icon.isNotEmpty ? icon : null,
            tier: _tier,
            category: _category,
            criteria: criteria,
            bonusPoints: bonusPoints,
            isActive: _isActive,
            isSecret: _isSecret,
            isRepeatable: _isRepeatable,
          );

      if (mounted) {
        setState(() => _loading = false);
        if (result != null) {
          Navigator.pop(context);
          ErrorDisplayService.showSuccess('Achievement opprettet');
        } else {
          ErrorDisplayService.showWarning('Kunne ikke opprette achievement');
        }
      }
    }
  }
}
