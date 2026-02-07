import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/activity.dart';

/// Form fields for editing an activity instance:
/// title, date, time, location, and description.
class EditInstanceFormFields extends StatelessWidget {
  final ActivityInstance instance;
  final EditScope scope;
  final TextEditingController titleController;
  final TextEditingController locationController;
  final TextEditingController descriptionController;
  final DateTime? date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectStartTime;
  final VoidCallback onSelectEndTime;

  const EditInstanceFormFields({
    super.key,
    required this.instance,
    required this.scope,
    required this.titleController,
    required this.locationController,
    required this.descriptionController,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.onSelectDate,
    required this.onSelectStartTime,
    required this.onSelectEndTime,
  });

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d. MMMM yyyy', 'nb_NO');
    final theme = Theme.of(context);

    return Column(
      children: [
        // Title
        TextFormField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: 'Tittel',
            suffixIcon: instance.titleOverride != null
                ? Tooltip(
                    message: 'Har egendefinert verdi',
                    child: Icon(
                      Icons.edit,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : null,
          ),
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vennligst skriv inn en tittel';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Date (only for single scope)
        if (scope == EditScope.single) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Dato'),
            subtitle: Text(
                date != null ? dateFormat.format(date!) : 'Ikke satt'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (instance.dateOverride != null)
                  Tooltip(
                    message: 'Har egendefinert dato',
                    child: Icon(
                      Icons.edit,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: onSelectDate,
          ),
          const Divider(),
        ],

        // Time
        Row(
          children: [
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Fra'),
                subtitle: Text(
                  startTime != null
                      ? _formatTimeOfDay(startTime!)
                      : 'Ikke satt',
                ),
                onTap: onSelectStartTime,
              ),
            ),
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Til'),
                subtitle: Text(
                  endTime != null
                      ? _formatTimeOfDay(endTime!)
                      : 'Ikke satt',
                ),
                onTap: onSelectEndTime,
              ),
            ),
          ],
        ),
        if (instance.startTimeOverride != null ||
            instance.endTimeOverride != null)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              'Har egendefinerte tidspunkter',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        const Divider(),

        // Location
        TextFormField(
          controller: locationController,
          decoration: InputDecoration(
            labelText: 'Sted (valgfritt)',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: instance.locationOverride != null
                ? Tooltip(
                    message: 'Har egendefinert verdi',
                    child: Icon(
                      Icons.edit,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : null,
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: descriptionController,
          decoration: InputDecoration(
            labelText: 'Beskrivelse (valgfritt)',
            alignLabelWithHint: true,
            suffixIcon: instance.descriptionOverride != null
                ? Tooltip(
                    message: 'Har egendefinert verdi',
                    child: Icon(
                      Icons.edit,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : null,
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
