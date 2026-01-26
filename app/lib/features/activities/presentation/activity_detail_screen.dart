import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/activity.dart';
import '../providers/activity_provider.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final String teamId;
  final String instanceId;

  const ActivityDetailScreen({
    super.key,
    required this.teamId,
    required this.instanceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instanceAsync = ref.watch(instanceDetailProvider(instanceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitet'),
      ),
      body: instanceAsync.when(
        data: (instance) => _ActivityDetailContent(
          instance: instance,
          teamId: teamId,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Kunne ikke laste aktivitet: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(instanceDetailProvider(instanceId)),
                child: const Text('Prøv igjen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityDetailContent extends ConsumerStatefulWidget {
  final ActivityInstance instance;
  final String teamId;

  const _ActivityDetailContent({
    required this.instance,
    required this.teamId,
  });

  @override
  ConsumerState<_ActivityDetailContent> createState() => _ActivityDetailContentState();
}

class _ActivityDetailContentState extends ConsumerState<_ActivityDetailContent> {
  bool _isResponding = false;

  Future<void> _respond(UserResponse? response) async {
    setState(() => _isResponding = true);

    final success = await ref.read(activityResponseProvider.notifier).respond(
          instanceId: widget.instance.id,
          teamId: widget.teamId,
          response: response,
        );

    if (mounted) {
      setState(() => _isResponding = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Svar registrert')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke registrere svar')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d. MMMM yyyy', 'nb_NO');
    final instance = widget.instance;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(instanceDetailProvider(widget.instance.id));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TypeChip(type: instance.type ?? ActivityType.other),
                        const SizedBox(width: 8),
                        if (instance.status == InstanceStatus.cancelled)
                          Chip(
                            label: const Text('Avlyst'),
                            backgroundColor: theme.colorScheme.errorContainer,
                            labelStyle: TextStyle(color: theme.colorScheme.onErrorContainer),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      instance.title ?? 'Aktivitet',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.calendar_today,
                      text: dateFormat.format(instance.date),
                    ),
                    if (instance.startTime != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.access_time,
                        text: instance.formattedTime,
                      ),
                    ],
                    if (instance.location != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.location_on,
                        text: instance.location!,
                      ),
                    ],
                    if (instance.description != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        instance.description!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Response section
            if (instance.status != InstanceStatus.cancelled) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ditt svar',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      if (_isResponding)
                        const Center(child: CircularProgressIndicator())
                      else
                        _ResponseButtons(
                          currentResponse: instance.userResponse,
                          responseType: instance.responseType ?? ResponseType.yesNo,
                          onRespond: _respond,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Responses list
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Svar',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        _ResponseSummary(
                          yesCount: instance.yesCount ?? 0,
                          noCount: instance.noCount ?? 0,
                          maybeCount: instance.maybeCount ?? 0,
                          showMaybe: instance.responseType == ResponseType.yesNoMaybe,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (instance.responses?.isEmpty ?? true)
                      Text(
                        'Ingen har svart ennå',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      )
                    else
                      ...instance.responses!.map(
                        (response) => _ResponseListItem(response: response),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ActivityType type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_getIcon(), size: 18),
      label: Text(type.displayName),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case ActivityType.training:
        return Icons.fitness_center;
      case ActivityType.match:
        return Icons.sports_soccer;
      case ActivityType.social:
        return Icons.celebration;
      case ActivityType.other:
        return Icons.event;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _ResponseButtons extends StatelessWidget {
  final UserResponse? currentResponse;
  final ResponseType responseType;
  final void Function(UserResponse?) onRespond;

  const _ResponseButtons({
    required this.currentResponse,
    required this.responseType,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ResponseButton(
            response: UserResponse.yes,
            isSelected: currentResponse == UserResponse.yes,
            onTap: () => onRespond(UserResponse.yes),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ResponseButton(
            response: UserResponse.no,
            isSelected: currentResponse == UserResponse.no,
            onTap: () => onRespond(UserResponse.no),
          ),
        ),
        if (responseType == ResponseType.yesNoMaybe) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _ResponseButton(
              response: UserResponse.maybe,
              isSelected: currentResponse == UserResponse.maybe,
              onTap: () => onRespond(UserResponse.maybe),
            ),
          ),
        ],
      ],
    );
  }
}

class _ResponseButton extends StatelessWidget {
  final UserResponse response;
  final bool isSelected;
  final VoidCallback onTap;

  const _ResponseButton({
    required this.response,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (response) {
      case UserResponse.yes:
        color = Colors.green;
        icon = Icons.check;
        break;
      case UserResponse.no:
        color = Colors.red;
        icon = Icons.close;
        break;
      case UserResponse.maybe:
        color = Colors.orange;
        icon = Icons.help_outline;
        break;
    }

    if (isSelected) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(response.displayName),
        style: FilledButton.styleFrom(backgroundColor: color),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      label: Text(response.displayName),
    );
  }
}

class _ResponseSummary extends StatelessWidget {
  final int yesCount;
  final int noCount;
  final int maybeCount;
  final bool showMaybe;

  const _ResponseSummary({
    required this.yesCount,
    required this.noCount,
    required this.maybeCount,
    required this.showMaybe,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 16, color: Colors.green),
        const SizedBox(width: 2),
        Text('$yesCount'),
        const SizedBox(width: 8),
        Icon(Icons.cancel, size: 16, color: Colors.red),
        const SizedBox(width: 2),
        Text('$noCount'),
        if (showMaybe) ...[
          const SizedBox(width: 8),
          Icon(Icons.help, size: 16, color: Colors.orange),
          const SizedBox(width: 2),
          Text('$maybeCount'),
        ],
      ],
    );
  }
}

class _ResponseListItem extends StatelessWidget {
  final ActivityResponseItem response;

  const _ResponseListItem({required this.response});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? indicatorColor;
    switch (response.response) {
      case UserResponse.yes:
        indicatorColor = Colors.green;
        break;
      case UserResponse.no:
        indicatorColor = Colors.red;
        break;
      case UserResponse.maybe:
        indicatorColor = Colors.orange;
        break;
      default:
        indicatorColor = theme.colorScheme.outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundImage: response.userAvatarUrl != null
                ? NetworkImage(response.userAvatarUrl!)
                : null,
            child: response.userAvatarUrl == null
                ? Text(response.userName?.substring(0, 1).toUpperCase() ?? '?')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  response.userName ?? 'Ukjent',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (response.comment != null)
                  Text(
                    response.comment!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            response.response?.displayName ?? 'Ikke svart',
            style: theme.textTheme.bodySmall?.copyWith(
              color: indicatorColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
