import '../models/fine_type_model.dart';
import '../repository/fines_repository.dart';

abstract class FinesState {}

class FinesInitialState extends FinesState {}

class FinesLoadingState extends FinesState {}

class FinesLoadedState extends FinesState {
  final FinesOverviewData data;
  FinesLoadedState(this.data);
}

class FineTypesLoadedState extends FinesState {
  final List<FineTypeModel> fineTypes;
  FineTypesLoadedState(this.fineTypes);
}

class FinesErrorState extends FinesState {
  final String message;
  FinesErrorState(this.message);
}
