import 'package:equatable/equatable.dart';
import '../models/admin_audit_log_model.dart';

abstract class AdminAuditState extends Equatable {
  const AdminAuditState();
  @override
  List<Object?> get props => [];
}

class AdminAuditInitialState extends AdminAuditState {}
class AdminAuditLoadingState extends AdminAuditState {}

class AdminAuditLoadedState extends AdminAuditState {
  final List<AdminAuditLogModel> allLogs;
  final String selectedFilter;

  const AdminAuditLoadedState({
    required this.allLogs,
    this.selectedFilter = 'all',
  });

  List<AdminAuditLogModel> get filteredLogs {
    if (selectedFilter == 'all') return allLogs;
    return allLogs
        .where((log) => log.action.toLowerCase() == selectedFilter.toLowerCase())
        .toList();
  }

  AdminAuditLoadedState copyWith({
    List<AdminAuditLogModel>? allLogs,
    String? selectedFilter,
  }) {
    return AdminAuditLoadedState(
      allLogs: allLogs ?? this.allLogs,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  @override
  List<Object?> get props => [allLogs, selectedFilter];
}

class AdminAuditErrorState extends AdminAuditState {
  final String message;
  const AdminAuditErrorState(this.message);
  @override
  List<Object?> get props => [message];
}
