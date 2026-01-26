import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/app_exceptions.dart';
import '../../shared/widgets/error_widget.dart';

/// Extension on AsyncValue for easier error handling with AppExceptions
extension AsyncValueUI<T> on AsyncValue<T> {
  /// Enhanced version of [when] that automatically maps errors to AppException
  /// and provides a retry callback
  Widget when2({
    required Widget Function(T data) data,
    Widget Function()? loading,
    Widget Function(AppException error, VoidCallback retry)? error,
    VoidCallback? onRetry,
  }) {
    return when(
      skipLoadingOnRefresh: false,
      data: data,
      loading: () =>
          loading?.call() ?? const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        final appError = _toAppException(e);
        final retry = onRetry ?? () {};

        if (error != null) {
          return error(appError, retry);
        }

        return AppErrorWidget(
          exception: appError,
          onRetry: onRetry != null ? retry : null,
        );
      },
    );
  }

  /// Build widget with custom builders, converting errors to AppException
  Widget build({
    required Widget Function(T data) data,
    Widget Function()? loading,
    Widget Function(AppException error)? error,
  }) {
    return when(
      skipLoadingOnRefresh: false,
      data: data,
      loading: () =>
          loading?.call() ?? const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        final appError = _toAppException(e);

        if (error != null) {
          return error(appError);
        }

        return AppErrorWidget(exception: appError);
      },
    );
  }

  /// Get the error as an AppException, or null if no error
  AppException? get appError {
    return whenOrNull(error: (e, _) => _toAppException(e));
  }

  /// Check if the error is of a specific type
  bool hasErrorOfType<E extends AppException>() {
    return whenOrNull(error: (e, _) => e is E) ?? false;
  }

  /// Check if this is a retriable error
  bool get isRetriableError {
    return whenOrNull(
          error: (e, _) {
            final appError = _toAppException(e);
            return appError is NetworkException ||
                appError is ServerException ||
                appError is ServiceUnavailableException ||
                appError is RateLimitException;
          },
        ) ??
        false;
  }

  /// Check if this error requires re-authentication
  bool get requiresReauth {
    return whenOrNull(
          error: (e, _) {
            final appError = _toAppException(e);
            return appError is TokenExpiredException ||
                appError is SessionInvalidatedException;
          },
        ) ??
        false;
  }

  /// Convert any error to AppException
  AppException _toAppException(Object error) {
    if (error is AppException) {
      return error;
    }
    return UnknownException(error.toString());
  }
}

/// Extension for handling multiple AsyncValues together
extension AsyncValueListExtension<T> on List<AsyncValue<T>> {
  /// Check if any AsyncValue is loading
  bool get isAnyLoading => any((v) => v.isLoading);

  /// Check if any AsyncValue has an error
  bool get hasAnyError => any((v) => v.hasError);

  /// Get the first error as AppException, if any
  AppException? get firstError {
    for (final value in this) {
      if (value.hasError) {
        final error = value.error;
        if (error is AppException) return error;
        return UnknownException(error.toString());
      }
    }
    return null;
  }
}
