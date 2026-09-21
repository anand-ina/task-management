import 'package:equatable/equatable.dart';
import '../models/audit_model.dart';

abstract class AuditState extends Equatable {
  const AuditState();

  @override
  List<Object?> get props => [];
}

class AuditInitialState extends AuditState {}

class AuditLoadingState extends AuditState {}

class AuditLoadedState extends AuditState {
  final AuditMetaModel meta;
  final List<AuditItemModel> audits;
  final AuditItemModel? selectedAudit;
  final bool isLoadingDetail;
  final bool isScheduling;
  final bool isClosing;
  final String? actionSuccess;
  final String? actionError;

  const AuditLoadedState({
    required this.meta,
    required this.audits,
    this.selectedAudit,
    this.isLoadingDetail = false,
    this.isScheduling = false,
    this.isClosing = false,
    this.actionSuccess,
    this.actionError,
  });

  AuditLoadedState copyWith({
    AuditMetaModel? meta,
    List<AuditItemModel>? audits,
    AuditItemModel? selectedAudit,
    bool? clearSelectedAudit,
    bool? isLoadingDetail,
    bool? isScheduling,
    bool? isClosing,
    String? actionSuccess,
    String? actionError,
  }) {
    return AuditLoadedState(
      meta: meta ?? this.meta,
      audits: audits ?? this.audits,
      selectedAudit: clearSelectedAudit == true ? null : (selectedAudit ?? this.selectedAudit),
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      isScheduling: isScheduling ?? this.isScheduling,
      isClosing: isClosing ?? this.isClosing,
      actionSuccess: actionSuccess,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [
        meta,
        audits,
        selectedAudit,
        isLoadingDetail,
        isScheduling,
        isClosing,
        actionSuccess,
        actionError,
      ];
}

class AuditErrorState extends AuditState {
  final String message;

  const AuditErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
