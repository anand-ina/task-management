import '../models/organization_data_model.dart';

abstract class OrganizationState {}

class OrganizationInitialState extends OrganizationState {}

class OrganizationLoadingState extends OrganizationState {}

class OrganizationLoadedState extends OrganizationState {
  final OrganizationDataModel data;
  final String activeBucket;

  OrganizationLoadedState({
    required this.data,
    this.activeBucket = 'week',
  });
}

class OrganizationErrorState extends OrganizationState {
  final String message;
  OrganizationErrorState(this.message);
}
