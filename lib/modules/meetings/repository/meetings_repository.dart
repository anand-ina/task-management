import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../dashboard/models/branch_model.dart';
import '../models/availability_model.dart';
import '../models/meeting_model.dart';
import '../models/one_on_one_pending_model.dart';

class ScheduleLookupsData {
  final List<BranchModel> branches;
  final List<MeetingAvailabilityModel> availability;

  ScheduleLookupsData({
    required this.branches,
    required this.availability,
  });
}

class MeetingsRepository {
  final DioClient _dioClient = DioClient();

  Future<List<OneOnOnePendingModel>> getOneOnOnePending() async {
    final response = await _dioClient.dio.get(ApiConstants.oneOnOnePending);

    if (response.data is List) {
      return (response.data as List).map((e) => OneOnOnePendingModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<MeetingItemModel>> getMyScheduledMeetings() async {
    final response = await _dioClient.dio.get(ApiConstants.meetings);

    if (response.data is List) {
      return (response.data as List).map((e) => MeetingItemModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<MeetingItemModel>> getMeetingsViewAll() async {
    final response = await _dioClient.dio.get(
      ApiConstants.meetings,
      queryParameters: {'view': 'all'},
    );

    if (response.data is List) {
      return (response.data as List).map((e) => MeetingItemModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<ScheduleLookupsData> getScheduleLookups({String atTime = '2026-08-19T14:00'}) async {
    final results = await Future.wait([
      _dioClient.dio.get(ApiConstants.branches),
      _dioClient.dio.get(ApiConstants.meetingsAvailability, queryParameters: {'at': atTime}),
      _dioClient.dio.get(ApiConstants.notifications),
    ]);

    List<BranchModel> branches = [];
    if (results[0].data is List) {
      branches = (results[0].data as List).map((e) => BranchModel.fromJson(e)).toList();
    }

    List<MeetingAvailabilityModel> availability = [];
    if (results[1].data is List) {
      availability = (results[1].data as List).map((e) => MeetingAvailabilityModel.fromJson(e)).toList();
    }

    return ScheduleLookupsData(
      branches: branches,
      availability: availability,
    );
  }
}
