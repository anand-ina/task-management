import 'package:equatable/equatable.dart';
import '../models/batch_ticket_response.dart';
import '../models/lookup_models.dart';
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
