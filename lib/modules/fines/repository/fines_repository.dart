import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../performance/models/performance_me_model.dart';
import '../models/fine_item_model.dart';
import '../models/fine_type_model.dart';

class FinesOverviewData {
  final List<FineItemModel> fines;
  final List<FineTypeModel> fineTypes;
  final PerformanceMeModel me;

  FinesOverviewData({
    required this.fines,
    required this.fineTypes,
    required this.me,
  });
}

class FinesRepository {
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

  Future<FinesOverviewData> getFinesOverviewData() async {
    final results = await Future.wait([
      _dioClient.dio.get(ApiConstants.fines),
      _dioClient.dio.get(ApiConstants.finesTypes),
      _dioClient.dio.get(ApiConstants.performanceMe),
    ]);

    final res0 = _safeParse(results[0].data);
    List<FineItemModel> fines = [];
    if (res0 is List) {
      fines = res0.map((e) => FineItemModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    }

    final res1 = _safeParse(results[1].data);
    List<FineTypeModel> fineTypes = [];
    if (res1 is List) {
      fineTypes = res1.map((e) => FineTypeModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    }

    final res2 = _safeParse(results[2].data);
    PerformanceMeModel me = PerformanceMeModel(assigned: 0, done: 0, overdue: 0, points: 0);
    if (res2 is Map<String, dynamic>) {
      me = PerformanceMeModel.fromJson(res2);
    }

    return FinesOverviewData(
      fines: fines,
      fineTypes: fineTypes,
      me: me,
    );
  }

  Future<List<FineTypeModel>> getFineTypes() async {
    final response = await _dioClient.dio.get(ApiConstants.finesTypes);
    final res = _safeParse(response.data);
    if (res is List) {
      return res.map((e) => FineTypeModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    }
    return [];
  }
}
