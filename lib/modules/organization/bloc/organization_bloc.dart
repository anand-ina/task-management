import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/organization_repository.dart';
import 'organization_event.dart';
import 'organization_state.dart';

class OrganizationBloc extends Bloc<OrganizationEvent, OrganizationState> {
  final OrganizationRepository repository;

  OrganizationBloc({OrganizationRepository? organizationRepository})
      : repository = organizationRepository ?? OrganizationRepository(),
        super(OrganizationInitialState()) {
    on<FetchOrganizationDataEvent>(_onFetchOrganizationData);
  }

  Future<void> _onFetchOrganizationData(
    FetchOrganizationDataEvent event,
    Emitter<OrganizationState> emit,
  ) async {
    emit(OrganizationLoadingState());
    try {
      final data = await repository.getOrganizationData(bucket: event.bucket);
      emit(OrganizationLoadedState(data: data, activeBucket: event.bucket));
    } catch (e) {
      emit(OrganizationErrorState(e.toString()));
    }
  }
}
