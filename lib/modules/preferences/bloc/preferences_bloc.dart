import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/preferences_repository.dart';
import 'preferences_event.dart';
import 'preferences_state.dart';

class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  final PreferencesRepository _repository = PreferencesRepository();

  PreferencesBloc() : super(PreferencesInitialState()) {
    on<LoadPreferencesEvent>(_onLoadPreferences);
    on<ToggleDailyDigestEvent>(_onToggleDailyDigest);
    on<ToggleChannelEvent>(_onToggleChannel);
  }

  Future<void> _onLoadPreferences(LoadPreferencesEvent event, Emitter<PreferencesState> emit) async {
    emit(PreferencesLoadingState());
    try {
      final data = await _repository.getPreferencesData();
      emit(PreferencesLoadedState(data: data));
    } catch (e) {
      emit(PreferencesErrorState(message: e.toString()));
    }
  }

  void _onToggleDailyDigest(ToggleDailyDigestEvent event, Emitter<PreferencesState> emit) {
    if (state is PreferencesLoadedState) {
      final currentData = (state as PreferencesLoadedState).data;
      currentData.preferences.dailyDigest = event.value;
      emit(PreferencesLoadedState(data: currentData));
    }
  }

  void _onToggleChannel(ToggleChannelEvent event, Emitter<PreferencesState> emit) {
    if (state is PreferencesLoadedState) {
      final currentData = (state as PreferencesLoadedState).data;
      final ch = currentData.preferences.channels[event.notificationType];
      if (ch != null) {
        if (event.channel == 'inapp') ch.inapp = event.value;
        if (event.channel == 'email') ch.email = event.value;
        if (event.channel == 'sms') ch.sms = event.value;
        if (event.channel == 'whatsapp') ch.whatsapp = event.value;
        if (event.channel == 'push') ch.push = event.value;
      }
      emit(PreferencesLoadedState(data: currentData));
    }
  }
}
