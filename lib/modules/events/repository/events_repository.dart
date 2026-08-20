import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/event_model.dart';

class EventsRepository {
  final DioClient _dioClient = DioClient();

  Future<List<EventModel>> getEvents() async {
    final response = await _dioClient.dio.get(ApiConstants.events);

    if (response.data is List) {
      return (response.data as List).map((e) => EventModel.fromJson(e)).toList();
    }
    return [];
  }
}
