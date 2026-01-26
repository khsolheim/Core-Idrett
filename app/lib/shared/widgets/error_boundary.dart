import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/services/connectivity_service.dart';

/// Widget that wraps content and shows offline state when disconnected
class ErrorBoundary extends ConsumerWidget {
  final Widget child;
  final Widget Function(AppException error, VoidCallback retry)? errorBuilder;
  final bool showOfflineBanner;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.showOfflineBanner = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStreamProvider);

    return connectivityAsync.when(
      data: (isConnected) {
        if (!isConnected && showOfflineBanner) {
          return Column(
            children: [
              _buildOfflineBanner(context),
              Expanded(child: child),
            ],
          );
        }
        return child;
      },
      loading: () => child,
      error: (e, st) => child,
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Ingen internettforbindelse',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen offline widget for use when network is required
class OfflineWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Ingen internettforbindelse',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sjekk tilkoblingen din og prøv igjen',
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
}

/// Consumer widget that requires network connectivity
class RequiresConnection extends ConsumerWidget {
  final Widget child;
  final Widget Function()? offlineBuilder;
  final VoidCallback? onRetry;

  const RequiresConnection({
    super.key,
    required this.child,
    this.offlineBuilder,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnectedAsync = ref.watch(connectivityStreamProvider);

    return isConnectedAsync.when(
      data: (isConnected) {
        if (!isConnected) {
          return offlineBuilder?.call() ?? OfflineWidget(onRetry: onRetry);
        }
        return child;
      },
      loading: () => child,
      error: (e, st) => child,
    );
  }
}
