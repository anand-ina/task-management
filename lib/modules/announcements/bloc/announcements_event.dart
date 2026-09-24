import 'package:equatable/equatable.dart';

abstract class AnnouncementsEvent extends Equatable {
  const AnnouncementsEvent();

  @override
  List<Object?> get props => [];
}

class FetchAnnouncementsEvent extends AnnouncementsEvent {
  final bool fetchActiveOnly;

  const FetchAnnouncementsEvent({this.fetchActiveOnly = false});

  @override
  List<Object?> get props => [fetchActiveOnly];
}

class FetchActiveAnnouncementsEvent extends AnnouncementsEvent {
  const FetchActiveAnnouncementsEvent();

  @override
  List<Object?> get props => [];
}

class CreateAnnouncementEvent extends AnnouncementsEvent {
  final Map<String, dynamic> payload;

  const CreateAnnouncementEvent(this.payload);

  @override
  List<Object?> get props => [payload];
}

class UpdateAnnouncementEvent extends AnnouncementsEvent {
  final int id;
  final Map<String, dynamic> payload;

  const UpdateAnnouncementEvent({
    required this.id,
    required this.payload,
  });

  @override
  List<Object?> get props => [id, payload];
}

class ToggleActiveAnnouncementEvent extends AnnouncementsEvent {
  final int id;
  final bool active;

  const ToggleActiveAnnouncementEvent({
    required this.id,
    required this.active,
  });

  @override
  List<Object?> get props => [id, active];
}

class DeleteAnnouncementEvent extends AnnouncementsEvent {
  final int id;

  const DeleteAnnouncementEvent(this.id);

  @override
  List<Object?> get props => [id];
}
