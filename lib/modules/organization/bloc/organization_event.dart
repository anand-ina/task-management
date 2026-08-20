abstract class OrganizationEvent {}

class FetchOrganizationDataEvent extends OrganizationEvent {
  final String bucket;
  FetchOrganizationDataEvent({this.bucket = 'week'});
}
