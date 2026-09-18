import 'package:equatable/equatable.dart';
import '../models/batch_ticket_request.dart';
import '../models/create_ticket_request.dart';

abstract class ComplaintsEvent extends Equatable {
  const ComplaintsEvent();

  @override
  List<Object?> get props => [];
}

class FetchComplaintsEvent extends ComplaintsEvent {
  final String statusTab; // 'open', 'overdue', 'resolved', 'all', 'new', 'in_progress', 'pending_reward'
  final String? type;
  final String? source;
  final String? category;
  final String? mine;
  final String? searchQuery;
  final int? branchId;

  const FetchComplaintsEvent({
    this.statusTab = 'open',
    this.type,
    this.source,
    this.category,
    this.mine,
    this.searchQuery,
    this.branchId,
  });

  @override
  List<Object?> get props => [statusTab, type, source, category, mine, searchQuery, branchId];
}

class SearchComplaintsEvent extends ComplaintsEvent {
  final String query;

  const SearchComplaintsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterComplaintsEvent extends ComplaintsEvent {
  final String? typeFilter;
  final String? sourceFilter;
  final String? categoryFilter;
  final String? ownerFilter;

  const FilterComplaintsEvent({
    this.typeFilter,
    this.sourceFilter,
    this.categoryFilter,
    this.ownerFilter,
  });

  @override
  List<Object?> get props => [typeFilter, sourceFilter, categoryFilter, ownerFilter];
}

class LoadRaiseRequestMetaEvent extends ComplaintsEvent {
  final int? branchId;

  const LoadRaiseRequestMetaEvent({this.branchId});

  @override
  List<Object?> get props => [branchId];
}

class CreateComplaintEvent extends ComplaintsEvent {
  final CreateTicketRequest request;

  const CreateComplaintEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class SubmitSuggestionBoxBatchEvent extends ComplaintsEvent {
  final BatchTicketRequest request;

  const SubmitSuggestionBoxBatchEvent(this.request);

  @override
  List<Object?> get props => [request];
}

