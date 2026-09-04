import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'login_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../staff/screens/staff_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    // Give splash screen a smooth 1.5 second display before navigation
    _timer = Timer(const Duration(milliseconds: 1500), () {
      _navigateNext();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateNext() {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthenticatedState) {
      final user = authState.userProfile;
      final roleLower = user.role.toLowerCase();
      final roleLabelLower = user.roleLabel.toLowerCase();
      if (roleLower.contains('admin') ||
          roleLabelLower.contains('admin') ||
          user.email.contains('admin')) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StaffScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } else if (authState is UnauthenticatedState || authState is AuthErrorState) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_timer != null && !_timer!.isActive) {
          _navigateNext();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // App Logo
                ClipOval(
                  child: Image.asset(
                    'assets/images/circle-logo.png',
                    width: 200,
                     height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFB91C1C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.task_alt, color: Colors.white, size: 50),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // const CircularProgressIndicator(
                //   color: Color(0xFFB91C1C),
                //   strokeWidth: 2.5,
                // ),
                const Spacer(),

                // Samskar Crest Icon & Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/circle-logo.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.school, size: 24, color: Color(0xFFB91C1C));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Samskar, The Life School',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
