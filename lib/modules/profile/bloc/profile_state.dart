import '../models/my_profile_model.dart';

abstract class ProfileState {}

class ProfileInitialState extends ProfileState {}

class ProfileLoadingState extends ProfileState {}

class ProfileLoadedState extends ProfileState {
  final MyProfileModel profile;
  ProfileLoadedState({required this.profile});
}

class ProfileErrorState extends ProfileState {
  final String message;
  ProfileErrorState({required this.message});
}
