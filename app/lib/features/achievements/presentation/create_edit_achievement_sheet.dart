import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/error_display_service.dart';
import '../../../data/models/achievement.dart';
import '../providers/achievement_provider.dart';
import 'widgets/achievement_criteria_section.dart';
import 'widgets/achievement_form_fields.dart';

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
  late final TextEditingController _cooldownDaysController;

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
    _cooldownDaysController = TextEditingController(
        text: (existing?.repeatCooldownDays ?? 30).toString());

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
    _cooldownDaysController.dispose();
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
                    isEditing ? 'Rediger prestasjon' : 'Ny prestasjon',
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

            // Basic info fields
            AchievementBasicInfoFields(
              nameController: _nameController,
              codeController: _codeController,
              descriptionController: _descriptionController,
              iconController: _iconController,
              bonusPointsController: _bonusPointsController,
              isEditing: isEditing,
            ),
            const SizedBox(height: 16),

            // Criteria section
            AchievementCriteriaSection(
              category: _category,
              tier: _tier,
              criteriaType: _criteriaType,
              thresholdController: _thresholdController,
              cooldownDaysController: _cooldownDaysController,
              isActive: _isActive,
              isSecret: _isSecret,
              isRepeatable: _isRepeatable,
              onCategoryChanged: (v) => setState(() => _category = v),
              onTierChanged: (v) => setState(() => _tier = v),
              onCriteriaTypeChanged: (v) =>
                  setState(() => _criteriaType = v),
              onActiveChanged: (v) => setState(() => _isActive = v),
              onSecretChanged: (v) => setState(() => _isSecret = v),
              onRepeatableChanged: (v) =>
                  setState(() => _isRepeatable = v),
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
                    : Text(isEditing ? 'Lagre endringer' : 'Opprett prestasjon'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Maximum bonus points allowed for an achievement
  static const int kMaxBonusPoints = 1000;

  /// Maximum threshold value allowed
  static const int kMaxThreshold = 10000;

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final description = _descriptionController.text.trim();
    final icon = _iconController.text.trim();
    final bonusPoints = int.tryParse(_bonusPointsController.text.trim()) ?? 0;
    final threshold = int.tryParse(_thresholdController.text.trim()) ?? 10;
    final cooldownDays = _isRepeatable
        ? int.tryParse(_cooldownDaysController.text.trim())
        : null;

    if (name.isEmpty) {
      ErrorDisplayService.showWarning('Navn er påkrevd');
      return;
    }

    if (!isEditing && code.isEmpty) {
      ErrorDisplayService.showWarning('Kode er påkrevd');
      return;
    }

    // Validate bonus points
    if (bonusPoints < 0) {
      ErrorDisplayService.showWarning('Bonuspoeng kan ikke være negative');
      return;
    }
    if (bonusPoints > kMaxBonusPoints) {
      ErrorDisplayService.showWarning('Maks $kMaxBonusPoints bonuspoeng tillatt');
      return;
    }

    // Validate threshold
    if (_criteriaType != AchievementCriteriaType.perfectAttendance) {
      if (threshold < 1) {
        ErrorDisplayService.showWarning('Terskelverdi må være minst 1');
        return;
      }
      if (threshold > kMaxThreshold) {
        ErrorDisplayService.showWarning('Terskelverdi kan ikke være over $kMaxThreshold');
        return;
      }
      // Special validation for percentage-based criteria
      if (_criteriaType == AchievementCriteriaType.attendanceRate && threshold > 100) {
        ErrorDisplayService.showWarning('Prosent må være mellom 0 og 100');
        return;
      }
    }

    // Validate cooldown for repeatable achievements
    if (_isRepeatable) {
      if (cooldownDays == null || cooldownDays < 1) {
        ErrorDisplayService.showWarning('Ventetid må være minst 1 dag for gjentakbare prestasjoner');
        return;
      }
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
            repeatCooldownDays: cooldownDays,
          );

      if (mounted) {
        setState(() => _loading = false);
        if (result != null) {
          Navigator.pop(context);
          ErrorDisplayService.showSuccess('Prestasjon oppdatert');
        } else {
          ErrorDisplayService.showWarning('Kunne ikke oppdatere prestasjon');
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
            repeatCooldownDays: cooldownDays,
          );

      if (mounted) {
        setState(() => _loading = false);
        if (result != null) {
          Navigator.pop(context);
          ErrorDisplayService.showSuccess('Prestasjon opprettet');
        } else {
          ErrorDisplayService.showWarning('Kunne ikke opprette prestasjon');
        }
      }
    }
  }
}
