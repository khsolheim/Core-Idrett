import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/dashboard_provider.dart';

/// Widget showing fines summary
class FinesWidget extends StatelessWidget {
  final FinesSummary summary;
  final String teamId;

  const FinesWidget({
    super.key,
    required this.summary,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnpaid = summary.unpaidCount > 0;
    final hasPending = summary.pendingApproval > 0;

    return Card(
      child: InkWell(
        onTap: () => context.pushNamed('fines', pathParameters: {'teamId': teamId}),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasUnpaid
                      ? Colors.red.withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: hasUnpaid ? Colors.red : theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Botekasse',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasUnpaid)
                      Text(
                        '${summary.unpaidCount} ubetalte (${summary.unpaidAmount.toStringAsFixed(0)} kr)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      )
                    else if (hasPending)
                      Text(
                        '${summary.pendingApproval} venter godkjenning',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                      )
                    else
                      Text(
                        'Ingen ubetalte boter',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
