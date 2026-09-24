abstract class HourlyLogEvent {
  const HourlyLogEvent();
}

class FetchHourlyLogEvent extends HourlyLogEvent {
  final String? date;
  const FetchHourlyLogEvent({this.date});
}

class AddHourlyItemEvent extends HourlyLogEvent {
  final String slot;
  final String body;
  const AddHourlyItemEvent({required this.slot, required this.body});
}

class DeleteHourlyItemEvent extends HourlyLogEvent {
  final int id;
  final String slot;
  const DeleteHourlyItemEvent({required this.id, required this.slot});
}

class EditHourlyItemEvent extends HourlyLogEvent {
  final int id;
  final String slot;
  final String body;
  const EditHourlyItemEvent({
    required this.id,
    required this.slot,
    required this.body,
  });
}

class SetLunchSlotEvent extends HourlyLogEvent {
  final String slot;
  const SetLunchSlotEvent({required this.slot});
}

class SubmitDsrEvent extends HourlyLogEvent {
  const SubmitDsrEvent();
}
