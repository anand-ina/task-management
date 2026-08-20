import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/network_connectivity_service.dart';
import '../../../shared_widgets/dialogs/no_internet_dialog.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController =
      TextEditingController(text: 'vamsi@samskar.edu');
  final TextEditingController _passwordController =
      TextEditingController(text: 'Samskar@123');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onQuickLogin(String email) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = 'Samskar@123';
    });
    _submitLogin();
  }

  Future<void> _submitLogin() async {
    final isConnected = await NetworkConnectivityService().checkConnection();
    if (!mounted) return;
    if (!isConnected) {
      NoInternetDialog.show(context, onRetry: () {
        NetworkConnectivityService().checkConnection();
      });
      return; // Do not call API if internet is not connected
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isNotEmpty && password.isNotEmpty) {
      context.read<AuthBloc>().add(
            LoginRequestedEvent(email: email, password: password),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          if (isDesktop) {
            return Row(
              children: [
                // Left Brand Banner
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Row(
                            children: [
                              Container(
                                width: 250,
                                height: 100,
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/circle-logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                s.appTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'eduCore',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const Text(
                          'Task Management System · Samskar, The Life School',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Features List
                        _buildFeatureCard(
                          'Smart Task Lifecycle',
                          'Assign, acknowledge, progress & close with a full accountability chain',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          'Role-Based Dashboards',
                          'Executive → Team Lead → Manager → Principal → Director, each scoped',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          'DSR · WSR · MSR',
                          'Daily, weekly & monthly status reports with pull-from-tasks & lock',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          'Performance & Rewards',
                          'Leaderboards, fines & rewards to drive accountability',
                        ),

                        const SizedBox(height: 40),
                        const Text(
                          'Powered by Navacle · Srivyn Platforms',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Sign In Panel
                Expanded(
                  flex: 6,
                  child: Container(
                    color: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
                    child: Center(
                      child: SingleChildScrollView(
                        child: SizedBox(
                          width: 520,
                          child: _buildLoginForm(context, s, isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile / Tablet Layout
            return Container(
              color: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildLoginForm(context, s, isDark),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildFeatureCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, AppStrings s, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Logo Image at First
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                height: 54,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/circle-logo.png',
                    height: 54,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ),
        ),
        Text(
          s.welcomeBack,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.signInToAccount,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),

        // QUICK LOGIN AS Section (Maintained in 2 clean rows)
        Text(
          s.quickLoginAs,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        const SizedBox(height: 10),

        // Row 1
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickChip(s.directorVamsi, 'vamsi@samskar.edu', isHighlighted: true),
              const SizedBox(width: 8),
              _buildQuickChip(s.principalMadhumathi, 'madhumathi@samskar.edu'),
              const SizedBox(width: 8),
              _buildQuickChip(s.managerMurali, 'murali@samskar.edu'),
              const SizedBox(width: 8),
              _buildQuickChip(s.managerSwapnika, 'swapnika@samskar.edu'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Row 2
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickChip(s.teamLeadNarasimha, 'narasimha@samskar.edu'),
              const SizedBox(width: 8),
              _buildQuickChip(s.executiveAnamika, 'anamika@samskar.edu'),
              const SizedBox(width: 8),
              // _buildQuickChip(s.executiveGyapika, 'gyapika@samskar.edu'),
              _buildQuickChip(s.executiveGyapika, 'sushma@samskar.edu '),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                s.credentials,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
            Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
          ],
        ),
        const SizedBox(height: 20),

        // Email Field
        Text(
          s.emailLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
        ),

        const SizedBox(height: 16),

        // Password Field
        Text(
          s.passwordLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
        ),

        const SizedBox(height: 24),

        // Sign In Button
        BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthenticatedState) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            }
            if (state is AuthErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoadingState;

            return SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isLoading ? null : _submitLogin,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        s.signInButton,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Demo password hint
        Center(
          child: Text(
            s.demoPasswordHint,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, String email, {bool isHighlighted = false}) {
    final isSelected = _emailController.text == email;

    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF334155),
        ),
      ),
      backgroundColor: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0F172A) : Colors.black12,
        ),
      ),
      onPressed: () => _onQuickLogin(email),
    );
  }
}
