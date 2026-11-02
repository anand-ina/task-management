import 'package:flutter/material.dart';
import '../../core/utils/app_toast.dart';

/// NoInternetDialog has been replaced with non-intrusive toast notifications.
/// All previous dialogs and force-logout behaviors are completely removed.
class NoInternetDialog extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetDialog({super.key, this.onRetry});

  static bool get isShowing => false;

  static void resetState() {}

  /// Displays an internet toast instead of showing any modal dialog.
  static void show(BuildContext context, {VoidCallback? onRetry}) {
    AppToast.showInternetToast(message: 'Internet not available');
  }

  /// Displays an internet toast instead of forceful logout or countdown dialog.
  static void showForceLogout(BuildContext context) {
    AppToast.showInternetToast(message: 'Internet not available');
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class ForceLogoutNoInternetDialog extends StatelessWidget {
  final BuildContext parentContext;

  const ForceLogoutNoInternetDialog({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
