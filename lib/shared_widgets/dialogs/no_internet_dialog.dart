import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization/app_strings.dart';
import '../../core/utils/network_connectivity_service.dart';
import '../../core/utils/preferences_service.dart';
import '../../modules/auth/bloc/auth_bloc.dart';
import '../../modules/auth/bloc/auth_event.dart';
import '../../modules/auth/screens/login_screen.dart';

class NoInternetDialog extends StatefulWidget {
  final VoidCallback onRetry;

  const NoInternetDialog({super.key, required this.onRetry});

  static bool _isShowing = false;
  static bool get isShowing => _isShowing;

  static void show(BuildContext context, {required VoidCallback onRetry}) {
    if (_isShowing) return;
    _isShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => NoInternetDialog(onRetry: onRetry),
    ).then((_) {
      _isShowing = false;
    });
  }

  static void showForceLogout(BuildContext context) {
    if (_isShowing) return;
    _isShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ForceLogoutNoInternetDialog(parentContext: context),
    ).then((_) {
      _isShowing = false;
    });
  }

  @override
  State<NoInternetDialog> createState() => _NoInternetDialogState();
}

class _NoInternetDialogState extends State<NoInternetDialog> {
  bool _isChecking = false;
  String? _statusMessage;

  Future<void> _handleRetry() async {
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    final isConnected = await NetworkConnectivityService().checkConnection();
    if (!mounted) return;

    if (isConnected) {
      Navigator.of(context).pop();
      widget.onRetry();
    } else {
      setState(() {
        _isChecking = false;
        _statusMessage = 'Still no internet connection. Please connect to Wi-Fi or mobile data and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded, color: Color(0xFFB91C1C), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.noInternetTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.noInternetMessage,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isChecking
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: Text(
            s.cancelButton,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB91C1C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isChecking ? null : _handleRetry,
          child: _isChecking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(s.retryButton),
        ),
      ],
    );
  }
}

class ForceLogoutNoInternetDialog extends StatefulWidget {
  final BuildContext parentContext;

  const ForceLogoutNoInternetDialog({super.key, required this.parentContext});

  @override
  State<ForceLogoutNoInternetDialog> createState() => _ForceLogoutNoInternetDialogState();
}

class _ForceLogoutNoInternetDialogState extends State<ForceLogoutNoInternetDialog> {
  int _secondsRemaining = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _performForceLogout();
      }
    });
  }

  void _performForceLogout() {
    final parentCtx = widget.parentContext;
    PreferencesService().clearSession();
    NoInternetDialog._isShowing = false;
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (parentCtx.mounted) {
      parentCtx.read<AuthBloc>().add(LogoutRequestedEvent());
      Navigator.of(parentCtx, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.signal_wifi_connected_no_internet_4_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.noInternetTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.forceLogoutNotice(_secondsRemaining)),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _secondsRemaining / 3.0,
            backgroundColor: Colors.red.shade100,
            color: Colors.red.shade700,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            _timer?.cancel();
            _performForceLogout();
          },
          child: Text(s.logout),
        ),
      ],
    );
  }
}
