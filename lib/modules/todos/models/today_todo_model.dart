class TodayTodoItemModel {
  final int id;
  final int userId;
  final String day;
  final String text;
  final bool done;
  final String createdAt;
  final String? doneOn;
  final bool carried;
  final int ageDays;
  final bool auto;
  final int? taskId;
  final String? taskNo;

  TodayTodoItemModel({
    required this.id,
    required this.userId,
    required this.day,
    required this.text,
    required this.done,
    required this.createdAt,
    this.doneOn,
    this.carried = false,
    this.ageDays = 0,
    this.auto = false,
    this.taskId,
    this.taskNo,
  });

  factory TodayTodoItemModel.fromJson(Map<String, dynamic> json) {
    return TodayTodoItemModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] as int : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      day: json['day']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      done: json['done'] as bool? ?? false,
      createdAt: json['created_at']?.toString() ?? '',
      doneOn: json['done_on']?.toString(),
      carried: json['carried'] as bool? ?? false,
      ageDays: json['age_days'] is int ? json['age_days'] as int : (int.tryParse(json['age_days']?.toString() ?? '') ?? 0),
      auto: json['auto'] as bool? ?? false,
      taskId: json['task_id'] is int ? json['task_id'] as int : int.tryParse(json['task_id']?.toString() ?? ''),
      taskNo: json['task_no']?.toString(),
    );
  }
}

class TodayTodoResponseModel {
  final int openCount;
  final int doneCount;
  final int carriedCount;
  final List<TodayTodoItemModel> carriedItems;
  final List<TodayTodoItemModel> todayItems;

  TodayTodoResponseModel({
    required this.openCount,
    required this.doneCount,
    required this.carriedCount,
    required this.carriedItems,
    required this.todayItems,
  });

  factory TodayTodoResponseModel.fromJson(dynamic json) {
    List<TodayTodoItemModel> allItems = [];

    if (json is Map<String, dynamic>) {
      if (json['items'] is List) {
        allItems = (json['items'] as List)
            .map((e) => TodayTodoItemModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      } else {
        if (json['carried'] is List) {
          allItems.addAll((json['carried'] as List).map((e) {
            final map = Map<String, dynamic>.from(e is Map<String, dynamic> ? e : {});
            map['carried'] = true;
            return TodayTodoItemModel.fromJson(map);
          }));
        }
        if (json['today'] is List) {
          allItems.addAll((json['today'] as List).map((e) {
            final map = Map<String, dynamic>.from(e is Map<String, dynamic> ? e : {});
            map['carried'] = false;
            return TodayTodoItemModel.fromJson(map);
          }));
        }
      }
    } else if (json is List) {
      allItems = json.map((e) => TodayTodoItemModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    }

    final carriedList = allItems.where((i) => i.carried).toList();
    final todayList = allItems.where((i) => !i.carried).toList();

    final open = allItems.where((i) => !i.done).length;
    final done = allItems.where((i) => i.done).length;
    final carriedCount = carriedList.length;

    return TodayTodoResponseModel(
      openCount: open,
      doneCount: done,
      carriedCount: carriedCount,
      carriedItems: carriedList,
      todayItems: todayList,
    );
  }
}
