import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Returns true if both dates fall on the same calendar day
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Shows a confirmation dialog for deleting a message.
///
/// [onConfirm] is called when the user confirms the deletion.
void showDeleteMessageDialog(BuildContext context, {required VoidCallback onConfirm}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Slett melding'),
      content: const Text('Er du sikker pa at du vil slette denne meldingen?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Slett'),
        ),
      ],
    ),
  );
}

/// Date divider between messages
class DateDivider extends StatelessWidget {
  final DateTime date;

  const DateDivider({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1;

    String text;
    if (isToday) {
      text = 'I dag';
    } else if (isYesterday) {
      text = 'I gar';
    } else {
      text = DateFormat('EEEE d. MMMM', 'nb_NO').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: theme.colorScheme.outline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(child: Divider(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}
