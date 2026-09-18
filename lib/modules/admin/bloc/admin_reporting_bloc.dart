import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/admin_reporting_repository.dart';
import 'admin_reporting_event.dart';
import 'admin_reporting_state.dart';

class AdminReportingBloc extends Bloc<AdminReportingEvent, AdminReportingState> {
  final AdminReportingRepository _repository = AdminReportingRepository();

  AdminReportingBloc() : super(AdminReportingInitialState()) {
    on<FetchReportingEvent>(_onFetch);
    on<AddManagerEvent>(_onAddManager);
    on<RemoveManagerEvent>(_onRemoveManager);
    on<SaveReportingEvent>(_onSaveReporting);
  }

  Future<void> _onFetch(FetchReportingEvent event, Emitter<AdminReportingState> emit) async {
    emit(AdminReportingLoadingState());
    try {
      final people = await _repository.getReportingPeople();
      emit(AdminReportingLoadedState(people: people));
    } catch (e) {
      emit(AdminReportingErrorState(e.toString()));
    }
  }

  void _onAddManager(AddManagerEvent event, Emitter<AdminReportingState> emit) {
    if (state is! AdminReportingLoadedState) return;
    final s = state as AdminReportingLoadedState;
    final updatedPeople = s.people.map((person) {
      if (person.id == event.personId) {
        if (event.isPrimary) {
          final newPrimary = List<int>.from(person.primary);
          if (!newPrimary.contains(event.managerId)) newPrimary.add(event.managerId);
          return person.copyWith(primary: newPrimary);
        } else {
          final newSecondary = List<int>.from(person.secondary);
          if (!newSecondary.contains(event.managerId)) newSecondary.add(event.managerId);
          return person.copyWith(secondary: newSecondary);
        }
      }
      return person;
    }).toList();
    emit(AdminReportingLoadedState(people: updatedPeople));
  }

  void _onRemoveManager(RemoveManagerEvent event, Emitter<AdminReportingState> emit) {
    if (state is! AdminReportingLoadedState) return;
    final s = state as AdminReportingLoadedState;
    final updatedPeople = s.people.map((person) {
      if (person.id == event.personId) {
        if (event.isPrimary) {
          final newPrimary = person.primary.where((id) => id != event.managerId).toList();
          return person.copyWith(primary: newPrimary);
        } else {
          final newSecondary = person.secondary.where((id) => id != event.managerId).toList();
          return person.copyWith(secondary: newSecondary);
        }
      }
      return person;
    }).toList();
    emit(AdminReportingLoadedState(people: updatedPeople));
  }

  Future<void> _onSaveReporting(
    SaveReportingEvent event,
    Emitter<AdminReportingState> emit,
  ) async {
    if (state is! AdminReportingLoadedState) return;
    final s = state as AdminReportingLoadedState;
    final match = s.people.where((p) => p.id == event.personId);
    if (match.isNotEmpty) {
      final person = match.first;
      await _repository.updateReporting(
        personId: event.personId,
        primary: person.primary,
        secondary: person.secondary,
      );
    }
  }
}
