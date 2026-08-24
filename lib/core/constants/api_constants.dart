class ApiConstants {
  static const String baseUrl = 'https://dev-task-api.srivyn.in/api';

  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';

  // Dashboard & App Endpoints
  static const String notifications = '$baseUrl/notifications';
  static const String dashboard = '$baseUrl/dashboard';
  static const String dashboardTeam = '$baseUrl/dashboard/team';
  static const String todos = '$baseUrl/todos';
  static const String todosToday = '$baseUrl/todos/today';
  static const String branches = '$baseUrl/lookups/branches';
  static const String assignees = '$baseUrl/lookups/assignees';
  static const String enums = '$baseUrl/lookups/enums';
  static const String scheduleMy = '$baseUrl/schedule/my';
  static const String tasks = '$baseUrl/tasks';
  static const String tasksBulk = '$baseUrl/tasks/bulk';
  static const String bulkTasksTemplate = '$baseUrl/bulk/tasks/template';
  static const String bulkTasksPreview = '$baseUrl/bulk/tasks/preview';
  static const String bulkTasksCommit = '$baseUrl/bulk/tasks/commit';
  static const String recurring = '$baseUrl/recurring';
  static const String oneOnOnePending = '$baseUrl/meetings/one-on-one/pending';
  static const String meetings = '$baseUrl/meetings';
  static const String meetingsAvailability = '$baseUrl/meetings/availability';
  static const String sutraCommand = '$baseUrl/sutra/command';

  // Approvals & Escalations Endpoints
  static const String approvals = '$baseUrl/approvals';
  static const String approvalsInitiated = '$baseUrl/approvals/initiated';
  static const String escalationsToReview = '$baseUrl/escalations/to-review';
  static const String escalations = '$baseUrl/escalations';
  static const String meetingCompletionRequests = '$baseUrl/meetings/completion-requests';
  static const String budgetReceived = '$baseUrl/budget/received';
  static const String budgetInitiated = '$baseUrl/budget/initiated';

  // Events & Reports Endpoints
  static const String events = '$baseUrl/events';
  static const String reports = '$baseUrl/reports';
  static const String reportsStats = '$baseUrl/reports/stats';
  static const String reportsCompliance = '$baseUrl/reports/compliance';

  // To-Do History & Performance Endpoints
  static const String todosHistory = '$baseUrl/todos';
  static const String performanceLeaderboard = '$baseUrl/performance/leaderboard';
  static const String performanceLedger = '$baseUrl/performance/ledger';
  static const String performanceMe = '$baseUrl/performance/me';
  static const String teamPerformance = '$baseUrl/dashboard/team-performance';

  // Fines & Staff Endpoints
  static const String fines = '$baseUrl/fines';
  static const String finesTypes = '$baseUrl/fines/types';
  static const String staff = '$baseUrl/staff';
  static const String departments = '$baseUrl/lookups/departments';
  static const String roles = '$baseUrl/lookups/roles';
  static const String notificationPreferences = '$baseUrl/notifications/preferences';
  static const String staffMeProfile = '$baseUrl/staff/me/profile';
}

