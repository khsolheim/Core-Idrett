import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/activity.dart';

class ResponseButtons extends StatelessWidget {
  final UserResponse? currentResponse;
  final ResponseType responseType;
  final void Function(UserResponse?) onRespond;

  const ResponseButtons({
    super.key,
    required this.currentResponse,
    required this.responseType,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ResponseButton(
            response: UserResponse.yes,
            isSelected: currentResponse == UserResponse.yes,
            onTap: () => onRespond(UserResponse.yes),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ResponseButton(
            response: UserResponse.no,
            isSelected: currentResponse == UserResponse.no,
            onTap: () => onRespond(UserResponse.no),
          ),
        ),
        if (responseType == ResponseType.yesNoMaybe) ...[
          const SizedBox(width: 8),
          Expanded(
            child: ResponseButton(
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

class ResponseButton extends StatelessWidget {
  final UserResponse response;
  final bool isSelected;
  final VoidCallback onTap;

  const ResponseButton({
    super.key,
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

class ResponseSummary extends StatelessWidget {
  final int yesCount;
  final int noCount;
  final int maybeCount;
  final bool showMaybe;

  const ResponseSummary({
    super.key,
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

class ResponseListItem extends StatelessWidget {
  final ActivityResponseItem response;

  const ResponseListItem({super.key, required this.response});

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
                ? CachedNetworkImageProvider(response.userAvatarUrl!)
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
