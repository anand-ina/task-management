import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization/app_strings.dart';
import '../../core/utils/app_navigator.dart';
import '../../core/utils/network_connectivity_service.dart';
import '../../core/utils/preferences_service.dart';
import '../../modules/auth/bloc/auth_bloc.dart';
import '../../modules/auth/bloc/auth_event.dart';
import '../../modules/auth/screens/login_screen.dart';

class NoInternetDialog extends StatefulWidget {
  final VoidCallback? onRetry;

  const NoInternetDialog({super.key, this.onRetry});

  static bool _isShowing = false;
  static bool _isForceLogoutShowing = false;
  static BuildContext? _activeStandardDialogContext;

  static bool get isShowing => _isShowing || _isForceLogoutShowing;

  static void resetState() {
    _isShowing = false;
    _isForceLogoutShowing = false;
    _activeStandardDialogContext = null;
  }

  static void show(BuildContext context, {VoidCallback? onRetry}) {
    debugPrint('[NoInternetDialog] show() called');
    // If standard dialog is already visible, do not stack duplicate
    if (_activeStandardDialogContext != null && _activeStandardDialogContext!.mounted) {
      debugPrint('[NoInternetDialog] Already showing standard dialog');
      return;
    }

    final targetContext = AppNavigator.navigatorKey.currentContext ?? context;
    showDialog(
      context: targetContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) {
        _activeStandardDialogContext = dialogContext;
        return NoInternetDialog(onRetry: onRetry);
      },
    ).whenComplete(() {
      _activeStandardDialogContext = null;
    });
  }

  static void showForceLogout(BuildContext context) {
    if (_isForceLogoutShowing) return;

    // If standard no-internet dialog is currently showing, dismiss it first
    if (_isShowing && _activeStandardDialogContext != null && _activeStandardDialogContext!.mounted) {
      Navigator.of(_activeStandardDialogContext!).pop();
      _isShowing = false;
      _activeStandardDialogContext = null;
    }

    _isForceLogoutShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ForceLogoutNoInternetDialog(parentContext: context),
    ).whenComplete(() {
      _isForceLogoutShowing = false;
    });
  }

  @override
  State<NoInternetDialog> createState() => _NoInternetDialogState();
}

class _NoInternetDialogState extends State<NoInternetDialog> {
  bool _isConnected = false;
  String? _statusMessage;
  StreamSubscription<bool>? _networkSubscription;

  @override
  void initState() {
    super.initState();
    _startListeningForConnection();
  }

  void _startListeningForConnection() {
    _networkSubscription = NetworkConnectivityService().onConnectionChanged.listen((connected) {
      if (!mounted) return;
      setState(() {
        _isConnected = connected;
        if (connected) {
          _statusMessage = 'Internet connection detected.';
        } else {
          _statusMessage = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: _isConnected ? Colors.green.shade700 : const Color(0xFFB91C1C),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isConnected ? 'Internet Restored' : s.noInternetTitle,
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
              _isConnected
                  ? 'Your device is back online. Tap "OK" to continue.'
                  : s.noInternetMessage,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 14),

            // Dynamic Real-time Status Indicator Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isConnected
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isConnected
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green : Colors.amber.shade700,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isConnected
                          ? 'Connected to internet'
                          : 'Listening for network changes...',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _isConnected
                            ? Colors.green.shade800
                            : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _statusMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: _isConnected ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
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
  int _secondsRemaining = 5;
  Timer? _timer;
  StreamSubscription<bool>? _connectivitySub;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _listenForReconnection();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _secondsRemaining = 0;
        });
        _timer?.cancel();
        _performForceLogout();
      }
    });
  }

  void _listenForReconnection() {
    _connectivitySub = NetworkConnectivityService().onConnectionChanged.listen((isConnected) {
      if (isConnected && mounted && !_isLoggingOut) {
        _timer?.cancel();
        _connectivitySub?.cancel();
        NoInternetDialog._isForceLogoutShowing = false;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        final rootContext = AppNavigator.navigatorKey.currentContext;
        if (rootContext != null && rootContext.mounted) {
          ScaffoldMessenger.of(rootContext).showSnackBar(
            const SnackBar(
              content: Text('Internet connection restored.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _performForceLogout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    _timer?.cancel();
    _connectivitySub?.cancel();
    await PreferencesService().clearSession();
    NoInternetDialog.resetState();

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    final rootContext = AppNavigator.navigatorKey.currentContext ?? widget.parentContext;
    if (rootContext.mounted) {
      try {
        rootContext.read<AuthBloc>().add(LogoutRequestedEvent());
      } catch (_) {}
    }

    AppNavigator.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.signal_wifi_connected_no_internet_4_rounded, color: Colors.red, size: 24),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              s.forceLogoutNotice(_secondsRemaining),
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Large Animated Countdown Timer Badge
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade400, width: 2.5),
              ),
              child: Center(
                child: Text(
                  '$_secondsRemaining',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: _secondsRemaining <= 2 ? Colors.red.shade700 : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Linear Progress Bar synchronized with 5s
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _secondsRemaining / 5.0,
                minHeight: 6,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.red.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _secondsRemaining <= 2 ? Colors.red.shade700 : const Color(0xFFB91C1C),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              _timer?.cancel();
              _performForceLogout();
            },
            child: Text(s.logout),
          ),
        ],
      ),
    );
  }
}
