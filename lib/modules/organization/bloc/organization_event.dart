abstract class OrganizationEvent {}

class FetchOrganizationDataEvent extends OrganizationEvent {
  final String bucket;
  final int? branchId;
  FetchOrganizationDataEvent({this.bucket = 'week', this.branchId});
}
