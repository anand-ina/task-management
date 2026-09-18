import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/ticket_model.dart';
import '../repository/complaints_repository.dart';
import 'complaints_event.dart';
import 'complaints_state.dart';

class ComplaintsBloc extends Bloc<ComplaintsEvent, ComplaintsState> {
  final ComplaintsRepository _repository;

  ComplaintsBloc({ComplaintsRepository? repository})
      : _repository = repository ?? ComplaintsRepository(),
        super(ComplaintsInitialState()) {
    on<FetchComplaintsEvent>(_onFetchComplaints);
    on<SearchComplaintsEvent>(_onSearchComplaints);
    on<FilterComplaintsEvent>(_onFilterComplaints);
    on<LoadRaiseRequestMetaEvent>(_onLoadRaiseRequestMeta);
    on<CreateComplaintEvent>(_onCreateComplaint);
    on<SubmitSuggestionBoxBatchEvent>(_onSubmitSuggestionBoxBatch);
  }

  List<TicketItemModel> _applyFilters({
    required List<TicketItemModel> items,
    required String query,
    required String typeFilter,
    required String sourceFilter,
    required String categoryFilter,
    required String ownerFilter,
  }) {
    return items.where((ticket) {
      // Query filter
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final matchesTicketNo = ticket.ticketNo.toLowerCase().contains(q);
        final matchesStudent = (ticket.studentName ?? '').toLowerCase().contains(q);
        final matchesParent = (ticket.parentName ?? '').toLowerCase().contains(q);
        final matchesStaff = (ticket.ownerName ?? '').toLowerCase().contains(q) ||
            (ticket.aboutUserName ?? '').toLowerCase().contains(q);
        final matchesDesc = ticket.description.toLowerCase().contains(q);

        if (!matchesTicketNo && !matchesStudent && !matchesParent && !matchesStaff && !matchesDesc) {
          return false;
        }
      }

      // Type filter
      if (typeFilter != 'All types' && typeFilter.isNotEmpty) {
        if (ticket.type.toLowerCase() != typeFilter.toLowerCase()) {
          return false;
        }
      }

      // Source filter
      if (sourceFilter != 'Parents & students' && sourceFilter.isNotEmpty) {
        if (ticket.source.toLowerCase() != sourceFilter.toLowerCase()) {
          return false;
        }
      }

      // Category filter
      if (categoryFilter != 'All categories' && categoryFilter.isNotEmpty) {
        if (ticket.category.toLowerCase() != categoryFilter.toLowerCase()) {
          return false;
        }
      }

      // Owner filter
      if (ownerFilter != "Everyone's" && ownerFilter.isNotEmpty) {
        if ((ticket.ownerName ?? '').toLowerCase() != ownerFilter.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _onFetchComplaints(
    FetchComplaintsEvent event,
    Emitter<ComplaintsState> emit,
  ) async {
    ComplaintsLoadedState? currentState;
    if (state is ComplaintsLoadedState) {
      currentState = state as ComplaintsLoadedState;
    } else {
      emit(ComplaintsLoadingState());
    }

    try {
      final currentType = event.type ?? currentState?.typeFilter ?? 'All types';
      final currentSource = event.source ?? currentState?.sourceFilter ?? 'Parents & students';
      final currentCategory = event.category ?? currentState?.categoryFilter ?? 'All categories';
      final currentOwner = currentState?.ownerFilter ?? "Everyone's";
      final currentMine = event.mine ?? currentState?.mineFilter ?? '';
      final currentQuery = event.searchQuery ?? currentState?.searchQuery ?? '';

      // Normalize filters for backend query parameters
      String? apiType;
      if (currentType != 'All types' && currentType.isNotEmpty) {
        final t = currentType.toLowerCase();
        if (t.contains('complaint')) {
          apiType = 'complaint';
        } else if (t.contains('feedback')) {
          apiType = 'feedback';
        } else if (t.contains('appreciation')) {
          apiType = 'appreciation';
        } else {
          apiType = t;
        }
      }

      String? apiSource;
      if (currentSource != 'Parents & students' && currentSource.isNotEmpty) {
        final s = currentSource.toLowerCase();
        if (s.contains('parent')) {
          apiSource = 'parent';
        } else if (s.contains('student')) {
          apiSource = 'student';
        } else {
          apiSource = s;
        }
      }

      String? apiCategory;
      if (currentCategory != 'All categories' && currentCategory.isNotEmpty) {
        apiCategory = currentCategory;
      }

      String? apiMine;
      if (currentMine.isNotEmpty && currentMine != "Everyone's") {
        if (currentMine == 'owned' || currentMine.toLowerCase().contains('received')) {
          apiMine = 'owned';
        } else if (currentMine == 'raised' || currentMine.toLowerCase().contains('assigned')) {
          apiMine = 'raised';
        } else {
          apiMine = currentMine;
        }
      }

      final ticketResponse = await _repository.getTickets(
        status: event.statusTab,
        type: apiType,
        source: apiSource,
        category: apiCategory,
        mine: apiMine,
        q: currentQuery,
        branchId: event.branchId,
      );

      final meta = currentState?.meta.categories.isNotEmpty == true
          ? currentState!.meta
          : await _repository.getTicketMeta(branchId: event.branchId);

      final departments = currentState?.departments.isNotEmpty == true
          ? currentState!.departments
          : await _repository.getDepartments();

      final branches = currentState?.branches.isNotEmpty == true
          ? currentState!.branches
          : await _repository.getBranches();

      final assignees = currentState?.assignees.isNotEmpty == true
          ? currentState!.assignees
          : await _repository.getAssignees();

      final filtered = _applyFilters(
        items: ticketResponse.items,
        query: currentQuery,
        typeFilter: currentType,
        sourceFilter: currentSource,
        categoryFilter: currentCategory,
        ownerFilter: currentOwner,
      );

      emit(ComplaintsLoadedState(
        allItems: ticketResponse.items,
        filteredItems: filtered,
        counts: ticketResponse.counts,
        statusTab: event.statusTab,
        meta: meta,
        departments: departments,
        branches: branches,
        assignees: assignees,
        searchQuery: currentQuery,
        typeFilter: currentType,
        sourceFilter: currentSource,
        categoryFilter: currentCategory,
        ownerFilter: currentOwner,
        mineFilter: currentMine,
        isSubmitting: false,
        submittedTicket: null,
      ));
    } catch (e) {
      if (currentState != null) {
        emit(currentState.copyWith(errorMessage: e.toString()));
      } else {
        emit(ComplaintsErrorState(e.toString()));
      }
    }
  }

  void _onSearchComplaints(
    SearchComplaintsEvent event,
    Emitter<ComplaintsState> emit,
  ) {
    if (state is! ComplaintsLoadedState) return;
    final s = state as ComplaintsLoadedState;
    final filtered = _applyFilters(
      items: s.allItems,
      query: event.query,
      typeFilter: s.typeFilter,
      sourceFilter: s.sourceFilter,
      categoryFilter: s.categoryFilter,
      ownerFilter: s.ownerFilter,
    );
    emit(s.copyWith(searchQuery: event.query, filteredItems: filtered));
  }

  void _onFilterComplaints(
    FilterComplaintsEvent event,
    Emitter<ComplaintsState> emit,
  ) {
    if (state is! ComplaintsLoadedState) return;
    final s = state as ComplaintsLoadedState;
    final newType = event.typeFilter ?? s.typeFilter;
    final newSource = event.sourceFilter ?? s.sourceFilter;
    final newCategory = event.categoryFilter ?? s.categoryFilter;
    final newOwner = event.ownerFilter ?? s.ownerFilter;

    final filtered = _applyFilters(
      items: s.allItems,
      query: s.searchQuery,
      typeFilter: newType,
      sourceFilter: newSource,
      categoryFilter: newCategory,
      ownerFilter: newOwner,
    );

    emit(s.copyWith(
      typeFilter: newType,
      sourceFilter: newSource,
      categoryFilter: newCategory,
      ownerFilter: newOwner,
      filteredItems: filtered,
    ));
  }

  Future<void> _onLoadRaiseRequestMeta(
    LoadRaiseRequestMetaEvent event,
    Emitter<ComplaintsState> emit,
  ) async {
    if (state is! ComplaintsLoadedState) return;
    final s = state as ComplaintsLoadedState;
    try {
      final updatedMeta = await _repository.getTicketMeta(branchId: event.branchId);
      emit(s.copyWith(meta: updatedMeta));
    } catch (e) {
      // Keep existing meta on error
    }
  }

  Future<void> _onCreateComplaint(
    CreateComplaintEvent event,
    Emitter<ComplaintsState> emit,
  ) async {
    if (state is! ComplaintsLoadedState) return;
    final s = state as ComplaintsLoadedState;
    emit(s.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final newTicket = await _repository.createTicket(event.request);
      // Refresh complaints list
      final ticketResponse = await _repository.getTickets(status: s.statusTab);

      final filtered = _applyFilters(
        items: ticketResponse.items,
        query: s.searchQuery,
        typeFilter: s.typeFilter,
        sourceFilter: s.sourceFilter,
        categoryFilter: s.categoryFilter,
        ownerFilter: s.ownerFilter,
      );

      emit(s.copyWith(
        allItems: ticketResponse.items,
        filteredItems: filtered,
        counts: ticketResponse.counts,
        isSubmitting: false,
        submittedTicket: newTicket,
      ));
    } catch (e) {
      emit(s.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onSubmitSuggestionBoxBatch(
    SubmitSuggestionBoxBatchEvent event,
    Emitter<ComplaintsState> emit,
  ) async {
    if (state is! ComplaintsLoadedState) return;
    final s = state as ComplaintsLoadedState;
    emit(s.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final response = await _repository.createBatchTickets(event.request);
      // Refresh complaints list
      final ticketResponse = await _repository.getTickets(status: s.statusTab);

      final filtered = _applyFilters(
        items: ticketResponse.items,
        query: s.searchQuery,
        typeFilter: s.typeFilter,
        sourceFilter: s.sourceFilter,
        categoryFilter: s.categoryFilter,
        ownerFilter: s.ownerFilter,
      );

      emit(s.copyWith(
        allItems: ticketResponse.items,
        filteredItems: filtered,
        counts: ticketResponse.counts,
        isSubmitting: false,
        batchCreatedResponse: response,
      ));
    } catch (e) {
      emit(s.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }
}
