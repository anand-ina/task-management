import '../models/task_id_settings_model.dart';

abstract class TaskIdSettingsState {
  const TaskIdSettingsState();
}

class TaskIdSettingsInitialState extends TaskIdSettingsState {
  const TaskIdSettingsInitialState();
}

class TaskIdSettingsLoadingState extends TaskIdSettingsState {
  const TaskIdSettingsLoadingState();
}

class TaskIdSettingsLoadedState extends TaskIdSettingsState {
  final TaskCounterResponse counterData;
  final TicketSettingsResponse ticketSettings;
  final List<AssigneeLookupItem> assignees;
  final String? successMessage;

  const TaskIdSettingsLoadedState({
    required this.counterData,
    required this.ticketSettings,
    required this.assignees,
    this.successMessage,
  });

  TaskIdSettingsLoadedState copyWith({
    TaskCounterResponse? counterData,
    TicketSettingsResponse? ticketSettings,
    List<AssigneeLookupItem>? assignees,
    String? successMessage,
  }) {
    return TaskIdSettingsLoadedState(
      counterData: counterData ?? this.counterData,
      ticketSettings: ticketSettings ?? this.ticketSettings,
      assignees: assignees ?? this.assignees,
      successMessage: successMessage,
    );
  }
}

class TaskIdSettingsErrorState extends TaskIdSettingsState {
  final String message;

  const TaskIdSettingsErrorState(this.message);
}
