import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/hourly_log_model.dart';
import '../repository/hourly_log_repository.dart';
import 'hourly_log_event.dart';
import 'hourly_log_state.dart';

class HourlyLogBloc extends Bloc<HourlyLogEvent, HourlyLogState> {
  final HourlyLogRepository repository;

  HourlyLogBloc(this.repository) : super(const HourlyLogInitialState()) {
    on<FetchHourlyLogEvent>(_onFetchHourlyLog);
    on<AddHourlyItemEvent>(_onAddHourlyItem);
    on<DeleteHourlyItemEvent>(_onDeleteHourlyItem);
    on<EditHourlyItemEvent>(_onEditHourlyItem);
    on<SetLunchSlotEvent>(_onSetLunchSlot);
    on<SubmitDsrEvent>(_onSubmitDsr);
  }

  Future<void> _onFetchHourlyLog(
    FetchHourlyLogEvent event,
    Emitter<HourlyLogState> emit,
  ) async {
    emit(const HourlyLogLoadingState());
    final result = await repository.getHourlyLog(date: event.date);
    if (result != null) {
      emit(HourlyLogLoadedState(hourlyLog: result));
    } else {
      emit(const HourlyLogErrorState('Failed to load hourly log'));
    }
  }

  Future<void> _onAddHourlyItem(
    AddHourlyItemEvent event,
    Emitter<HourlyLogState> emit,
  ) async {
    if (state is! HourlyLogLoadedState) return;
    final currentState = state as HourlyLogLoadedState;

    final newId = await repository.addHourlyItem(event.slot, event.body);
    if (newId != null) {
      final updatedSlots = currentState.hourlyLog.slots.map((slot) {
        if (slot.slot == event.slot) {
          final updatedItems = List<HourlyItemModel>.from(slot.items)
            ..add(HourlyItemModel(id: newId, body: event.body));
          return slot.copyWith(items: updatedItems);
        }
        return slot;
      }).toList();

      emit(currentState.copyWith(
        hourlyLog: currentState.hourlyLog.copyWith(slots: updatedSlots),
      ));
    }
  }

  Future<void> _onDeleteHourlyItem(
    DeleteHourlyItemEvent event,
    Emitter<HourlyLogState> emit,
  ) async {
    if (state is! HourlyLogLoadedState) return;
    final currentState = state as HourlyLogLoadedState;

    final success = await repository.deleteHourlyItem(event.id);
    if (success) {
      final updatedSlots = currentState.hourlyLog.slots.map((slot) {
        if (slot.slot == event.slot) {
          final updatedItems = slot.items.where((i) => i.id != event.id).toList();
          return slot.copyWith(items: updatedItems);
        }
        return slot;
      }).toList();

      emit(currentState.copyWith(
        hourlyLog: currentState.hourlyLog.copyWith(slots: updatedSlots),
      ));
    }
  }

  Future<void> _onEditHourlyItem(
    EditHourlyItemEvent event,
    Emitter<HourlyLogState> emit,
  ) async {
    if (state is! HourlyLogLoadedState) return;
    final currentState = state as HourlyLogLoadedState;

    final success = await repository.editHourlyItem(event.id, event.body);
    if (success) {
      final updatedSlots = currentState.hourlyLog.slots.map((slot) {
        if (slot.slot == event.slot) {
          final updatedItems = slot.items.map((item) {
            if (item.id == event.id) {
              return HourlyItemModel(id: item.id, body: event.body);
            }
            return item;
          }).toList();
          return slot.copyWith(items: updatedItems);
        }
        return slot;
      }).toList();

      emit(currentState.copyWith(
        hourlyLog: currentState.hourlyLog.copyWith(slots: updatedSlots),
      ));
    }
  }

  Future<void> _onSetLunchSlot(
    SetLunchSlotEvent event,
    Emitter<HourlyLogState> emit,
  ) async {
    if (state is! HourlyLogLoadedState) return;
    final currentState = state as HourlyLogLoadedState;

    final success = await repository.setLunchSlot(event.slot);
    if (success) {
      final updatedSlots = currentState.hourlyLog.slots.map((slot) {
        if (slot.slot == event.slot) {
          return slot.copyWith(lunch: !slot.lunch);
        }
        return slot;
      }).toList();

      emit(currentState.copyWith(
        hourlyLog: currentState.hourlyLog.copyWith(
          slots: updatedSlots,
          lunch: event.slot,
        ),
      ));
    }
  }

  Future<void> _onSubmitDsr(
    SubmitDsrEvent event,
    Emitter<HourlyLogState> emit,
  ) async {
    if (state is! HourlyLogLoadedState) return;
    final currentState = state as HourlyLogLoadedState;

    emit(currentState.copyWith(isSubmitting: true));
    final success = await repository.submitDsr();
    if (success) {
      emit(currentState.copyWith(
        isSubmitting: false,
        isSuccess: true,
        hourlyLog: currentState.hourlyLog.copyWith(isSubmitted: true),
        actionMessage: 'Hourly log submitted successfully!',
      ));
    } else {
      emit(currentState.copyWith(
        isSubmitting: false,
        isSuccess: false,
        actionMessage: 'Failed to submit DSR',
      ));
    }
  }
}
