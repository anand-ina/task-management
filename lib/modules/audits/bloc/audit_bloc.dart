import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/audit_model.dart';
import '../repository/audit_repository.dart';
import 'audit_event.dart';
import 'audit_state.dart';

class AuditBloc extends Bloc<AuditEvent, AuditState> {
  final AuditRepository _repository;

  AuditBloc({AuditRepository? repository})
      : _repository = repository ?? AuditRepository(),
        super(AuditInitialState()) {
    on<FetchAuditsEvent>(_onFetchAudits);
    on<ScheduleAuditEvent>(_onScheduleAudit);
    on<SelectAuditDetailEvent>(_onSelectAuditDetail);
    on<CloseAuditEvent>(_onCloseAudit);
    on<ClearAuditDetailEvent>(_onClearAuditDetail);
  }

  Future<void> _onFetchAudits(
    FetchAuditsEvent event,
    Emitter<AuditState> emit,
  ) async {
    final current = state is AuditLoadedState ? (state as AuditLoadedState) : null;
    if (current == null) {
      emit(AuditLoadingState());
    }

    try {
      final meta = current?.meta.people.isNotEmpty == true
          ? current!.meta
          : await _repository.getAuditMeta();

      final audits = event.isAuditee
          ? await _repository.getAsAuditeeAudits()
          : await _repository.getAsAuditorAudits();

      emit(AuditLoadedState(
        meta: meta,
        audits: audits,
        selectedAudit: current?.selectedAudit,
      ));
    } catch (e) {
      emit(AuditErrorState(e.toString()));
    }
  }

  Future<void> _onScheduleAudit(
    ScheduleAuditEvent event,
    Emitter<AuditState> emit,
  ) async {
    final current = state is AuditLoadedState ? (state as AuditLoadedState) : null;
    if (current == null) return;

    emit(current.copyWith(isScheduling: true, actionSuccess: null, actionError: null));

    try {
      final success = await _repository.scheduleAudit(event.body);
      if (success) {
        final audits = event.isAuditee
            ? await _repository.getAsAuditeeAudits()
            : await _repository.getAsAuditorAudits();
        emit(current.copyWith(
          isScheduling: false,
          audits: audits,
          actionSuccess: 'Audit scheduled successfully.',
        ));
      } else {
        emit(current.copyWith(
          isScheduling: false,
          actionError: 'Failed to schedule audit. Please check your inputs.',
        ));
      }
    } catch (e) {
      emit(current.copyWith(
        isScheduling: false,
        actionError: e.toString(),
      ));
    }
  }

  Future<void> _onSelectAuditDetail(
    SelectAuditDetailEvent event,
    Emitter<AuditState> emit,
  ) async {
    final current = state is AuditLoadedState ? (state as AuditLoadedState) : null;
    if (current == null) return;

    emit(current.copyWith(isLoadingDetail: true));

    try {
      final detail = await _repository.getAuditById(event.id);
      if (detail != null) {
        emit(current.copyWith(
          isLoadingDetail: false,
          selectedAudit: detail,
        ));
      } else {
        emit(current.copyWith(isLoadingDetail: false));
      }
    } catch (_) {
      emit(current.copyWith(isLoadingDetail: false));
    }
  }

  Future<void> _onCloseAudit(
    CloseAuditEvent event,
    Emitter<AuditState> emit,
  ) async {
    final current = state is AuditLoadedState ? (state as AuditLoadedState) : null;
    if (current == null) return;

    emit(current.copyWith(isClosing: true, actionSuccess: null, actionError: null));

    try {
      final success = await _repository.closeAudit(event.id);
      if (success) {
        final audits = event.isAuditee
            ? await _repository.getAsAuditeeAudits()
            : await _repository.getAsAuditorAudits();
        final detail = await _repository.getAuditById(event.id);
        emit(current.copyWith(
          isClosing: false,
          audits: audits,
          selectedAudit: detail,
          actionSuccess: 'Audit closed successfully.',
        ));
      } else {
        emit(current.copyWith(
          isClosing: false,
          actionError: 'Failed to close audit.',
        ));
      }
    } catch (e) {
      emit(current.copyWith(
        isClosing: false,
        actionError: e.toString(),
      ));
    }
  }

  void _onClearAuditDetail(
    ClearAuditDetailEvent event,
    Emitter<AuditState> emit,
  ) {
    final current = state is AuditLoadedState ? (state as AuditLoadedState) : null;
    if (current != null) {
      emit(current.copyWith(clearSelectedAudit: true));
    }
  }
}
