import 'package:flutter/material.dart';
import 'points_config_fields.dart';

/// Card with automation toggle switches (auto-award, opt-out)
class AutomationSettingsCard extends StatelessWidget {
  final bool autoAwardAttendance;
  final bool allowOptOut;
  final ValueChanged<bool> onAutoAwardChanged;
  final ValueChanged<bool> onAllowOptOutChanged;

  const AutomationSettingsCard({
    super.key,
    required this.autoAwardAttendance,
    required this.allowOptOut,
    required this.onAutoAwardChanged,
    required this.onAllowOptOutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Automatisering'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Automatisk poengtildeling'),
                subtitle: const Text(
                  'Gi poeng automatisk ved oppmøteregistrering',
                ),
                value: autoAwardAttendance,
                onChanged: onAutoAwardChanged,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Tillat opt-out'),
                subtitle: const Text(
                  'Spillere kan velge å skjule seg fra leaderboard',
                ),
                value: allowOptOut,
                onChanged: onAllowOptOutChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card with absence-related toggle switches
class AbsenceSettingsCard extends StatelessWidget {
  final bool requireAbsenceReason;
  final bool requireAbsenceApproval;
  final bool excludeValidAbsence;
  final ValueChanged<bool> onRequireReasonChanged;
  final ValueChanged<bool> onRequireApprovalChanged;
  final ValueChanged<bool> onExcludeValidChanged;

  const AbsenceSettingsCard({
    super.key,
    required this.requireAbsenceReason,
    required this.requireAbsenceApproval,
    required this.excludeValidAbsence,
    required this.onRequireReasonChanged,
    required this.onRequireApprovalChanged,
    required this.onExcludeValidChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Fravær'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Krev begrunnelse'),
                subtitle: const Text(
                  'Spillere må oppgi årsak ved fravær',
                ),
                value: requireAbsenceReason,
                onChanged: onRequireReasonChanged,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Krev godkjenning'),
                subtitle: const Text(
                  'Admin må godkjenne fravær før det teller',
                ),
                value: requireAbsenceApproval,
                onChanged: onRequireApprovalChanged,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Ekskluder gyldig fravær'),
                subtitle: const Text(
                  'Gyldig fravær tas ikke med i prosentberegning',
                ),
                value: excludeValidAbsence,
                onChanged: onExcludeValidChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
