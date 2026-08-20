import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/fines_repository.dart';
import 'fines_event.dart';
import 'fines_state.dart';

class FinesBloc extends Bloc<FinesEvent, FinesState> {
  final FinesRepository repository;

  FinesBloc({FinesRepository? finesRepository})
      : repository = finesRepository ?? FinesRepository(),
        super(FinesInitialState()) {
    on<FetchFinesEvent>(_onFetchFines);
    on<FetchFineTypesEvent>(_onFetchFineTypes);
  }

  Future<void> _onFetchFines(
    FetchFinesEvent event,
    Emitter<FinesState> emit,
  ) async {
    emit(FinesLoadingState());
    try {
      final data = await repository.getFinesOverviewData();
      emit(FinesLoadedState(data));
    } catch (e) {
      emit(FinesErrorState(e.toString()));
    }
  }

  Future<void> _onFetchFineTypes(
    FetchFineTypesEvent event,
    Emitter<FinesState> emit,
  ) async {
    emit(FinesLoadingState());
    try {
      final fineTypes = await repository.getFineTypes();
      emit(FineTypesLoadedState(fineTypes));
    } catch (e) {
      emit(FinesErrorState(e.toString()));
    }
  }
}
