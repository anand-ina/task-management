import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/announcement_model.dart';

class AnnouncementsRepository {
  final DioClient _dioClient = DioClient();

  dynamic _safeParse(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return null;
      }
    }
    return data;
  }

  void _logServiceCall({
    required String serviceMethod,
    required String url,
    dynamic payload,
    dynamic response,
  }) {
    debugPrint('---------------- [AnnouncementsService: $serviceMethod] ----------------');
    debugPrint('Service URL: $url');
    if (payload != null) {
      debugPrint('Service Payload: $payload');
    }
    if (response != null) {
      debugPrint('Service Response: $response');
    }
    debugPrint('------------------------------------------------------------------------');
  }

  /// GET /api/announcements/active
  Future<List<AnnouncementModel>> getActiveAnnouncements() async {
    const url = ApiConstants.announcementsActive;
    try {
      final response = await _dioClient.dio.get(url);
      _logServiceCall(
        serviceMethod: 'getActiveAnnouncements',
        url: url,
        response: response.data,
      );

      final parsed = _safeParse(response.data);
      if (parsed is List) {
        return parsed
            .map((item) => AnnouncementModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[AnnouncementsRepository] getActiveAnnouncements error: $e');
      rethrow;
    }
  }

  /// GET /api/announcements
  Future<List<AnnouncementModel>> getAnnouncements() async {
    const url = ApiConstants.announcements;
    try {
      final response = await _dioClient.dio.get(url);
      _logServiceCall(
        serviceMethod: 'getAnnouncements',
        url: url,
        response: response.data,
      );

      final parsed = _safeParse(response.data);
      if (parsed is List) {
        return parsed
            .map((item) => AnnouncementModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[AnnouncementsRepository] getAnnouncements error: $e');
      rethrow;
    }
  }

  /// POST /api/announcements
  Future<int?> createAnnouncement(Map<String, dynamic> data) async {
    const url = ApiConstants.announcements;
    try {
      final response = await _dioClient.dio.post(url, data: data);
      _logServiceCall(
        serviceMethod: 'createAnnouncement',
        url: url,
        payload: data,
        response: response.data,
      );

      final parsed = _safeParse(response.data);
      if (parsed is Map && parsed.containsKey('id')) {
        return parsed['id'] as int?;
      }
      return null;
    } catch (e) {
      debugPrint('[AnnouncementsRepository] createAnnouncement error: $e');
      rethrow;
    }
  }

  /// PATCH /api/announcements/:id (Edit)
  Future<bool> updateAnnouncement(int id, Map<String, dynamic> data) async {
    final url = ApiConstants.announcementDetail(id);
    try {
      final response = await _dioClient.dio.patch(url, data: data);
      _logServiceCall(
        serviceMethod: 'updateAnnouncement',
        url: url,
        payload: data,
        response: response.data,
      );

      final parsed = _safeParse(response.data);
      if (parsed is Map && parsed['ok'] == true) {
        return true;
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AnnouncementsRepository] updateAnnouncement error: $e');
      rethrow;
    }
  }

  /// PATCH /api/announcements/:id (Toggle Active / Deactivate)
  Future<bool> setAnnouncementActive(int id, bool active) async {
    final url = ApiConstants.announcementDetail(id);
    final data = {'active': active};
    try {
      final response = await _dioClient.dio.patch(url, data: data);
      _logServiceCall(
        serviceMethod: 'setAnnouncementActive',
        url: url,
        payload: data,
        response: response.data,
      );

      final parsed = _safeParse(response.data);
      if (parsed is Map && parsed['ok'] == true) {
        return true;
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AnnouncementsRepository] setAnnouncementActive error: $e');
      rethrow;
    }
  }

  /// DELETE /api/announcements/:id
  Future<bool> deleteAnnouncement(int id) async {
    final url = ApiConstants.announcementDetail(id);
    try {
      final response = await _dioClient.dio.delete(url);
      _logServiceCall(
        serviceMethod: 'deleteAnnouncement',
        url: url,
        response: response.data,
      );

      final parsed = _safeParse(response.data);
      if (parsed is Map && parsed['ok'] == true) {
        return true;
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AnnouncementsRepository] deleteAnnouncement error: $e');
      rethrow;
    }
  }
}
