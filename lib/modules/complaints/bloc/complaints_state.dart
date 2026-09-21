import 'package:equatable/equatable.dart';
import '../models/batch_ticket_response.dart';
import '../models/lookup_models.dart';
import '../models/ticket_insights_model.dart';
import '../models/ticket_meta_model.dart';
import '../models/ticket_model.dart';

abstract class ComplaintsState extends Equatable {
  const ComplaintsState();

  @override
  List<Object?> get props => [];
}

class ComplaintsInitialState extends ComplaintsState {}

class ComplaintsLoadingState extends ComplaintsState {}

class ComplaintsLoadedState extends ComplaintsState {
  final List<TicketItemModel> allItems;
  final List<TicketItemModel> filteredItems;
  final TicketCountsModel counts;
  final String statusTab; // 'open', 'overdue', 'resolved', 'all', 'new', 'in_progress', 'pending_reward'
  final TicketMetaModel meta;
  final List<LookupDepartmentModel> departments;
  final List<LookupBranchModel> branches;
  final List<LookupAssigneeModel> assignees;
  final String searchQuery;
  final String typeFilter;
  final String sourceFilter;
  final String categoryFilter;
  final String ownerFilter;
  final String mineFilter; // '', 'owned', 'raised'
  final bool isSubmitting;
  final TicketItemModel? submittedTicket;
  final BatchTicketResponse? batchCreatedResponse;
  final String? errorMessage;

  const ComplaintsLoadedState({
    required this.allItems,
    required this.filteredItems,
    required this.counts,
    required this.statusTab,
    this.meta = const TicketMetaModel(),
    this.departments = const [],
    this.branches = const [],
    this.assignees = const [],
    this.searchQuery = '',
    this.typeFilter = 'All types',
    this.sourceFilter = 'Parents & students',
    this.categoryFilter = 'All categories',
    this.ownerFilter = "Everyone's",
    this.mineFilter = '',
    this.isSubmitting = false,
    this.submittedTicket,
    this.batchCreatedResponse,
    this.errorMessage,
  });

  ComplaintsLoadedState copyWith({
    List<TicketItemModel>? allItems,
    List<TicketItemModel>? filteredItems,
    TicketCountsModel? counts,
    String? statusTab,
    TicketMetaModel? meta,
    List<LookupDepartmentModel>? departments,
    List<LookupBranchModel>? branches,
    List<LookupAssigneeModel>? assignees,
    String? searchQuery,
    String? typeFilter,
    String? sourceFilter,
    String? categoryFilter,
    String? ownerFilter,
    String? mineFilter,
    bool? isSubmitting,
    TicketItemModel? submittedTicket,
    BatchTicketResponse? batchCreatedResponse,
    String? errorMessage,
  }) {
    return ComplaintsLoadedState(
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      counts: counts ?? this.counts,
      statusTab: statusTab ?? this.statusTab,
      meta: meta ?? this.meta,
      departments: departments ?? this.departments,
      branches: branches ?? this.branches,
      assignees: assignees ?? this.assignees,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: typeFilter ?? this.typeFilter,
      sourceFilter: sourceFilter ?? this.sourceFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      ownerFilter: ownerFilter ?? this.ownerFilter,
      mineFilter: mineFilter ?? this.mineFilter,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittedTicket: submittedTicket,
      batchCreatedResponse: batchCreatedResponse,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        allItems,
        filteredItems,
        counts,
        statusTab,
        meta,
        departments,
        branches,
        assignees,
        searchQuery,
        typeFilter,
        sourceFilter,
        categoryFilter,
        ownerFilter,
        mineFilter,
        isSubmitting,
        submittedTicket,
        batchCreatedResponse,
        errorMessage,
      ];
}

class ComplaintsErrorState extends ComplaintsState {
  final String message;

  const ComplaintsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class ComplaintsDashboardLoadedState extends ComplaintsState {
  final TicketInsightsResponse insights;
  final List<LookupBranchModel> branches;
  final int selectedYear;
  final int? selectedBranchId;
  final bool isLoading;
  final String? errorMessage;

  const ComplaintsDashboardLoadedState({
    required this.insights,
    this.branches = const [],
    this.selectedYear = 2026,
    this.selectedBranchId,
    this.isLoading = false,
    this.errorMessage,
  });

  ComplaintsDashboardLoadedState copyWith({
    TicketInsightsResponse? insights,
    List<LookupBranchModel>? branches,
    int? selectedYear,
    int? selectedBranchId,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ComplaintsDashboardLoadedState(
      insights: insights ?? this.insights,
      branches: branches ?? this.branches,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [insights, branches, selectedYear, selectedBranchId, isLoading, errorMessage];
}

class SourceComplaintsLoadedState extends ComplaintsState {
  final String source; // 'parent' or 'student'
  final List<TicketItemModel> items;
  final TicketCountsModel counts;
  final String statusTab; // 'everything', 'open', 'overdue', 'resolved'
  final String types; // 'complaint,feedback' or specific
  final TicketMetaModel meta;
  final List<LookupBranchModel> branches;
  final String searchQuery;
  final String categoryFilter;
  final String mineFilter;
  final bool isLoading;
  final String? errorMessage;

  const SourceComplaintsLoadedState({
    required this.source,
    required this.items,
    required this.counts,
    this.statusTab = 'everything',
    this.types = 'complaint,feedback',
    this.meta = const TicketMetaModel(),
    this.branches = const [],
    this.searchQuery = '',
    this.categoryFilter = 'All categories',
    this.mineFilter = '',
    this.isLoading = false,
    this.errorMessage,
  });

  SourceComplaintsLoadedState copyWith({
    String? source,
    List<TicketItemModel>? items,
    TicketCountsModel? counts,
    String? statusTab,
    String? types,
    TicketMetaModel? meta,
    List<LookupBranchModel>? branches,
    String? searchQuery,
    String? categoryFilter,
    String? mineFilter,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SourceComplaintsLoadedState(
      source: source ?? this.source,
      items: items ?? this.items,
      counts: counts ?? this.counts,
      statusTab: statusTab ?? this.statusTab,
      types: types ?? this.types,
      meta: meta ?? this.meta,
      branches: branches ?? this.branches,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      mineFilter: mineFilter ?? this.mineFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        source,
        items,
        counts,
        statusTab,
        types,
        meta,
        branches,
        searchQuery,
        categoryFilter,
        mineFilter,
        isLoading,
        errorMessage,
      ];
}

class TicketDetailsLoadedState extends ComplaintsState {
  final TicketItemModel ticket;
  final bool isLoading;
  final String? errorMessage;

  const TicketDetailsLoadedState({
    required this.ticket,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [ticket, isLoading, errorMessage];
}

class TicketActionSuccessState extends ComplaintsState {
  final String action; // 'assign', 'resolve', 'reject', 'update'
  final TicketItemModel ticket;
  final String message;

  const TicketActionSuccessState({
    required this.action,
    required this.ticket,
    required this.message,
  });

  @override
  List<Object?> get props => [action, ticket, message];
}

class AppreciationsLoadedState extends ComplaintsState {
  final List<TicketItemModel> items;
  final TicketCountsModel counts;
  final TicketMetaModel meta;
  final List<LookupBranchModel> branches;
  final String searchQuery;
  final String categoryFilter;
  final String mineFilter;
  final bool isLoading;
  final String? errorMessage;

  const AppreciationsLoadedState({
    required this.items,
    required this.counts,
    this.meta = const TicketMetaModel(),
    this.branches = const [],
    this.searchQuery = '',
    this.categoryFilter = 'All categories',
    this.mineFilter = '',
    this.isLoading = false,
    this.errorMessage,
  });

  AppreciationsLoadedState copyWith({
    List<TicketItemModel>? items,
    TicketCountsModel? counts,
    TicketMetaModel? meta,
    List<LookupBranchModel>? branches,
    String? searchQuery,
    String? categoryFilter,
    String? mineFilter,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AppreciationsLoadedState(
      items: items ?? this.items,
      counts: counts ?? this.counts,
      meta: meta ?? this.meta,
      branches: branches ?? this.branches,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      mineFilter: mineFilter ?? this.mineFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        items,
        counts,
        meta,
        branches,
        searchQuery,
        categoryFilter,
        mineFilter,
        isLoading,
        errorMessage,
      ];
}


