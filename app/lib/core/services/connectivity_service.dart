import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Provider for streaming connectivity status
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onConnectivityChanged;
});

/// Provider for current connectivity status
final isConnectedProvider = FutureProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).isConnected;
});

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream of connectivity status changes
  /// Emits true when connected, false when disconnected
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_isConnected);
  }

  /// Check if currently connected to the network
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  /// Convert connectivity results to a boolean
  bool _isConnected(List<ConnectivityResult> results) {
    // No connectivity results means no connection
    if (results.isEmpty) return false;

    // Check if any result indicates a connection
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);
  }

  /// Get the current connection type as a string (for debugging)
  Future<String> get connectionType async {
    final results = await _connectivity.checkConnectivity();
    if (results.isEmpty) return 'none';

    return results
        .map((r) {
          switch (r) {
            case ConnectivityResult.wifi:
              return 'WiFi';
            case ConnectivityResult.mobile:
              return 'Mobildata';
            case ConnectivityResult.ethernet:
              return 'Ethernet';
            case ConnectivityResult.vpn:
              return 'VPN';
            case ConnectivityResult.bluetooth:
              return 'Bluetooth';
            case ConnectivityResult.other:
              return 'Annet';
            case ConnectivityResult.none:
              return 'Ingen';
          }
        })
        .join(', ');
  }
}
