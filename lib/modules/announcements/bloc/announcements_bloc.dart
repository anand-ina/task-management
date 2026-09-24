import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/announcement_model.dart';
import '../repository/announcements_repository.dart';
import 'announcements_event.dart';
import 'announcements_state.dart';

class AnnouncementsBloc extends Bloc<AnnouncementsEvent, AnnouncementsState> {
  final AnnouncementsRepository _repository;

  AnnouncementsBloc({AnnouncementsRepository? repository})
      : _repository = repository ?? AnnouncementsRepository(),
        super(AnnouncementsInitialState()) {
    on<FetchAnnouncementsEvent>(_onFetchAnnouncements);
    on<FetchActiveAnnouncementsEvent>((event, emit) => _onFetchAnnouncements(const FetchAnnouncementsEvent(fetchActiveOnly: true), emit));
    on<CreateAnnouncementEvent>(_onCreateAnnouncement);
    on<UpdateAnnouncementEvent>(_onUpdateAnnouncement);
    on<ToggleActiveAnnouncementEvent>(_onToggleActiveAnnouncement);
    on<DeleteAnnouncementEvent>(_onDeleteAnnouncement);
  }

  Future<void> _onFetchAnnouncements(
    FetchAnnouncementsEvent event,
    Emitter<AnnouncementsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AnnouncementsLoadedState) {
      emit(AnnouncementsLoadingState());
    }

    try {
      final activeList = await _repository.getActiveAnnouncements();
      List<AnnouncementModel> allList = [];
      if (!event.fetchActiveOnly) {
        allList = await _repository.getAnnouncements();
      } else if (currentState is AnnouncementsLoadedState) {
        allList = currentState.announcements;
      }

      emit(AnnouncementsLoadedState(
        announcements: allList,
        activeAnnouncements: activeList,
      ));
    } catch (e) {
      if (currentState is AnnouncementsLoadedState) {
        emit(currentState.copyWith(errorMessage: e.toString()));
      } else {
        emit(AnnouncementsErrorState(e.toString()));
      }
    }
  }

  Future<void> _onCreateAnnouncement(
    CreateAnnouncementEvent event,
    Emitter<AnnouncementsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AnnouncementsLoadedState) {
      emit(currentState.copyWith(isSubmitting: true));
    }

    try {
      await _repository.createAnnouncement(event.payload);
      final activeList = await _repository.getActiveAnnouncements();
      final allList = await _repository.getAnnouncements();
      emit(AnnouncementsLoadedState(
        announcements: allList,
        activeAnnouncements: activeList,
        successMessage: 'created',
      ));
    } catch (e) {
      if (currentState is AnnouncementsLoadedState) {
        emit(currentState.copyWith(isSubmitting: false, errorMessage: e.toString()));
      } else {
        emit(AnnouncementsErrorState(e.toString()));
      }
    }
  }

  Future<void> _onUpdateAnnouncement(
    UpdateAnnouncementEvent event,
    Emitter<AnnouncementsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AnnouncementsLoadedState) {
      emit(currentState.copyWith(isSubmitting: true));
    }

    try {
      await _repository.updateAnnouncement(event.id, event.payload);
      final activeList = await _repository.getActiveAnnouncements();
      final allList = await _repository.getAnnouncements();
      emit(AnnouncementsLoadedState(
        announcements: allList,
        activeAnnouncements: activeList,
        successMessage: 'updated',
      ));
    } catch (e) {
      if (currentState is AnnouncementsLoadedState) {
        emit(currentState.copyWith(isSubmitting: false, errorMessage: e.toString()));
      } else {
        emit(AnnouncementsErrorState(e.toString()));
      }
    }
  }

  Future<void> _onToggleActiveAnnouncement(
    ToggleActiveAnnouncementEvent event,
    Emitter<AnnouncementsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AnnouncementsLoadedState) {
      emit(currentState.copyWith(isSubmitting: true));
    }

    try {
      await _repository.setAnnouncementActive(event.id, event.active);
      final activeList = await _repository.getActiveAnnouncements();
      final allList = await _repository.getAnnouncements();
      emit(AnnouncementsLoadedState(
        announcements: allList,
        activeAnnouncements: activeList,
        successMessage: event.active ? 'activated' : 'deactivated',
      ));
    } catch (e) {
      if (currentState is AnnouncementsLoadedState) {
        emit(currentState.copyWith(isSubmitting: false, errorMessage: e.toString()));
      } else {
        emit(AnnouncementsErrorState(e.toString()));
      }
    }
  }

  Future<void> _onDeleteAnnouncement(
    DeleteAnnouncementEvent event,
    Emitter<AnnouncementsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AnnouncementsLoadedState) {
      emit(currentState.copyWith(isSubmitting: true));
    }

    try {
      await _repository.deleteAnnouncement(event.id);
      final activeList = await _repository.getActiveAnnouncements();
      final allList = await _repository.getAnnouncements();
      emit(AnnouncementsLoadedState(
        announcements: allList,
        activeAnnouncements: activeList,
        successMessage: 'deleted',
      ));
    } catch (e) {
      if (currentState is AnnouncementsLoadedState) {
        emit(currentState.copyWith(isSubmitting: false, errorMessage: e.toString()));
      } else {
        emit(AnnouncementsErrorState(e.toString()));
      }
    }
  }
}
