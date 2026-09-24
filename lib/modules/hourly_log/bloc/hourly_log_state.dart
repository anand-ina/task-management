import '../models/hourly_log_model.dart';

abstract class HourlyLogState {
  const HourlyLogState();
}

class HourlyLogInitialState extends HourlyLogState {
  const HourlyLogInitialState();
}

class HourlyLogLoadingState extends HourlyLogState {
  const HourlyLogLoadingState();
}

class HourlyLogLoadedState extends HourlyLogState {
  final HourlyLogModel hourlyLog;
  final bool isSubmitting;
  final String? actionMessage;
  final bool isSuccess;

  const HourlyLogLoadedState({
    required this.hourlyLog,
    this.isSubmitting = false,
    this.actionMessage,
    this.isSuccess = false,
  });

  HourlyLogLoadedState copyWith({
    HourlyLogModel? hourlyLog,
    bool? isSubmitting,
    String? actionMessage,
    bool? isSuccess,
  }) {
    return HourlyLogLoadedState(
      hourlyLog: hourlyLog ?? this.hourlyLog,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      actionMessage: actionMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class HourlyLogErrorState extends HourlyLogState {
  final String message;
  const HourlyLogErrorState(this.message);
}
