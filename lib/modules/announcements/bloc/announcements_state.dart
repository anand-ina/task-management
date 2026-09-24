import 'package:equatable/equatable.dart';
import '../models/announcement_model.dart';

abstract class AnnouncementsState extends Equatable {
  const AnnouncementsState();

  @override
  List<Object?> get props => [];
}

class AnnouncementsInitialState extends AnnouncementsState {}

class AnnouncementsLoadingState extends AnnouncementsState {}

class AnnouncementsLoadedState extends AnnouncementsState {
  final List<AnnouncementModel> announcements;
  final List<AnnouncementModel> activeAnnouncements;
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;

  const AnnouncementsLoadedState({
    required this.announcements,
    required this.activeAnnouncements,
    this.isSubmitting = false,
    this.successMessage,
    this.errorMessage,
  });

  AnnouncementsLoadedState copyWith({
    List<AnnouncementModel>? announcements,
    List<AnnouncementModel>? activeAnnouncements,
    bool? isSubmitting,
    String? successMessage,
    String? errorMessage,
  }) {
    return AnnouncementsLoadedState(
      announcements: announcements ?? this.announcements,
      activeAnnouncements: activeAnnouncements ?? this.activeAnnouncements,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        announcements,
        activeAnnouncements,
        isSubmitting,
        successMessage,
        errorMessage,
      ];
}

class AnnouncementsErrorState extends AnnouncementsState {
  final String message;

  const AnnouncementsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
