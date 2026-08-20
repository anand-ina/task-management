import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization/app_strings.dart';
import '../../core/utils/preferences_service.dart';
import '../../modules/auth/bloc/auth_bloc.dart';
import '../../modules/auth/bloc/auth_event.dart';
import '../../modules/auth/screens/login_screen.dart';

class NoInternetDialog extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetDialog({super.key, required this.onRetry});

  static void show(BuildContext context, {required VoidCallback onRetry}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NoInternetDialog(onRetry: onRetry),
    );
  }

  static void showForceLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ForceLogoutNoInternetDialog(parentContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.noInternetTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(s.noInternetMessage),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB91C1C),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            onRetry();
          },
          child: Text(s.retryButton),
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
