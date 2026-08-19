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
  static const String branches = '$baseUrl/lookups/branches';
  static const String scheduleMy = '$baseUrl/schedule/my';
}

