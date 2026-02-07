import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/team.dart';

class EditTeamGeneralTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController sportController;
  final TextEditingController attendancePointsController;
  final TextEditingController winPointsController;
  final TextEditingController drawPointsController;
  final TextEditingController lossPointsController;
  final TextEditingController appealFeeController;
  final TextEditingController gameDayMultiplierController;
  final Team team;
  final TeamSettings settings;
  final VoidCallback onRegenerateInviteCode;

  const EditTeamGeneralTab({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.sportController,
    required this.attendancePointsController,
    required this.winPointsController,
    required this.drawPointsController,
    required this.lossPointsController,
    required this.appealFeeController,
    required this.gameDayMultiplierController,
    required this.team,
    required this.settings,
    required this.onRegenerateInviteCode,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team info section
            Text(
              'Laginformasjon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Lagnavn',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lagnavn er pakrevd';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: sportController,
              decoration: const InputDecoration(
                labelText: 'Idrett',
                border: OutlineInputBorder(),
                hintText: 'f.eks. Fotball, Handball, Basketball',
              ),
            ),

            const SizedBox(height: 24),

            // Invite code section
            Text(
              'Invitasjonskode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _InviteCodeCard(
              inviteCode: team.inviteCode,
              onRegenerate: onRegenerateInviteCode,
            ),

            const SizedBox(height: 24),

            // Points settings section
            Text(
              'Poenginnstillinger',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sett hvor mange poeng spillere skal fa i ulike situasjoner.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: PointsField(
                    controller: attendancePointsController,
                    label: 'Oppmote',
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PointsField(
                    controller: winPointsController,
                    label: 'Seier',
                    icon: Icons.emoji_events_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PointsField(
                    controller: drawPointsController,
                    label: 'Uavgjort',
                    icon: Icons.handshake_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PointsField(
                    controller: lossPointsController,
                    label: 'Tap',
                    icon: Icons.thumb_down_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Fine settings section
            Text(
              'Boteinnstillinger',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Innstillinger for boter og klager.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: appealFeeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Klagegebyr',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.gavel),
                suffixText: 'kr',
                helperText: 'Legges til ved avslatt klage',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Ugyldig belop';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: gameDayMultiplierController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Kampdagsmultiplikator',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_soccer),
                suffixText: 'x',
                helperText: 'F.eks. 2.0 = dobbelt belop pa kampdag',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed < 1.0) {
                    return 'Ma vare minst 1.0';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  final String? inviteCode;
  final VoidCallback onRegenerate;

  const _InviteCodeCard({
    required this.inviteCode,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          inviteCode ?? 'Ingen kode',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text('Del denne koden for a invitere nye medlemmer'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                if (inviteCode != null) {
                  Clipboard.setData(ClipboardData(text: inviteCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kode kopiert')),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRegenerate,
            ),
          ],
        ),
      ),
    );
  }
}

class PointsField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const PointsField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Pakrevd';
        }
        if (int.tryParse(value) == null) {
          return 'Ugyldig tall';
        }
        return null;
      },
    );
  }
}
