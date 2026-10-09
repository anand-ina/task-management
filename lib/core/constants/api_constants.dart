class ApiConstants {
  static const String baseUrl = 'https://dev-task-api.srivyn.in/api';

  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String resetPassword = '$baseUrl/auth/reset-password';

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
  static String meetingRespond(dynamic id) => '$baseUrl/meetings/$id/respond';
  static const String meetingsAvailability = '$baseUrl/meetings/availability';
  static const String googleCalendarAuth = '$baseUrl/auth/google-calendar';
  static const String googleCalendarCallback = '$baseUrl/auth/google-calendar/callback';
  static const String googleCalendarStatus = '$baseUrl/google-calendar/status';
  static const String googleCalendarDisconnect = '$baseUrl/google-calendar/disconnect';
  static const String sutraCommand = '$baseUrl/sutra/command';

  // Announcements Endpoints
  static const String announcementsActive = '$baseUrl/announcements/active';
  static const String announcements = '$baseUrl/announcements';
  static String announcementDetail(int id) => '$baseUrl/announcements/$id';

  // Approvals & Escalations Endpoints
  static const String approvals = '$baseUrl/approvals';
  static const String approvalsInitiated = '$baseUrl/approvals/initiated';
  static const String escalationsToReview = '$baseUrl/escalations/to-review';
  static const String escalations = '$baseUrl/escalations';
  static const String meetingCompletionRequests = '$baseUrl/meetings/completion-requests';
  static const String budgetReceived = '$baseUrl/budget/received';
  static const String budgetInitiated = '$baseUrl/budget/initiated';
  static const String indents = '$baseUrl/indents';
  static const String indentsInbox = '$baseUrl/indents/inbox';
  static const String indentsAll = '$baseUrl/indents/all';
  static String indentDetail(int id) => '$baseUrl/indents/$id';

  // Events & Reports Endpoints
  static const String events = '$baseUrl/events';
  static const String reports = '$baseUrl/reports';
  static const String reportsStats = '$baseUrl/reports/stats';
  static const String reportsCompliance = '$baseUrl/reports/compliance';
  static String reportDetail(int id) => '$baseUrl/reports/$id';

  // Task Next ID
  static const String tasksNextId = '$baseUrl/tasks/next-id';

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

  // Organization & Responsibilities Endpoints
  static const String orgChart = '$baseUrl/org/chart';
  static const String orgMyReporting = '$baseUrl/org/my-reporting';
  static const String responsibilities = '$baseUrl/responsibilities';
  static const String adminAudit = '$baseUrl/admin/audit';
  static const String adminBranches = '$baseUrl/admin/branches';
  static const String adminDepartments = '$baseUrl/admin/departments';
  static const String adminReporting = '$baseUrl/admin/reporting';
  static const String adminRoles = '$baseUrl/admin/roles';
  static const String adminTaskCounter = '$baseUrl/admin/task-counter';
  static const String adminTaskCounterReset = '$baseUrl/v1/admin/task-counter/reset';
  static String taskReview(int taskId) => '$baseUrl/tasks/$taskId/review';

  // Complaints & Tickets Endpoints
  static const String tickets = '$baseUrl/tickets';
  static const String ticketSettings = '$baseUrl/tickets/settings';
  static const String ticketMeta = '$baseUrl/tickets/meta';
  static const String ticketBatch = '$baseUrl/tickets/batch';
  static const String ticketInsights = '$baseUrl/tickets/insights';
  static const String uploads = '$baseUrl/uploads';
  static String ticketMetaBranch(int branchId) => '$baseUrl/tickets/meta?branchId=$branchId';
  static String ticketAward(int ticketId) => '$baseUrl/tickets/$ticketId/award';

  // Drafts Endpoints
  static const String drafts = '$baseUrl/drafts';
  static String draftDetail(int id) => '$baseUrl/drafts/$id';

  // Audits Endpoints
  static const String audits = '$baseUrl/audits';
  static const String auditsMeta = '$baseUrl/audits/meta';
  static const String auditsAsAuditee = '$baseUrl/audits/as-auditee';
  static const String auditsAsAuditor = '$baseUrl/audits/as-auditor';
  static String auditDetail(int id) => '$baseUrl/audits/$id';
  static String closeAudit(int id) => '$baseUrl/audits/$id/close';

  // Hourly Log Endpoints
  static const String hourlyLog = '$baseUrl/hourly-log';
  static const String hourlyLogItems = '$baseUrl/hourly-log/items';
  static String hourlyLogItemDetail(int id) => '$baseUrl/hourly-log/items/$id';
  static const String hourlyLogSubmit = '$baseUrl/hourly-log/submit';
}

