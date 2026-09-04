import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/network_connectivity_service.dart';
import '../../../shared_widgets/dialogs/no_internet_dialog.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../repository/auth_repository.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../staff/screens/staff_screen.dart';

enum AuthFormMode {
  signIn,
  forgotPassword,
  forgotPasswordSent,
  resetPassword,
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _forgotIdentifierController = TextEditingController();
  final TextEditingController _resetCodeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  AuthFormMode _currentFormMode = AuthFormMode.signIn;
  bool _isPasswordVisible = false;
  bool _showFeaturesOnMobile = false;
  bool _isLoadingForgot = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotIdentifierController.dispose();
    _resetCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final isConnected = await NetworkConnectivityService().checkConnection();
    if (!mounted) return;
    if (!isConnected) {
      NoInternetDialog.show(context, onRetry: () {
        NetworkConnectivityService().checkConnection();
      });
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isNotEmpty && password.isNotEmpty) {
      context.read<AuthBloc>().add(
            LoginRequestedEvent(email: email, password: password),
          );
    }
  }

  Future<void> _onSendResetCode() async {
    final isConnected = await NetworkConnectivityService().checkConnection();
    if (!mounted) return;
    if (!isConnected) {
      NoInternetDialog.show(context, onRetry: () {
        NetworkConnectivityService().checkConnection();
      });
      return;
    }

    final identifier = _forgotIdentifierController.text.trim();
    if (identifier.isEmpty) return;

    setState(() {
      _isLoadingForgot = true;
    });

    try {
      await AuthRepository().forgotPassword(identifier);
      if (!mounted) return;
      setState(() {
        _isLoadingForgot = false;
        _currentFormMode = AuthFormMode.forgotPasswordSent;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingForgot = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onResetPasswordSubmitted() async {
    final isConnected = await NetworkConnectivityService().checkConnection();
    if (!mounted) return;
    if (!isConnected) {
      NoInternetDialog.show(context, onRetry: () {
        NetworkConnectivityService().checkConnection();
      });
      return;
    }

    final identifier = _forgotIdentifierController.text.trim();
    final code = _resetCodeController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (identifier.isEmpty || code.isEmpty || newPass.isEmpty) return;

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingForgot = true;
    });

    try {
      final res = await AuthRepository().resetPassword(
        identifier: identifier,
        code: code,
        newPassword: newPass,
      );
      if (!mounted) return;
      setState(() {
        _isLoadingForgot = false;
        _currentFormMode = AuthFormMode.signIn;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] as String? ?? 'Password reset successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingForgot = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
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
          final isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return _buildMobileLayout(context, s, isDark);
          } else {
            return _buildDesktopLayout(context, s, isDark);
          }
        },
      ),
    );
  }

  // Desktop Split Layout (50/50 side by side)
  Widget _buildDesktopLayout(BuildContext context, AppStrings s, bool isDark) {
    return Row(
      children: [
        // Left Dark Navy Panel
        Expanded(
          flex: 5,
          child: Container(
            color: const Color(0xFF0B132B),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Logo & Title
                    Row(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/circle-logo.png',
                            height: 32,
                            width: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.school, color: Colors.white, size: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          s.appTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Main Emblem & eduCore Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/circle-logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.school, color: AppColors.primaryRed, size: 48),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'eduCore',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Task Management System · Samskar, The Life School',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 4 Feature Cards
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildFeatureCard(
                              'Smart Task Lifecycle',
                              'Assign, acknowledge, progress & close with a full accountability chain',
                            ),
                            const SizedBox(height: 14),
                            _buildFeatureCard(
                              'Role-Based Dashboards',
                              'Executive → Team Lead → Manager → Principal → Director, each scoped',
                            ),
                            const SizedBox(height: 14),
                            _buildFeatureCard(
                              'DSR · WSR · MSR',
                              'Daily, weekly & monthly status reports with pull-from-tasks & lock',
                            ),
                            const SizedBox(height: 14),
                            _buildFeatureCard(
                              'Performance & Rewards',
                              'Leaderboards, fines & rewards to drive accountability',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Footer
                    const Text(
                      'Powered by Srivyn Platforms',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right Form Panel
        Expanded(
          flex: 6,
          child: Container(
            color: isDark ? const Color(0xFF090D16) : const Color(0xFFF3F5F8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: _buildFormContent(context, s, isDark),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile Comfortable Layout (Single Scrollable Column)
  Widget _buildMobileLayout(BuildContext context, AppStrings s, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF090D16) : const Color(0xFFF3F5F8),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mobile Header Banner Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/circle-logo.png',
                            height: 28,
                            width: 28,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.school, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          s.appTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/circle-logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.school, color: AppColors.primaryRed, size: 32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'eduCore',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Task Management System · Samskar',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Toggle Button to expand features on mobile
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showFeaturesOnMobile = !_showFeaturesOnMobile;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _showFeaturesOnMobile ? 'Hide Key Features' : 'View Key Features',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              _showFeaturesOnMobile
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showFeaturesOnMobile) ...[
                      const SizedBox(height: 14),
                      _buildFeatureCard(
                        'Smart Task Lifecycle',
                        'Assign, acknowledge, progress & close with accountability',
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureCard(
                        'Role-Based Dashboards',
                        'Executive → Team Lead → Manager → Principal → Director',
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureCard(
                        'DSR · WSR · MSR',
                        'Daily, weekly & monthly status reports with pull-from-tasks',
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureCard(
                        'Performance & Rewards',
                        'Leaderboards, fines & rewards to drive accountability',
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Mobile Form Container Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: _buildFormContent(context, s, isDark),
              ),

              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Powered by Srivyn Platforms',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Feature Card Widget
  Widget _buildFeatureCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
              color: Color(0xFF94A3B8),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // Main Form Content Router
  Widget _buildFormContent(BuildContext context, AppStrings s, bool isDark) {
    switch (_currentFormMode) {
      case AuthFormMode.forgotPassword:
        return _buildForgotPasswordStep1(context, s, isDark);
      case AuthFormMode.forgotPasswordSent:
        return _buildForgotPasswordStep2(context, s, isDark);
      case AuthFormMode.resetPassword:
        return _buildResetPasswordStep3(context, s, isDark);
      case AuthFormMode.signIn:
        return _buildLoginForm(context, s, isDark);
    }
  }

  // Login Form Widget (Exact match to media_1788500370709.png)
  Widget _buildLoginForm(BuildContext context, AppStrings s, bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final labelColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF374151);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title: Welcome back
        Text(
          s.welcomeBack,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: titleColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),

        // Subtitle: Sign in to your account.
        Text(
          s.signInToAccount,
          style: TextStyle(
            fontSize: 16,
            color: subtitleColor,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 28),

        // Field 1: Email, phone or username
        Text(
          s.emailPhoneOrUsernameLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 14.5,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'you@school.edu · 98xxxxxxxx · username',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF991B1B),
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
        ),

        const SizedBox(height: 20),

        // Field 2: Password
        Text(
          s.passwordLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 14.5,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF991B1B),
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Right Aligned Link: Forgot password?
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () {
              setState(() {
                _forgotIdentifierController.text = _emailController.text;
                _currentFormMode = AuthFormMode.forgotPassword;
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Crimson Sign In Button
        BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthenticatedState) {
              final user = state.userProfile;
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
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF991B1B), // Dark Crimson Red
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : _submitLogin,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        s.signInButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Step 1: Forgot Password (Exact match to media_1788502722027.png)
  Widget _buildForgotPasswordStep1(BuildContext context, AppStrings s, bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final labelColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF374151);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.forgotPasswordTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: titleColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.forgotPasswordSubtitle,
          style: TextStyle(
            fontSize: 14,
            color: subtitleColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          s.emailPhoneOrUsernameLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _forgotIdentifierController,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 14.5,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFF2563EB),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF1D4ED8),
                width: 2.0,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF132A50), // Navy Blue
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isLoadingForgot ? null : _onSendResetCode,
            child: _isLoadingForgot
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    s.sendResetCodeButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        Center(
          child: InkWell(
            onTap: () {
              setState(() {
                _currentFormMode = AuthFormMode.signIn;
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Text(
                s.backToSignInLink,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Step 2: Confirmation Notice State (Exact match to media_1788502812684.png)
  Widget _buildForgotPasswordStep2(BuildContext context, AppStrings s, bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.forgotPasswordTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: titleColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.forgotPasswordSubtitle,
          style: TextStyle(
            fontSize: 14,
            color: subtitleColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Success Green Dashed Banner Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF10B981) : const Color(0xFF81C784),
              width: 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✓ ',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: Text(
                  s.resetCodeSentNotice,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF2E7D32),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF132A50), // Navy Blue
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() {
                _currentFormMode = AuthFormMode.resetPassword;
              });
            },
            child: Text(
              s.enterResetCodeButton,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        Center(
          child: InkWell(
            onTap: () {
              setState(() {
                _currentFormMode = AuthFormMode.signIn;
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Text(
                s.backToSignInLink,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Step 3: Reset Password View (Exact match to media_1788502934364.png)
  Widget _buildResetPasswordStep3(BuildContext context, AppStrings s, bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final labelColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF374151);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.resetPasswordTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: titleColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.resetPasswordSubtitle,
          style: TextStyle(
            fontSize: 14,
            color: subtitleColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Field 1: Email, phone or username
        Text(
          s.emailPhoneOrUsernameLabel,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _forgotIdentifierController,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF132A50),
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
        ),

        const SizedBox(height: 16),

        // Field 2: Reset Code
        Text(
          s.resetCodeLabel,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _resetCodeController,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: s.resetCodeHint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              fontSize: 13.5,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFF2563EB),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF1D4ED8),
                width: 2.0,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
        ),

        const SizedBox(height: 16),

        // Field 3: New Password
        Text(
          s.newPasswordLabel,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _newPasswordController,
          obscureText: true,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: s.newPasswordHint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              fontSize: 13.5,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF132A50),
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
        ),

        const SizedBox(height: 16),

        // Field 4: Confirm New Password
        Text(
          s.confirmNewPasswordLabel,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF132A50),
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF132A50), // Navy Blue
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isLoadingForgot ? null : _onResetPasswordSubmitted,
            child: _isLoadingForgot
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    s.resetPasswordButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 18),

        Center(
          child: InkWell(
            onTap: () {
              setState(() {
                _currentFormMode = AuthFormMode.signIn;
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Text(
                s.backToSignInLink,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
