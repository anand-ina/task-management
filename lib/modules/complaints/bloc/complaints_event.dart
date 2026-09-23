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

class FetchComplaintsDashboardEvent extends ComplaintsEvent {
  final int? year;
  final int? branchId;

  const FetchComplaintsDashboardEvent({this.year, this.branchId});

  @override
  List<Object?> get props => [year, branchId];
}

class FetchSourceComplaintsEvent extends ComplaintsEvent {
  final String source; // 'parent' or 'student'
  final String statusTab; // 'everything', 'open', 'overdue', 'resolved'
  final String types; // 'complaint,feedback' or specific
  final String? category;
  final String? mine;
  final String? searchQuery;
  final int? branchId;

  const FetchSourceComplaintsEvent({
    required this.source,
    this.statusTab = 'everything',
    this.types = 'complaint,feedback',
    this.category,
    this.mine,
    this.searchQuery,
    this.branchId,
  });

  @override
  List<Object?> get props => [source, statusTab, types, category, mine, searchQuery, branchId];
}

class GetTicketDetailsEvent extends ComplaintsEvent {
  final int ticketId;

  const GetTicketDetailsEvent(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

class AssignTicketEvent extends ComplaintsEvent {
  final int ticketId;
  final List<int> assigneeIds;
  final String note;

  const AssignTicketEvent({
    required this.ticketId,
    required this.assigneeIds,
    required this.note,
  });

  @override
  List<Object?> get props => [ticketId, assigneeIds, note];
}

class ResolveTicketEvent extends ComplaintsEvent {
  final int ticketId;
  final String resolution;
  final bool notifyParent;

  const ResolveTicketEvent({
    required this.ticketId,
    required this.resolution,
    this.notifyParent = false,
  });

  @override
  List<Object?> get props => [ticketId, resolution, notifyParent];
}

class RejectTicketEvent extends ComplaintsEvent {
  final int ticketId;
  final String reason;

  const RejectTicketEvent({
    required this.ticketId,
    required this.reason,
  });

  @override
  List<Object?> get props => [ticketId, reason];
}

class UpdateTicketEvent extends ComplaintsEvent {
  final int ticketId;
  final Map<String, dynamic> data;

  const UpdateTicketEvent({
    required this.ticketId,
    required this.data,
  });

  @override
  List<Object?> get props => [ticketId, data];
}

class FetchAppreciationsEvent extends ComplaintsEvent {
  final String? category;
  final String? mine;
  final String? searchQuery;
  final int? branchId;
  final String? source;

  const FetchAppreciationsEvent({
    this.category,
    this.mine,
    this.searchQuery,
    this.branchId,
    this.source,
  });

  @override
  List<Object?> get props => [category, mine, searchQuery, branchId, source];
}

class AwardTicketEvent extends ComplaintsEvent {
  final int ticketId;
  final int userId;
  final int points;
  final String reason;

  const AwardTicketEvent({
    required this.ticketId,
    required this.userId,
    required this.points,
    required this.reason,
  });

  @override
  List<Object?> get props => [ticketId, userId, points, reason];
}


