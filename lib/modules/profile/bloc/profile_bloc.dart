import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository = ProfileRepository();

  ProfileBloc() : super(ProfileInitialState()) {
    on<LoadProfileEvent>(_onLoadProfile);
  }

  Future<void> _onLoadProfile(LoadProfileEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoadingState());
    try {
      final profile = await _repository.getMyProfile();
      emit(ProfileLoadedState(profile: profile));
    } catch (e) {
      emit(ProfileErrorState(message: e.toString()));
    }
  }
}
