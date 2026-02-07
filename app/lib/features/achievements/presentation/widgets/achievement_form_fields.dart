import 'package:flutter/material.dart';

/// Basic info form fields for creating/editing an achievement:
/// name, code, description, icon, and bonus points.
class AchievementBasicInfoFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController descriptionController;
  final TextEditingController iconController;
  final TextEditingController bonusPointsController;
  final bool isEditing;

  const AchievementBasicInfoFields({
    super.key,
    required this.nameController,
    required this.codeController,
    required this.descriptionController,
    required this.iconController,
    required this.bonusPointsController,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        TextField(
          controller: nameController,
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
            controller: codeController,
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
          controller: descriptionController,
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
                controller: iconController,
                decoration: const InputDecoration(
                  labelText: 'Ikon (emoji)',
                  border: OutlineInputBorder(),
                  hintText: 'F.eks. \u{1F525}',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: bonusPointsController,
                decoration: const InputDecoration(
                  labelText: 'Bonuspoeng',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
