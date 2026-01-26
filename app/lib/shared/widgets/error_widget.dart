import 'package:flutter/material.dart';
import '../../core/errors/app_exceptions.dart';

/// Widget for displaying error states with retry option
class AppErrorWidget extends StatelessWidget {
  final AppException exception;
  final VoidCallback? onRetry;
  final bool compact;

  const AppErrorWidget({
    super.key,
    required this.exception,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            _getIcon(),
            color: _getColor(context),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              exception.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRetry,
              tooltip: 'Prøv igjen',
            ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(),
              size: 64,
              color: _getColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              _getTitle(),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              exception.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Prøv igjen'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    if (exception is NoInternetException) {
      return Icons.wifi_off_rounded;
    }
    if (exception is TimeoutException) {
      return Icons.timer_off_rounded;
    }
    if (exception is NetworkException) {
      return Icons.cloud_off_rounded;
    }
    if (exception is AuthException) {
      return Icons.lock_outline_rounded;
    }
    if (exception is NotFoundException) {
      return Icons.search_off_rounded;
    }
    if (exception is ValidationException) {
      return Icons.warning_amber_rounded;
    }
    if (exception is ServerException || exception is ServiceUnavailableException) {
      return Icons.dns_rounded;
    }
    if (exception is RateLimitException) {
      return Icons.speed_rounded;
    }
    return Icons.error_outline_rounded;
  }

  Color _getColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (exception is NoInternetException || exception is NetworkException) {
      return Colors.orange;
    }
    if (exception is AuthException) {
      return colorScheme.error;
    }
    if (exception is ValidationException) {
      return Colors.amber.shade700;
    }
    if (exception is RateLimitException) {
      return Colors.blue;
    }
    return colorScheme.error;
  }

  String _getTitle() {
    if (exception is NoInternetException) {
      return 'Ingen tilkobling';
    }
    if (exception is TimeoutException) {
      return 'Tidsavbrudd';
    }
    if (exception is NetworkException) {
      return 'Nettverksfeil';
    }
    if (exception is TokenExpiredException || exception is SessionInvalidatedException) {
      return 'Sesjon utløpt';
    }
    if (exception is UnauthorizedException) {
      return 'Ingen tilgang';
    }
    if (exception is NotFoundException) {
      return 'Ikke funnet';
    }
    if (exception is ValidationException) {
      return 'Ugyldig data';
    }
    if (exception is ServerException || exception is ServiceUnavailableException) {
      return 'Serverfeil';
    }
    if (exception is RateLimitException) {
      return 'For mange forespørsler';
    }
    return 'Noe gikk galt';
  }
}
