import 'package:equatable/equatable.dart';
import '../models/dashboard_stats.dart';
import '../models/team_performance.dart';
import '../models/notification_model.dart';
import '../models/branch_model.dart';
import '../models/todo_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitialState extends DashboardState {}

class DashboardLoadingState extends DashboardState {}

class DashboardLoadedState extends DashboardState {
  final DashboardData dashboardData;
  final TeamData teamData;
  final NotificationsResponse notifications;
  final List<BranchModel> branches;
  final BranchModel? selectedBranch;
  final List<TodoItem> todos;

  const DashboardLoadedState({
    required this.dashboardData,
    required this.teamData,
    required this.notifications,
    required this.branches,
    this.selectedBranch,
    required this.todos,
  });

  DashboardLoadedState copyWith({
    DashboardData? dashboardData,
    TeamData? teamData,
    NotificationsResponse? notifications,
    List<BranchModel>? branches,
    BranchModel? selectedBranch,
    List<TodoItem>? todos,
  }) {
    return DashboardLoadedState(
      dashboardData: dashboardData ?? this.dashboardData,
      teamData: teamData ?? this.teamData,
      notifications: notifications ?? this.notifications,
      branches: branches ?? this.branches,
      selectedBranch: selectedBranch ?? this.selectedBranch,
      todos: todos ?? this.todos,
    );
  }

  @override
  List<Object?> get props => [dashboardData, teamData, notifications, branches, selectedBranch, todos];
}

class DashboardErrorState extends DashboardState {
  final String message;

  const DashboardErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}
