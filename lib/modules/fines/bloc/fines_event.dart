abstract class FinesEvent {}

class FetchFinesEvent extends FinesEvent {}

class FetchFineTypesEvent extends FinesEvent {}

class AddFineTypeEvent extends FinesEvent {
  final String kind;
  final String label;
  final dynamic amount;

  AddFineTypeEvent({
    required this.kind,
    required this.label,
    required this.amount,
  });
}

class DeleteFineTypeEvent extends FinesEvent {
  final int id;
  final String kind;
  final String label;

  DeleteFineTypeEvent({
    required this.id,
    required this.kind,
    required this.label,
  });
}

class UpdateFineTypesEvent extends FinesEvent {
  final List<Map<String, dynamic>> types;

  UpdateFineTypesEvent(this.types);
}
