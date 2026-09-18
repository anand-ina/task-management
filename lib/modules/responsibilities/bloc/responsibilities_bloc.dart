import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/responsibility_model.dart';
import '../repository/responsibilities_repository.dart';
import 'responsibilities_event.dart';
import 'responsibilities_state.dart';

class ResponsibilitiesBloc extends Bloc<ResponsibilitiesEvent, ResponsibilitiesState> {
  final ResponsibilitiesRepository _repository = ResponsibilitiesRepository();

  ResponsibilitiesBloc() : super(ResponsibilitiesInitialState()) {
    on<FetchResponsibilitiesEvent>(_onFetch);
    on<AddResponsibilityEvent>(_onAdd);
    on<DeleteResponsibilityEvent>(_onDelete);
  }

  Future<void> _onFetch(FetchResponsibilitiesEvent event, Emitter<ResponsibilitiesState> emit) async {
    emit(ResponsibilitiesLoadingState());
    try {
      final data = await _repository.getResponsibilities();
      emit(ResponsibilitiesLoadedState(data));
    } catch (e) {
      emit(ResponsibilitiesErrorState(e.toString()));
    }
  }

  void _onAdd(AddResponsibilityEvent event, Emitter<ResponsibilitiesState> emit) {
    if (state is! ResponsibilitiesLoadedState) return;
    final s = state as ResponsibilitiesLoadedState;
    final newItem = ResponsibilityItemModel(
      id: DateTime.now().millisecondsSinceEpoch,
      kind: event.kind,
      text: event.text,
      sort: 0,
    );

    if (event.kind == 'primary') {
      final updatedPrimary = List<ResponsibilityItemModel>.from(s.data.primary)..add(newItem);
      emit(ResponsibilitiesLoadedState(s.data.copyWith(primary: updatedPrimary)));
    } else {
      final updatedSecondary = List<ResponsibilityItemModel>.from(s.data.secondary)..add(newItem);
      emit(ResponsibilitiesLoadedState(s.data.copyWith(secondary: updatedSecondary)));
    }
  }

  void _onDelete(DeleteResponsibilityEvent event, Emitter<ResponsibilitiesState> emit) {
    if (state is! ResponsibilitiesLoadedState) return;
    final s = state as ResponsibilitiesLoadedState;

    if (event.kind == 'primary') {
      final updatedPrimary = s.data.primary.where((item) => item.id != event.id).toList();
      emit(ResponsibilitiesLoadedState(s.data.copyWith(primary: updatedPrimary)));
    } else {
      final updatedSecondary = s.data.secondary.where((item) => item.id != event.id).toList();
      emit(ResponsibilitiesLoadedState(s.data.copyWith(secondary: updatedSecondary)));
    }
  }
}
