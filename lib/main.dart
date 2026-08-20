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
import 'modules/settings/bloc/language_cubit.dart';
import 'shared_widgets/dialogs/no_internet_dialog.dart';

import 'modules/auth/screens/splash_screen.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

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

      _networkSubscription = NetworkConnectivityService().onConnectionChanged.listen((isConnected) {
        if (!isConnected && mounted) {
          final currentContext = AppNavigator.navigatorKey.currentContext;
          if (currentContext != null && currentContext.mounted) {
            final authState = currentContext.read<AuthBloc>().state;
            if (authState is AuthenticatedState) {
              // User is logged in: show 3-second countdown force-logout dialog
              NoInternetDialog.showForceLogout(currentContext);
            } else {
              // User is not logged in: show standard retry dialog
              NoInternetDialog.show(currentContext, onRetry: () {
                NetworkConnectivityService().checkConnection();
              });
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
