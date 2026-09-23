import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/fine_type_model.dart';
import '../repository/fines_repository.dart';
import 'fines_event.dart';
import 'fines_state.dart';

class FinesBloc extends Bloc<FinesEvent, FinesState> {
  final FinesRepository repository;
  List<FineTypeModel> _cachedFineTypes = [];

  FinesBloc({FinesRepository? finesRepository})
      : repository = finesRepository ?? FinesRepository(),
        super(FinesInitialState()) {
    on<FetchFinesEvent>(_onFetchFines);
    on<FetchFineTypesEvent>(_onFetchFineTypes);
    on<AddFineTypeEvent>(_onAddFineType);
    on<DeleteFineTypeEvent>(_onDeleteFineType);
    on<UpdateFineTypesEvent>(_onUpdateFineTypes);
  }

  Future<void> _onFetchFines(
    FetchFinesEvent event,
    Emitter<FinesState> emit,
  ) async {
    emit(FinesLoadingState());
    try {
      final data = await repository.getFinesOverviewData();
      _cachedFineTypes = data.fineTypes;
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
      _cachedFineTypes = fineTypes;
      emit(FineTypesLoadedState(fineTypes));
    } catch (e) {
      emit(FinesErrorState(e.toString()));
    }
  }

  Future<void> _onAddFineType(
    AddFineTypeEvent event,
    Emitter<FinesState> emit,
  ) async {
    emit(FineTypesSavingState(_cachedFineTypes));
    try {
      await repository.addFineType(
        kind: event.kind,
        label: event.label,
        amount: event.amount,
      );
      final refreshed = await repository.getFineTypes();
      _cachedFineTypes = refreshed;
      emit(FineTypesActionSuccessState('added', refreshed));
    } catch (e) {
      emit(FineTypesActionErrorState(e.toString(), _cachedFineTypes));
    }
  }

  Future<void> _onDeleteFineType(
    DeleteFineTypeEvent event,
    Emitter<FinesState> emit,
  ) async {
    emit(FineTypesSavingState(_cachedFineTypes));
    try {
      await repository.deleteFineType(event.id);
      final refreshed = await repository.getFineTypes();
      _cachedFineTypes = refreshed;
      emit(FineTypesActionSuccessState('deleted', refreshed));
    } catch (e) {
      emit(FineTypesActionErrorState(e.toString(), _cachedFineTypes));
    }
  }

  Future<void> _onUpdateFineTypes(
    UpdateFineTypesEvent event,
    Emitter<FinesState> emit,
  ) async {
    emit(FineTypesSavingState(_cachedFineTypes));
    try {
      final updated = await repository.updateFineTypes(event.types);
      _cachedFineTypes = updated;
      emit(FineTypesActionSuccessState('saved', updated));
    } catch (e) {
      emit(FineTypesActionErrorState(e.toString(), _cachedFineTypes));
    }
  }
}
