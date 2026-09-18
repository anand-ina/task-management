import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/admin_audit_repository.dart';
import 'admin_audit_event.dart';
import 'admin_audit_state.dart';

class AdminAuditBloc extends Bloc<AdminAuditEvent, AdminAuditState> {
  final AdminAuditRepository _repository = AdminAuditRepository();

  AdminAuditBloc() : super(AdminAuditInitialState()) {
    on<FetchAuditLogsEvent>(_onFetch);
    on<FilterAuditLogsEvent>(_onFilter);
  }

  Future<void> _onFetch(FetchAuditLogsEvent event, Emitter<AdminAuditState> emit) async {
    emit(AdminAuditLoadingState());
    try {
      final logs = await _repository.getAuditLogs();
      emit(AdminAuditLoadedState(allLogs: logs));
    } catch (e) {
      emit(AdminAuditErrorState(e.toString()));
    }
  }

  void _onFilter(FilterAuditLogsEvent event, Emitter<AdminAuditState> emit) {
    if (state is! AdminAuditLoadedState) return;
    final s = state as AdminAuditLoadedState;
    emit(s.copyWith(selectedFilter: event.actionFilter));
  }
}
