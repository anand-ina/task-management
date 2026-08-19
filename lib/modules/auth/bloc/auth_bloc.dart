import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/preferences_service.dart';
import '../repository/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository = AuthRepository();
  final PreferencesService _prefs = PreferencesService();

  AuthBloc() : super(AuthInitialState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginRequestedEvent>(_onLoginRequested);
    on<LogoutRequestedEvent>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    // Force session clear on app restart/refresh as requested
    await _prefs.clearSession();
    emit(UnauthenticatedState());
  }

  Future<void> _onLoginRequested(LoginRequestedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final loginRes = await _authRepository.login(event.email, event.password);
      final userProfile = await _authRepository.getMe();
      emit(AuthenticatedState(userProfile: userProfile, token: loginRes.token));
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequestedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    await _authRepository.logout();
    emit(UnauthenticatedState());
  }
}
