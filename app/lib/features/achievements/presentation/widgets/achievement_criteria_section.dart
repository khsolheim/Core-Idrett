import 'package:flutter/material.dart';
import '../../../../data/models/achievement.dart';

/// Section for selecting achievement category, tier, criteria type,
/// threshold, flags (active/secret/repeatable), and cooldown.
class AchievementCriteriaSection extends StatelessWidget {
  final AchievementCategory category;
  final AchievementTier tier;
  final AchievementCriteriaType criteriaType;
  final TextEditingController thresholdController;
  final TextEditingController cooldownDaysController;
  final bool isActive;
  final bool isSecret;
  final bool isRepeatable;
  final ValueChanged<AchievementCategory> onCategoryChanged;
  final ValueChanged<AchievementTier> onTierChanged;
  final ValueChanged<AchievementCriteriaType> onCriteriaTypeChanged;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<bool> onSecretChanged;
  final ValueChanged<bool> onRepeatableChanged;

  const AchievementCriteriaSection({
    super.key,
    required this.category,
    required this.tier,
    required this.criteriaType,
    required this.thresholdController,
    required this.cooldownDaysController,
    required this.isActive,
    required this.isSecret,
    required this.isRepeatable,
    required this.onCategoryChanged,
    required this.onTierChanged,
    required this.onCriteriaTypeChanged,
    required this.onActiveChanged,
    required this.onSecretChanged,
    required this.onRepeatableChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              selected: category == cat,
              onSelected: (_) => onCategoryChanged(cat),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Tier
        const Text('Nivå', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<AchievementTier>(
          segments: AchievementTier.values.map((t) {
            return ButtonSegment(
              value: t,
              label: Text(t.emoji),
              tooltip: t.displayName,
            );
          }).toList(),
          selected: {tier},
          onSelectionChanged: (selection) =>
              onTierChanged(selection.first),
        ),
        const SizedBox(height: 16),

        // Criteria type
        const Text('Kriteriumtype',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<AchievementCriteriaType>(
          initialValue: criteriaType,
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
            if (value != null) onCriteriaTypeChanged(value);
          },
        ),
        const SizedBox(height: 16),

        // Threshold
        if (criteriaType != AchievementCriteriaType.perfectAttendance) ...[
          TextField(
            controller: thresholdController,
            decoration: InputDecoration(
              labelText: _getThresholdLabel(criteriaType),
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
              selected: isActive,
              onSelected: onActiveChanged,
            ),
            FilterChip(
              label: const Text('Hemmelig'),
              selected: isSecret,
              onSelected: onSecretChanged,
            ),
            FilterChip(
              label: const Text('Kan gjentas'),
              selected: isRepeatable,
              onSelected: onRepeatableChanged,
            ),
          ],
        ),

        // Cooldown days (shown when repeatable is enabled)
        if (isRepeatable) ...[
          const SizedBox(height: 16),
          TextField(
            controller: cooldownDaysController,
            decoration: const InputDecoration(
              labelText: 'Ventetid mellom gjentagelser (dager)',
              border: OutlineInputBorder(),
              hintText: 'F.eks. 30 dager',
              helperText:
                  'Hvor lenge må spilleren vente før achievement kan oppnås igjen',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ],
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
}
