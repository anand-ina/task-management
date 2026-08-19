import 'package:equatable/equatable.dart';
import '../models/user_profile.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthenticatedState extends AuthState {
  final UserProfile userProfile;
  final String token;

  const AuthenticatedState({required this.userProfile, required this.token});

  @override
  List<Object?> get props => [userProfile, token];
}

class UnauthenticatedState extends AuthState {}

class AuthErrorState extends AuthState {
  final String message;

  const AuthErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}
