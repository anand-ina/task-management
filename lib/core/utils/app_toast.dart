import 'package:flutter/material.dart';
import 'app_navigator.dart';

class AppToast {
  static DateTime? _lastToastTime;
  static String? _lastToastMessage;

  /// Shows an internet status toast.
  /// Deduplicates and throttles rapid calls within 3 seconds.
  static void showInternetToast({
    String? message,
    bool isConnected = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final msg = message ??
        (isConnected
            ? 'Internet connection restored.'
            : 'Internet not available');

    final now = DateTime.now();
    if (_lastToastTime != null &&
        _lastToastMessage == msg &&
        now.difference(_lastToastTime!) < const Duration(seconds: 3)) {
      return;
    }
    _lastToastTime = now;
    _lastToastMessage = msg;

    final messenger = AppNavigator.scaffoldMessengerKey.currentState;
    if (messenger == null) {
      final context = AppNavigator.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        try {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar(msg, isConnected, duration),
          );
        } catch (_) {}
      }
      return;
    }

    try {
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        _buildSnackBar(msg, isConnected, duration),
      );
    } catch (_) {}
  }

  static SnackBar _buildSnackBar(String msg, bool isConnected, Duration duration) {
    return SnackBar(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isConnected ? const Color(0xFF15803D) : const Color(0xFFDC2626),
      behavior: SnackBarBehavior.floating,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
