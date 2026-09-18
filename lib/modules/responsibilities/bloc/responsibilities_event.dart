import 'package:equatable/equatable.dart';

abstract class ResponsibilitiesEvent extends Equatable {
  const ResponsibilitiesEvent();
  @override
  List<Object?> get props => [];
}

class FetchResponsibilitiesEvent extends ResponsibilitiesEvent {}

class AddResponsibilityEvent extends ResponsibilitiesEvent {
  final String kind;
  final String text;
  const AddResponsibilityEvent({required this.kind, required this.text});
  @override
  List<Object?> get props => [kind, text];
}

class DeleteResponsibilityEvent extends ResponsibilitiesEvent {
  final int id;
  final String kind;
  const DeleteResponsibilityEvent({required this.id, required this.kind});
  @override
  List<Object?> get props => [id, kind];
}
