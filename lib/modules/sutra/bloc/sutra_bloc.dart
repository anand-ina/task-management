import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/sutra_repository.dart';
import 'sutra_event.dart';
import 'sutra_state.dart';

class SutraBloc extends Bloc<SutraEvent, SutraState> {
  final SutraRepository _repository = SutraRepository();

  SutraBloc() : super(SutraInitialState()) {
    on<LoadSutraDataEvent>(_onLoadSutraData);
  }

  Future<void> _onLoadSutraData(LoadSutraDataEvent event, Emitter<SutraState> emit) async {
    emit(SutraLoadingState());
    try {
      final data = await _repository.getSutraData();
      emit(SutraLoadedState(data: data));
    } catch (e) {
      emit(SutraErrorState(message: e.toString()));
    }
  }
}
