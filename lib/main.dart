import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/utils/network_connectivity_service.dart';
import 'modules/auth/bloc/auth_bloc.dart';
import 'modules/auth/bloc/auth_event.dart';
import 'modules/auth/bloc/auth_state.dart';
import 'modules/auth/screens/login_screen.dart';

import 'modules/dashboard/bloc/dashboard_bloc.dart';
import 'modules/approvals/bloc/approvals_bloc.dart';
import 'modules/complaints/bloc/complaints_bloc.dart';
import 'modules/announcements/bloc/announcements_bloc.dart';
import 'modules/hourly_log/bloc/hourly_log_bloc.dart';
import 'modules/hourly_log/repository/hourly_log_repository.dart';
import 'modules/hourly_log/widgets/hourly_log_prompt_overlay.dart';
import 'modules/settings/bloc/language_cubit.dart';
import 'shared_widgets/dialogs/no_internet_dialog.dart';
import 'shared_widgets/radial_menu/draggable_radial_menu_overlay.dart';

import 'core/utils/app_navigator.dart';
import 'core/utils/preferences_service.dart';
import 'modules/auth/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<bool>? _networkSubscription;

  @override
  void initState() {
    super.initState();
    // Post-frame callback ensures isolate is fully prepared before binding platform listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NetworkConnectivityService().initialize();

      _networkSubscription = NetworkConnectivityService().onConnectionChanged.listen((isConnected) async {
        if (!isConnected && mounted) {
          final token = await PreferencesService().getToken();
          if (!mounted) return;
          final currentContext = AppNavigator.navigatorKey.currentContext;
          if (currentContext != null && currentContext.mounted) {
            final authState = currentContext.read<AuthBloc>().state;
            final isAuthenticated = authState is AuthenticatedState || (token != null && token.isNotEmpty);
            if (isAuthenticated) {
              // User is logged in inside the app: show 5-second countdown force-logout dialog
              NoInternetDialog.showForceLogout(currentContext);
            }
          }
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (context) => ThemeCubit()),
        BlocProvider<LanguageCubit>(create: (context) => LanguageCubit()),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(CheckAuthStatusEvent()),
        ),
        BlocProvider<DashboardBloc>(create: (context) => DashboardBloc()),
        BlocProvider<ApprovalsBloc>(create: (context) => ApprovalsBloc()),
        BlocProvider<ComplaintsBloc>(create: (context) => ComplaintsBloc()),
        BlocProvider<AnnouncementsBloc>(create: (context) => AnnouncementsBloc()),
        BlocProvider<HourlyLogBloc>(
          create: (context) => HourlyLogBloc(HourlyLogRepository()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LanguageCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp(
                navigatorKey: AppNavigator.navigatorKey,
                title: 'Samskar Task Manager',
                debugShowCheckedModeBanner: false,
                themeMode: themeMode,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                locale: locale,
                supportedLocales: const [
                  Locale('en'),
                  Locale('te'),
                  Locale('hi'),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                navigatorObservers: [
                  ModalCheckObserver.instance,
                ],
                builder: (context, child) {
                  return DraggableRadialMenuOverlay(
                    child: HourlyLogPromptOverlay(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                },
                onGenerateRoute: (settings) => null,
                home: BlocListener<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is UnauthenticatedState) {
                      AppNavigator.navigatorKey.currentState?.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const SplashScreen(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
