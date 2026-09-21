abstract class TaskIdSettingsEvent {
  const TaskIdSettingsEvent();
}

class FetchTaskIdSettingsEvent extends TaskIdSettingsEvent {
  const FetchTaskIdSettingsEvent();
}

class ResetBranchCounterEvent extends TaskIdSettingsEvent {
  final int branchId;
  final String branchCode;

  const ResetBranchCounterEvent({
    required this.branchId,
    required this.branchCode,
  });
}

class ResetAllCountersEvent extends TaskIdSettingsEvent {
  const ResetAllCountersEvent();
}

class UpdateBranchTicketOwnerEvent extends TaskIdSettingsEvent {
  final int branchId;
  final int? ownerId;

  const UpdateBranchTicketOwnerEvent({
    required this.branchId,
    required this.ownerId,
  });
}

class UpdateFallbackTicketOwnerEvent extends TaskIdSettingsEvent {
  final int? ownerId;

  const UpdateFallbackTicketOwnerEvent({
    required this.ownerId,
  });
}
