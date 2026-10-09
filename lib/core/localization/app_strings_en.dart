import 'app_strings.dart';

class AppStringsEn extends AppStrings {
  @override
  String get appTitle => 'Samskar Task Manager';
  @override
  String get welcomeBack => 'Welcome back';
  @override
  String get signInToAccount => 'Sign in to your account';
  @override
  String get quickLoginAs => 'Quick Login As';
  @override
  String get credentials => 'Credentials';
  @override
  String get emailLabel => 'Email address';
  @override
  String get passwordLabel => 'Password';
  @override
  String get signInButton => 'Sign In';
  @override
  String get demoPasswordHint => 'Demo password: Samskar@123';

  @override
  String get forgotPasswordTitle => 'Forgot password';
  @override
  String get forgotPasswordSubtitle => 'Enter your email, phone or username. We’ll send a 6-digit reset code by WhatsApp (and email, if set up).';
  @override
  String get emailPhoneOrUsernameLabel => 'Email, phone or username';
  @override
  String get sendResetCodeButton => 'Send reset code';
  @override
  String get backToSignInLink => 'Back to sign in';
  @override
  String get resetCodeSentNotice => 'If that account exists, a reset code is on its way. Enter it on the next screen.';
  @override
  String get enterResetCodeButton => 'Enter reset code';
  @override
  String get resetPasswordTitle => 'Reset password';
  @override
  String get resetPasswordSubtitle => 'Enter the 6-digit code you received and choose a new password.';
  @override
  String get resetCodeLabel => 'Reset code';
  @override
  String get resetCodeHint => '6-digit code';
  @override
  String get newPasswordLabel => 'New password';
  @override
  String get newPasswordHint => 'min 8 chars, a letter and a number';
  @override
  String get confirmNewPasswordLabel => 'Confirm new password';
  @override
  String get resetPasswordButton => 'Reset password';


  @override
  String get dashboard => 'Dashboard';
  @override
  String get organizationOverview => 'Organization Overview';
  @override
  String get campusOverview => 'Campus Overview';
  @override
  String get tasksHeader => 'TASKS';
  @override
  String get allTasks => 'All Tasks';
  @override
  String get myTasks => 'My Tasks';
  @override
  String get recurringTasks => 'Recurring Tasks';
  @override
  String get approvalsHeader => 'APPROVALS';
  @override
  String get taskApprovals => 'Task Approvals';
  @override
  String get escalations => 'Escalations';
  @override
  String get meetingApprovals => 'Meeting Approvals';
  @override
  String get budgetApprovals => 'Budget Approvals';
  @override
  String get meetingsHeader => 'MEETINGS';
  @override
  String get monthlyOneOnOnePending => 'Monthly 1:1 Pending';
  @override
  String get myScheduledMeetings => 'My Scheduled Meetings';
  @override
  String get meetingCalendar => 'Meeting Calendar';
  @override
  String get eventsHeader => 'EVENTS';
  @override
  String get events => 'Events';
  @override
  String get eventsCalendar => 'Events Calendar';
  @override
  String get reportsHeader => 'REPORTS';
  @override
  String get statusReports => 'Status Reports';
  @override
  String get reportsDashboard => 'Reports Dashboard';
  @override
  String get todoHeader => 'TO-DO';
  @override
  String get today => 'Today';
  @override
  String get history => 'History';
  @override
  String get performanceHeader => 'PERFORMANCE';
  @override
  String get leaderboard => 'Leaderboard';
  @override
  String get teamPerformance => 'Team Performance';
  @override
  String get finesAndRewards => 'Fines & Rewards';
  @override
  String get settings => 'Settings';
  @override
  String get organizationHeader => 'ORGANIZATION';
  @override
  String get staff => 'Staff';
  @override
  String get administrationHeader => 'ADMINISTRATION';
  @override
  String get userManagement => 'User Management';
  @override
  String get branchesAndDepartments => 'Branches & Departments';
  @override
  String get reportingStructure => 'Reporting Structure';
  @override
  String get rolesAndPermissions => 'Roles & Permissions';
  @override
  String get auditLog => 'Audit Log';
  @override
  String get administratorRole => 'Administrator';
  @override
  String get administratorBadgeScope => 'Full organization view — every campus & department.';
  @override
  String get branchesAndDepartmentsSubtitle => 'Add and rename branches and departments, and see the users linked to each. Used across every login.';
  @override
  String get branchesHeader => 'Branches';
  @override
  String get departmentsHeader => 'Departments';
  @override
  String get codePlaceholder => 'Code';
  @override
  String get branchNamePlaceholder => 'Branch name';
  @override
  String get newDepartmentPlaceholder => 'New department';
  @override
  String get editButton => 'Edit';
  @override
  String get saveButton => 'Save';
  @override
  String get cancelEditButton => 'Cancel';
  @override
  String get reportingStructureSubtitle => 'Who reports to whom across the organisation';
  @override
  String get personColumn => 'PERSON';
  @override
  String get reportsToColumn => 'REPORTS TO (PRIMARY)';
  @override
  String get dottedLineColumn => 'DOTTED-LINE (SECONDARY)';
  @override
  String get addManagerLabel => '+ add manager...';
  @override
  String get addDottedLabel => '+ add dotted...';
  @override
  String get noReportingDataFound => 'No reporting structure data found.';
  @override
  String get rolesAndPermissionsSubtitle => 'Define what each role can see and do';
  @override
  String get addRoleButton => '+ Add Role';
  @override
  String rolesCount(int count) => '$count roles';
  @override
  String get levelLabel => 'Level';
  @override
  String get permissionsLabel => 'permissions';
  @override
  String get usersLabel => 'users';
  @override
  String get savePermissionsButton => 'Save permissions';
  @override
  String get addRoleTitle => 'Add New Role';
  @override
  String get roleLabelField => 'Role Label (display name)';
  @override
  String get roleKeyField => 'Role Key (system name)';
  @override
  String get roleLevelField => 'Level (1–5)';
  @override
  String get noRolesFound => 'No roles found.';

  // Role Badges
  @override
  String get academicExecutiveRole => 'Academic Executive';
  @override
  String get academicExecutiveScope => 'Operational scope — your own tasks & reports.';

  // New Drawer Headers & Nav Items
  @override
  String get adminOrgChart => 'Admin Org Chart';
  @override
  String get myReportingStructure => 'My Reporting Structure';
  @override
  String get rolesAndResponsibilitiesHeader => 'ROLES & RESPONSIBILITIES';
  @override
  String get myResponsibilities => 'My Responsibilities';
  @override
  String get myAuditsHeader => 'MY AUDITS';
  @override
  String get asAnInternalAuditor => 'As an Internal Auditor';
  @override
  String get asAnAuditee => 'As an Auditee';

  // Admin Org Chart Screen
  @override
  String get adminOrgChartSubtitle => "The Administration team's reporting structure — mirrored from the published org chart.";
  @override
  String peopleCount(int count) => '$count people';
  @override
  String get primaryReportingLegend => 'Primary reporting (solid)';
  @override
  String get secondaryReportingLegend => 'Secondary / dotted line';
  @override
  String get reportsToPrefix => 'reports to';
  @override
  String get dottedPrefix => 'dotted:';
  @override
  String get youBadge => 'You';
  @override
  String get noOrgChartDataFound => 'No organization chart data found.';

  // My Reporting Structure Screen
  @override
  String get myReportingSubtitle => 'Who you report to, and who reports to you.';
  @override
  String get meSectionTitle => 'Me';
  @override
  String get iReportToSectionTitle => 'I report to';
  @override
  String get reportsToMeSectionTitle => 'Reports to me';
  @override
  String get peersSectionTitle => 'Peers';
  @override
  String get shareManagerSubtitle => 'share a manager';
  @override
  String get primarySolidLegend => 'primary (solid)';
  @override
  String get secondaryDottedLegend => 'secondary (dotted)';
  @override
  String get noneText => 'None.';
  @override
  String get noReportingStructureFound => 'No reporting structure found.';

  // My Responsibilities Screen
  @override
  String get myResponsibilitiesSubtitle => 'Your primary and secondary areas of responsibility.';
  @override
  String get primaryResponsibilitiesTitle => 'Primary';
  @override
  String get secondaryResponsibilitiesTitle => 'Secondary';
  @override
  String get addPrimaryResponsibilityPlaceholder => 'Add a primary responsibility...';
  @override
  String get addSecondaryResponsibilityPlaceholder => 'Add a secondary responsibility...';
  @override
  String get noneYetText => 'None yet.';
  @override
  String get noResponsibilitiesFound => 'No responsibilities found.';

  // My Audits Screens
  @override
  String get auditsAuditeeTitle => 'My Audits — As an Auditee';
  @override
  String get auditsAuditeeSubtitle => 'Audits carried out on you, your department or branch. Respond to findings and mark them resolved.';
  @override
  String get noAuditsInvolveYouYet => 'No audits involve you yet.';
  @override
  String get auditsAuditorTitle => 'My Audits — As an Internal Auditor';
  @override
  String get auditsAuditorSubtitle => 'Audits you are conducting or participating in.';
  @override
  String get noAuditsAssignedYet => 'No audits assigned to you yet.';

  // Audit Log Screen
  @override
  String get auditLogSubtitle => 'User created, password changes and login / logout activity.';
  @override
  String get allActivityFilter => 'All activity';
  @override
  String get loginAction => 'Login';
  @override
  String get logoutAction => 'Logout';
  @override
  String get passwordChangedAction => 'Password changed';
  @override
  String get noAuditLogsFound => 'No audit logs found.';

  // Calendar Navigation
  @override
  String get previousMonth => 'Previous Month';
  @override
  String get nextMonth => 'Next Month';

  @override
  String get aiAndSettingsHeader => 'AI & SETTINGS';
  @override
  String get sutraAi => 'Sūtra AI';
  @override
  String get myPreferences => 'My Preferences';
  @override
  String get directorBadgeScope => 'Full organization view — every campus & department.';

  @override
  String get searchPlaceholder => 'Search tasks, people, reports...';
  @override
  String get newButton => '+ New';
  @override
  String get newTask => 'New Task';
  @override
  String get newTodo => 'New To-Do';
  @override
  String get newMeeting => 'New Meeting';
  @override
  String get newEvent => 'New Event';
  @override
  String get raiseRequest => 'Raise Request';
  @override
  String get allBranches => 'All Branches';
  @override
  String get directorRole => 'Director';
  @override
  String get myProfile => 'My Profile';
  @override
  String get faq => 'FAQ';
  @override
  String get logout => 'Logout';

  @override
  String get directorHeadOffice => 'DIRECTOR · HEAD OFFICE';
  @override
  String get greetingNamaste => 'Namaste, Vamsi 🙏';
  @override
  String get dashboardSubtitle => 'Full organization overview across every campus & department.';
  @override
  String approvalsBadge(int count) => '$count approvals';
  @override
  String toReviewBadge(int count) => '$count to review';
  @override
  String toStartBadge(int count) => '$count to start';
  @override
  String inProgressBadge(int count) => '$count in progress';
  @override
  String overdueBadge(int count) => '$count overdue';
  @override
  String completionBadge(int rate) => '$rate% completion';

  @override
  String get performanceTitle => 'My Performance';
  @override
  String get performanceSubtitle => 'Completion by period · FY runs Jun–May';
  @override
  String get dayWise => 'Day-wise';
  @override
  String get weekWise => 'Week-wise';
  @override
  String get monthWise => 'Month-wise';
  @override
  String get quarterly => 'Quarterly';
  @override
  String get yearly => 'Yearly';

  @override
  String get tasksByPriority => 'My Tasks by Priority';
  @override
  String get emergencyPriority => 'Emergency';
  @override
  String get topMostPriority => 'Top Most';
  @override
  String get highPriority => 'High';
  @override
  String get mediumPriority => 'Medium';
  @override
  String get lowPriority => 'Low';

  @override
  String get totalOrganisation => 'Total Organisation';
  @override
  String get readOnlyTransparency => 'READ-ONLY TRANSPARENCY';
  @override
  String get totalTasks => 'Total Tasks';
  @override
  String get completed => 'Completed';
  @override
  String get inProgress => 'In Progress';
  @override
  String get overdue => 'Overdue';
  @override
  String get dropped => 'Dropped';

  @override
  String get recentActivityTitle => 'Recent Activity';
  @override
  String get teamLoginAnalyticsTitle => 'Team Login Analytics';
  @override
  String get activeToday => 'Active today';
  @override
  String get daysAway1To3 => '1–3 days away';
  @override
  String get daysAway4To6 => '4–6 days away';
  @override
  String get daysAway7Plus => '7+ days away';
  @override
  String get neverSignedIn => 'Never signed in';

  @override
  String get todoTodayTitle => 'To-Do Today';
  @override
  String get todoTodaySubtitle => 'Manage your focus tasks for today';
  @override
  String get reviewPendingApprovals => 'Review pending task approvals';
  @override
  String get checkScheduledMeetings => 'Check scheduled meetings for the week';
  @override
  String get addNotePlaceholder => 'Add a quick note or task...';
  @override
  String get addButton => 'Add';

  @override
  String get appearance => 'Appearance';
  @override
  String get appearanceSubtitle => 'Customize application theme';
  @override
  String get themeMode => 'Theme Mode';
  @override
  String get themeLight => 'Light Mode';
  @override
  String get themeDark => 'Dark Mode';
  @override
  String get themeSystem => 'System Theme';
  @override
  String get language => 'Language';
  @override
  String get languageSubtitle => 'Choose application display language';
  @override
  String get langEnglish => 'English';
  @override
  String get langTelugu => 'తెలుగు (Telugu)';
  @override
  String get langHindi => 'हिंदी (Hindi)';
  @override
  String get langKannada => 'ಕನ್ನಡ (Kannada)';

  @override
  String get toBeStarted => 'To be Started';
  @override
  String get workUnderway => 'Work underway';
  @override
  String get needsAttention => 'Needs attention';
  @override
  String get notYetPickedUp => 'Not yet picked up';
  @override
  String get closedWithoutCompletion => 'Closed without completion';

  @override
  String get actionCenterTitle => 'ACTION CENTER';
  @override
  String get clickRowToOpen => 'CLICK A ROW TO OPEN';
  @override
  String get approvalsToReview => 'Approvals to review';
  @override
  String get overdueTasks => 'Overdue tasks';
  @override
  String get dueToday => 'Due today';
  @override
  String get emergencyHighOpen => 'Emergency + High (open)';

  @override
  String get noMeetingsScheduled => 'Nothing scheduled today.';

  @override
  String get myLoginActivityTitle => 'MY LOGIN ACTIVITY';
  @override
  String get loginsToday => 'Logins today';
  @override
  String get loginsThisWeek => 'Logins this week';
  @override
  String get activeTodaySpan => 'Active today (first->last)';
  @override
  String get activeThisWeekSpan => 'Active this week';
  @override
  String get firstLoginToday => 'First login today';
  @override
  String get activeDays => 'Active days';
  @override
  String get lastLoginLabel => 'Last login';
  @override
  String get activeSpanNotice => '"Active" = span from your first to last sign-in.';

  @override
  String get overdueTasksByAgeTitle => 'OVERDUE TASKS BY AGE';
  @override
  String get overdueTasksByAgeSubtitle =>
      'Open overdue tasks grouped by how late they are · click a bar for the list';
  @override
  String get days1To3 => '1–3 days';
  @override
  String get days4To7 => '4–7 days';
  @override
  String get days8To14 => '8–14 days';
  @override
  String get days15Plus => '15+ days';

  @override
  String get myTeam => 'My Team';
  @override
  String get membersLabel => 'members';
  @override
  String get teamWide => 'TEAM-WIDE';
  @override
  String get clickRowForDetails => 'CLICK A ROW FOR DETAILS';
  @override
  String get recentActivityDetail => 'RECENT ACTIVITY DETAIL';
  @override
  String get viewTask => 'View task';
  @override
  String get branchLabel => 'Branch';
  @override
  String get dueLabel => 'Due';
  @override
  String get completedLabel => 'Completed';
  @override
  String get clickGroupForMembers => 'CLICK A GROUP FOR MEMBERS';

  @override
  String get noInternetTitle => 'Please Connect to the Internet';
  @override
  String get noInternetMessage =>
      'No internet connection detected. Please connect to Wi-Fi or mobile data to continue.';
  @override
  String forceLogoutNotice(int seconds) =>
      'Please connect to the internet. Forcefully logging out in $seconds seconds...';
  @override
  String get retryButton => 'Retry';
  @override
  String get exitAppTitle => 'Exit Application';
  @override
  String get exitAppMessage => 'Are you sure you want to exit the app?';
  @override
  String get cancelButton => 'Cancel';
  @override
  String get exitButton => 'Exit';

  @override
  String get tasksDueTodayTitle => 'Tasks due today';
  @override
  String get showingRangeText => 'Showing 1–10 of 10';
  @override
  String get sortByLabel => 'Sort by';
  @override
  String get entryDateLabel => 'Entry date';
  @override
  String get branchLegendLabel => 'BRANCH LEGEND';
  @override
  String get taskIdHeader => 'TASK ID';
  @override
  String get descriptionHeader => 'DESCRIPTION';
  @override
  String get branchHeader => 'BRANCH';
  @override
  String get priorityHeader => 'PRIORITY';
  @override
  String get statusHeader => 'STATUS';
  @override
  String get dueHeader => 'DUE';
  @override
  String get assignedByLabel => 'ASSIGNED BY';
  @override
  String get categoryLabel => 'CATEGORY';
  @override
  String get locationLabel => 'LOCATION';
  @override
  String get assigneesLabel => 'ASSIGNEES';
  @override
  String get activityLabel => 'ACTIVITY';
  @override
  String get closeButton => 'Close';

  @override
  String get everyCampusDeptAtAGlance => 'Every campus & department at a glance';
  @override
  String get byBranchUnit => 'By Branch Unit';
  @override
  String get searchBranchPlaceholder => 'Search branch...';
  @override
  String get clickRowOrFilterTopBar => 'Click a row, or filter via the top bar';
  @override
  String get analyticsTitle => 'Analytics';
  @override
  String get exportButton => 'Export';
  @override
  String get organizationWide => 'Organization-wide';
  @override
  String get trendsOverTime => 'TRENDS OVER TIME — CREATED VS. COMPLETED';
  @override
  String get weeklyBucket => 'Weekly';
  @override
  String get monthlyBucket => 'Monthly';
  @override
  String get quarterlyBucket => 'Quarterly';
  @override
  String get yearlyBucket => 'Yearly';
  @override
  String get createdLegend => 'Created';
  @override
  String get completedLegend => 'Completed';
  @override
  String get onTimeCompletionDueWindow => 'ON-TIME COMPLETION (BY DUE WINDOW)';
  @override
  String get taskStatusDistribution => 'TASK STATUS DISTRIBUTION';
  @override
  String get priorityLoadTitle => 'PRIORITY LOAD';
  @override
  String get completionByBranch => 'COMPLETION BY BRANCH';
  @override
  String get workloadByDeadlineOpenTasks => 'WORKLOAD BY DEADLINE (OPEN TASKS)';

  @override
  String get tasksInYourScope => 'tasks in your scope';
  @override
  String get needsAction => 'Needs Action';
  @override
  String get newRecurring => 'New Recurring';
  @override
  String get bulkUpload => 'Bulk Upload';
  @override
  String get exportCsv => 'Export CSV';
  @override
  String get exportExcel => 'Export Excel';
  @override
  String get exportPdf => 'Export PDF';
  @override
  String get bulkUploadTasksTitle => 'Bulk upload tasks';
  @override
  String get bulkUploadSubtitle => 'Excel or CSV · nothing is \n saved until you confirm';
  @override
  String get chooseAFile => 'Choose a file';
  @override
  String get acceptedFormats => 'Accepted: .xlsx, .xls, .csv';
  @override
  String get columnsImporterReads => 'COLUMNS THE IMPORTER READS';
  @override
  String get columnHeader => 'COLUMN HEADER';
  @override
  String get exampleHeader => 'EXAMPLE';
  @override
  String get notesHeader => 'NOTES';
  @override
  String get rowsFound => 'Rows found';
  @override
  String get willImport => 'Will import';
  @override
  String get skippedCount => 'Skipped';
  @override
  String get headerRowLabel => 'Header row';
  @override
  String get previewTitle => 'PREVIEW';
  @override
  String get rowHeader => 'ROW';
  @override
  String get taskHeader => 'TASK';
  @override
  String get assignedToHeader => 'ASSIGNED TO';
  @override
  String get targetHeader => 'TARGET';
  @override
  String get noteHeader => 'NOTE';
  @override
  String get chooseAnotherFile => 'Choose another file';
  @override
  String importTasksCount(int count) => 'Import $count task${count == 1 ? '' : 's'}';
  @override
  String bulkImportSuccess(int count, String taskNos) => 'Successfully imported $count task(s): $taskNos';
  @override
  String get allScope => 'All';
  @override
  String get confidentialScope => 'Confidential';
  @override
  String get generalScope => 'General';
  @override
  String get searchTasksPlaceholder => 'Search tasks...';
  @override
  String get allStatuses => 'All Statuses';
  @override
  String get allPriorities => 'All Priorities';
  @override
  String get selectAllText => 'Select all';

  @override
  String get tasksAssignedToOrCreatedByYou => 'tasks assigned to or created by you';
  @override
  String get repeatingDutiesAutoGenerated => 'Repeating duties — auto-generated\n on schedule';
  @override
  String get dailyFrequency => 'Daily';
  @override
  String get weeklyFrequency => 'Weekly';
  @override
  String get monthlyFrequency => 'Monthly';
  @override
  String get biMonthlyFrequency => 'Bi-Monthly';
  @override
  String get quarterlyFrequency => 'Quarterly';
  @override
  String get halfYearlyFrequency => 'Half-Yearly';
  @override
  String get yearlyFrequency => 'Yearly';
  @override
  String get othersFrequency => 'Others';
  @override
  String get listView => 'List';
  @override
  String get boardView => 'Board';
  @override
  String get calendarView => 'Calendar';

  @override
  String get staffWhoHaventCompletedMandatory => 'Staff who haven\'t completed this \nmonth\'s mandatory 1:1 with you.';
  @override
  String get scheduleOneOnOne => 'Schedule 1:1';
  @override
  String get oneOnOnePendingBadge => '1:1 pending';
  @override
  String get meetingsYouOrganizeOrInvitedTo => 'Meetings you organize or are invited to · DSR/WSR/MSR slots auto-added';
  @override
  String get previewReminder => 'Preview reminder';
  @override
  String get initiatedByMe => 'Initiated by Me';
  @override
  String get receivedByMe => 'Received by Me';
  @override
  String get joinMarkAttended => 'Join / Mark attended';
  @override
  String get meetingHappened => 'Meeting happened';
  @override
  String get reminderText => 'Reminder';

  @override
  String get scheduleAMeetingTitle => 'Schedule a Meeting';
  @override
  String get meetingTitleLabel => 'Title';
  @override
  String get meetingTitleHint => 'e.g., Fee reconciliation review';
  @override
  String get mandatoryOneOnOneDirectorLabel => 'Mandatory monthly 1:1 with the Director — the Director is added automatically; mark it completed once done.';
  @override
  String get dateLabel => 'Date';
  @override
  String get timeLabel => 'Time';
  @override
  String get durationLabel => 'Duration';
  @override
  String get inviteesAvailabilityHeader => 'Invitees & availability — set each as mandatory or optional';
  @override
  String get sendRequestButton => 'Send request';
  @override
  String get freeStatus => 'Free';
  @override
  String get busyStatus => 'Busy';
  @override
  String get notificationsTitle => 'Notifications';
  @override
  String get markAllAsRead => 'Mark all as read';
  @override
  String get noNotifications => 'No notifications found';
  @override
  String get previewRemindersButton => 'Preview reminders';
  @override
  String get meetingsOrganizeOrInvitedSubtitle => 'Meetings you organize or are invited to · DSR/WSR/MSR slots auto-added';
  @override
  String get joinMarkAttendedButton => 'Join / Mark attended';
  @override
  String get meetingHappenedButton => 'Meeting happened';
  @override
  String get reminderButton => 'Reminder';
  @override
  String get allTab => 'All';
  @override
  String get meetingCalendarSubtitle => 'Browse your meetings & auto status-report slots — day, work week, week or month';
  @override
  String get todayButton => 'Today';
  @override
  String get dayView => 'Day';
  @override
  String get workWeekView => 'Work week';
  @override
  String get weekView => 'Week';
  @override
  String get monthView => 'Month';

  @override
  String get eventsTitle => 'Events';
  @override
  String get eventsSubtitle => 'Multi-department events with checklists & progress';
  @override
  String get eventsCalendarTitle => 'Events Calendar';
  @override
  String get eventsCalendarSubtitle => 'All school events across campuses, by month';
  @override
  String get assignedToMeTab => 'Assigned to me';
  @override
  String get eventsTab => 'Events';
  @override
  String get checklistLabel => 'Checklist';

  @override
  String get reportsDashboardTitle => 'Reports Dashboard';
  @override
  String get submittedTodayLabel => 'Submitted Today';
  @override
  String get totalReportsLabel => 'Total Reports';
  @override
  String get submittedLabel => 'Submitted';
  @override
  String get draftLabel => 'Draft';
  @override
  String get dailyDsrLabel => 'Daily (DSR)';
  @override
  String get weeklyWsrLabel => 'Weekly (WSR)';
  @override
  String get monthlyMsrLabel => 'Monthly (MSR)';
  @override
  String get dsrComplianceHeader => 'DSR Compliance';
  @override
  String get dsrComplianceSubtitle => 'Who filed vs. missed their daily report — \nlast 14 days (Sundays excluded)';
  @override
  String get filedLabel => 'filed';
  @override
  String get missedLabel => 'missed';

  @override
  String get todoHistoryTitle => 'To-Do · History';
  @override
  String get todoHistorySubtitle => 'A complete day-by-day ledger of everything on your lists — done, carried forward, or still open.';
  @override
  String get doneCountBadge => 'done';

  @override
  String get leaderboardTitle => 'Leaderboard & Coaching';
  @override
  String get leaderboardSubtitle => 'Badges, streaks & rewards to drive accountability';
  @override
  String get teamLeaderboardHeader => 'Team Leaderboard';
  @override
  String get teamLeaderboardSubtitle => 'Ranked by completed tasks across your scope';
  @override
  String get memberHeader => 'MEMBER';
  @override
  String get departmentHeader => 'DEPARTMENT';
  @override
  String get doneHeader => 'DONE';
  @override
  String get assignedHeader => 'ASSIGNED';
  @override
  String get overdueHeader => 'OVERDUE';
  @override
  String get pointsHeader => 'POINTS';
  @override
  String get myPointsLedgerHeader => 'My Points Ledger';
  @override
  String get runningBalanceLabel => 'Running balance';
  @override
  String get reasonHeader => 'REASON';
  @override
  String get changeHeader => 'CHANGE';
  @override
  String get balanceHeader => 'BALANCE';
  @override
  String get achievementBadgesHeader => 'Achievement Badges';

  @override
  String get teamPerformanceTitle => 'Team Performance';
  @override
  String get teamPerformanceSubtitle => 'Full performance matrix across teams, departments, and members';
  @override
  String get teamSizeLabel => 'Team Size';
  @override
  String get assignmentsLabel => 'Assignments';
  @override
  String get inProgressLabel => 'In Progress';
  @override
  String get toStartLabel => 'To Start';
  @override
  String get onTimeLabel => 'On-time';
  @override
  String get onTimeHeader => 'ON-TIME';
  @override
  String get workloadDeliveryHeader => 'Workload & Delivery';
  @override
  String get workloadDeliverySubtitle => 'every number is clickable · sort by any column';
  @override
  String get completionHeader => 'COMPLETION';
  @override
  String get dueTodayHeader => 'DUE TODAY';
  @override
  String get emgHighHeader => 'EMG+HIGH';
  @override
  String get droppedHeader => 'DROPPED';
  @override
  String get avgDaysHeader => 'AVG DAYS';
  @override
  String get byDepartmentHeader => 'By Department';
  @override
  String get byDepartmentSubtitle => 'completion across your scope';

  @override
  String get finesRewardsTitle => 'Fines & Rewards';
  @override
  String get finesRewardsSubtitle => 'Points, rewards & fines across your team';
  @override
  String get issueFineRewardLabel => 'Issue Fine / Reward';
  @override
  String get overviewTab => 'Overview';
  @override
  String get summaryTab => 'Summary';
  @override
  String get auditTrailTab => 'Audit Trail';
  @override
  String get samskarMerchandiseStoreHeader => 'SAMSKAR MERCHANDISE STORE';
  @override
  String get redeemButton => 'Redeem';

  @override
  String get performanceSettingsTitle => 'Performance Settings';
  @override
  String get performanceSettingsSubtitle => 'Fine & reward policies. Changes apply to future scores.';
  @override
  String get directorOnlyBadge => 'Director only';
  @override
  String get finePolicyHeader => 'FINE POLICY — WHAT EACH BREACH COSTS';
  @override
  String get finePolicySubtitle => 'Fine rates for task and report delays';
  @override
  String get rewardPolicyHeader => 'REWARD POLICY — HOW GOOD WORK EARNS POINTS';
  @override
  String get rewardPolicySubtitle => 'Point rewards for early completion and streaks';
  @override
  String get amountHeader => 'AMOUNT';
  @override
  String get addFineTypeButton => 'Add fine type';
  @override
  String get addRewardTypeButton => 'Add reward type';
  @override
  String get saveSettingsButton => 'Save settings';
  @override
  String get resetToDefaultsButton => 'Reset to defaults';
  @override
  String get discardChangesButton => 'Discard changes';
  @override
  String get typeColumnHeader => 'TYPE';
  @override
  String get rupeeAmountColumnHeader => '₹ AMOUNT';
  @override
  String get pointsColumnHeader => 'POINTS';
  @override
  String get deleteFineTypeConfirmTitle => 'Delete Fine Type';
  @override
  String get deleteRewardTypeConfirmTitle => 'Delete Reward Type';
  @override
  String get deleteButton => 'Delete';
  @override
  String deleteFineTypeConfirmMessage(String label) =>
      'Delete the fine type "$label"? Fines/rewards already issued are not affected.';
  @override
  String deleteRewardTypeConfirmMessage(String label) =>
      'Delete the reward type "$label"? Fines/rewards already issued are not affected.';
  @override
  String get addFineTypeDialogTitle => 'Add Fine Type';
  @override
  String get addRewardTypeDialogTitle => 'Add Reward Type';
  @override
  String get policyNameLabel => 'Policy Name / Type';
  @override
  String get policyAmountLabel => 'Amount (₹)';
  @override
  String get policyPointsLabel => 'Points';
  @override
  String get settingsSavedSuccessfully => 'Settings saved successfully';
  @override
  String get fineTypeAddedSuccessfully => 'Fine type added successfully';
  @override
  String get rewardTypeAddedSuccessfully => 'Reward type added successfully';
  @override
  String get fineTypeDeletedSuccessfully => 'Fine type deleted successfully';
  @override
  String get rewardTypeDeletedSuccessfully => 'Reward type deleted successfully';
  @override
  String get noChangesToSave => 'No changes to save';
  @override
  String get pleaseEnterValidLabel => 'Please enter a valid name';
  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';

  @override
  String get staffTitle => 'Staff';
  @override
  String get staffSubtitle => 'Manage staff, roles and access';
  @override
  String get addStaffTitle => 'Add Staff';
  @override
  String get searchStaffPlaceholder => 'Search staff by name, email...';
  @override
  String get staffTypeHeader => 'Staff Type';
  @override
  String get rbacRoleHeader => 'RBAC Role';
  @override
  String get firstNameLabel => 'First Name';
  @override
  String get lastNameLabel => 'Last Name';
  @override
  String get mobileLabel => 'Mobile';
  @override
  String get teachingOption => 'Teaching';
  @override
  String get nonTeachingOption => 'Non-Teaching';
  @override
  String get departmentLabel => 'Department';
  @override
  String get responsibilitiesLabel => 'Responsibilities';
  @override
  String get taskCreatorLabel => 'Task Creator';
  @override
  String get confidentialAccessLabel => 'Confidential Task Access';
  @override
  String get createdStat => 'CREATED';
  @override
  String get finesStat => 'FINES';
  @override
  String get allOption => 'All';

  // Sūtra AI Strings
  @override
  String get sutraTitle => 'Sūtra AI';
  @override
  String get sutraBadge => 'Command Centre';
  @override
  String get sutraSubtitle => 'The connecting thread — auto-drafts tasks, flags what needs a human, tracks the rest.';
  @override
  String get askSutraHeader => 'ASK SŪTRA — CREATE BY VOICE OR TEXT';
  @override
  String get askSutraPlaceholder => 'e.g. "Schedule a meeting with Swapnika, Narasimha and Anamika tomorrow 4pm" · "Create a high task to print PBL banners by Friday"';
  @override
  String get interpretButton => 'Interpret';
  @override
  String get pendingBadge => 'Pending: ';
  @override
  String get emergencyBadge => 'Emergency: ';
  @override
  String get completedBadge => 'Completed: ';
  @override
  String get needsHumanBadge => 'Needs Human: ';
  @override
  String get needsHumanTab => 'Needs Human';
  @override
  String get activityFeedTab => 'Activity Feed';
  @override
  String get composeTab => 'Compose';
  @override
  String get activeTasksTab => 'Active Tasks';
  @override
  String get composeHeader => 'COMPOSE WITH SŪTRA';
  @override
  String get composePlaceholder => 'Type a request in plain language... e.g. \'Remind accounts to release July vendor cheques by Friday\'';
  @override
  String get suggestPriorityChip => '✦ Suggest priority';
  @override
  String get pickAssigneeChip => '✦ Pick assignee';
  @override
  String get setDueDateChip => '✦ Set due date';
  @override
  String get createTaskButton => 'Create Task';
  @override
  String get approveButton => 'Approve';
  @override
  String get assignButton => 'Assign';
  @override
  String get reviewButton => 'Review';
  @override
  String get trackingBadge => 'Tracking';

  // My Preferences Strings
  @override
  String get myPreferencesTitle => 'My Preferences';
  @override
  String get myPreferencesSubtitle => 'Control which notifications you receive \nand through which channels.';
  @override
  String get profileCardHeader => 'PROFILE';
  @override
  String get yourPermissionsHeader => 'YOUR PERMISSIONS';
  @override
  String get dailyDigestHeader => 'Daily Digest';
  @override
  String get dailyDigestSubtitle => 'Get one summary notification each morning at 8 AM — overdue, due-today, open tasks, and what you closed yesterday — instead of watching them trickle in.';
  @override
  String get taskOperationsHeader => 'Task Operations';
  @override
  String get meetingsEventsHeader => 'Meetings & Events';
  @override
  String get prefReportsHeader => 'Reports';
  @override
  String get notificationTypeHeader => 'NOTIFICATION TYPE';
  @override
  String get inAppChannel => 'IN-APP';
  @override
  String get emailChannel => 'EMAIL';
  @override
  String get smsChannel => 'SMS';
  @override
  String get whatsappChannel => 'WHATSAPP';
  @override
  String get pushChannel => 'PUSH';

  // My Profile & FAQ Strings
  @override
  String get myProfileTitle => 'My Profile';
  @override
  String get personalInfoSection => 'PERSONAL INFORMATION';
  @override
  String get performanceStatsSection => 'PERFORMANCE STATISTICS';
  @override
  String get fullNameLabel => 'Full Name';
  @override
  String get totalTasksStat => 'Total Tasks';
  @override
  String get completedStatLabel => 'Completed';
  @override
  String get overdueStatLabel => 'Overdue';
  @override
  String get currentStreakStat => 'Current Streak';
  @override
  String get totalPointsStat => 'Total Points';
  @override
  String get onTimeRateStat => 'On-Time Rate';
  @override
  String get completionRateStat => 'Completion Rate';
  @override
  String get faqTitle => 'FAQ';
  @override
  String get faqSubtitle => 'Frequently asked questions about Samskar Task Manager';
  @override
  String get faqQ1 => 'How do I create a task?';
  @override
  String get faqA1 => 'Go to All Tasks → New Task. Fill title, description, priority (auto-sets the target date), branch and assignees. You can make it recurring, add a checklist and attach files.';
  @override
  String get faqQ2 => 'Why can\'t I close my own task?';
  @override
  String get faqA2 => 'Assignees mark a task as Done, which sends it for review with your comment & attachments. The person who assigned it reviews and moves it to Completed — and can award or reduce points.';
  @override
  String get faqQ3 => 'When are DSR / WSR / MSR reminders sent?';
  @override
  String get faqA3 => 'Everyone except Director & Principal gets a DSR reminder at 5:30 PM and 5:45 PM daily (6 PM deadline). WSR is every Saturday, MSR on the 3rd. If it falls on a Sunday or public holiday, it is preponed.';
  @override
  String get faqQ4 => 'How does the branch filter work?';
  @override
  String get faqA4 => 'Directors and Principals get an "All Branches" selector in the top bar to slice the dashboard, tasks and overview by SS00 / SS01 / SS02.';
  @override
  String get faqQ5 => 'How do I change theme or language?';
  @override
  String get faqA5 => 'Open the avatar menu → Settings. Choose Light / Dark / System, and English / తెలుగు / हिन्दी.';

  @override
  String get myStatusReports => 'My Status Reports';
  @override
  String get myStatusReportsSubtitle => 'Daily, weekly and monthly reports you have submitted';
  @override
  String get newReportButton => '+ New Report';
  @override
  String get newStatusReport => 'New Status Report';
  @override
  String get dailyDsr => 'Daily (DSR)';
  @override
  String get weeklyWsr => 'Weekly (WSR)';
  @override
  String get monthlyMsr => 'Monthly (MSR)';
  @override
  String get reportTypeLabel => 'Report Type';
  @override
  String get periodDateLabel => 'Period Date';
  @override
  String get periodDateHint => 'The day this report covers. Locked at 9:00 PM.';
  @override
  String get autoFillBannerNote => 'line auto-filled from your tasks and locked. You can only add more lines below each section — pulled lines can\'t be edited or removed.';
  @override
  String get workCompletedLabel => 'Work Completed *';
  @override
  String get workInProgressLabel => 'Work in Progress';
  @override
  String get pendingTasksLabel => 'Pending Tasks';
  @override
  String get challengesBlockersLabel => 'Challenges / Blockers';
  @override
  String get lockedContactDirector => 'Locked — contact Director/Principal to unlock';
  @override
  String get enterDetailsPlaceholder => 'Enter details...';
  @override
  String get saveDraft => 'Save Draft';
  @override
  String get submitButton => 'Submit';
  @override
  String get noClosureRequestsAwaiting => 'No closure requests awaiting your decision. 🎉';
  @override
  String get targetDateChange => 'Target-date change';
  @override
  String get resolveApprove => 'Resolve · Approve';
  @override
  String get saveChanges => 'Save changes';
  @override
  String get autoStatusReportSlotsToday => 'Auto status-report slots today: ';
  @override
  String get dsrTimeSlot => 'DSR · 5:30 PM';
  @override
  String get completionAwaitingApproval => 'Completion awaiting approval';
  @override
  String get noFinesOrRewardsYet => 'No fines or rewards yet.';
  @override
  String get youHaveNotOrganizedAnyMeetingsYet => 'You haven’t organized any meetings yet. 🎉';
  @override
  String get cancelReminderButton => 'Cancel reminder';
  @override
  String get reportsDashboardSubtitle => 'Your DSR / WSR / MSR status reports at a glance.';
  @override
  String get myReportsTitle => 'My Reports';
  @override
  String get noReportsFound => 'No reports found.';
  @override
  String get complianceTitle => 'Compliance';
  @override
  String get complianceSubtitle => 'Who filed vs. missed their status \nreport, by cycle';
  @override
  String get noComplianceDataAvailable => 'No compliance data available.';
  @override
  String noReportDueToday(String type, String nextDue) => 'No $type due today. Next $type on $nextDue.';
  @override
  String lastReportCycleInfo(String type, String cycle, int filed, int missed) => 'Last $type — $cycle: $filed completed · $missed missed';
  @override
  String get whoButton => 'Who?';

  // Complaints & Feedback Module Strings
  @override
  String get complaintsAndFeedbackHeader => 'COMPLAINTS & FEEDBACKS';
  @override
  String get complaintsTracker => 'Complaints Tracker';
  @override
  String get suggestionBoxEntry => 'Suggestion Box Entry';
  @override
  String get historyAndInsights => 'History & Insights';
  @override
  String get appreciationApprovals => 'Appreciation Approvals';

  @override
  String get complaintsAndFeedbackTitle => 'Complaints & Feedbacks';
  @override
  String get complaintsAndFeedbackSubtitle => 'Complaints, feedback and appreciations from parents and students — each one tracked to closure.';
  @override
  String get suggestionBoxEntryButton => 'Suggestion box entry';
  @override
  String get historyAndInsightsButton => 'History & insights';
  @override
  String get raiseRequestButton => '+ Raise Request';

  @override
  String get statNewNotPickedUp => 'New — not picked up';
  @override
  String get statInProgress => 'In progress';
  @override
  String get statPastTargetDate => 'Past target date';
  @override
  String get statResolvedThisMonth => 'Resolved this month';
  @override
  String get statAwaitingDirectorApproval => 'Awaiting Director approval';
  @override
  String get statAvgTimeToResolve => 'Avg. time to resolve';

  @override
  String get tabOpen => 'Open';
  @override
  String get tabPastTargetDate => 'Past target date';
  @override
  String get tabResolved => 'Resolved';
  @override
  String get tabAll => 'All';

  @override
  String get searchTicketsPlaceholder => 'Search ticket no., student, staff...';
  @override
  String get filterAllTypes => 'All types';
  @override
  String get filterParentsAndStudents => 'Parents & students';
  @override
  String get filterAllCategories => 'All categories';
  @override
  String get filterEveryones => "Everyone's";

  @override
  String get colTicket => 'TICKET';
  @override
  String get colType => 'TYPE';
  @override
  String get colFrom => 'FROM';
  @override
  String get colStudent => 'STUDENT';
  @override
  String get colAbout => 'ABOUT';
  @override
  String get colCategory => 'CATEGORY';
  @override
  String get colStatus => 'STATUS';
  @override
  String get colWith => 'WITH';
  @override
  String get colReceived => 'RECEIVED';
  @override
  String get colTask => 'TASK';
  @override
  String get noTicketsFound => 'No tickets found matching your criteria.';

  @override
  String get raiseARequestTitle => 'Raise a Request';
  @override
  String get typeLabel => 'Type *';
  @override
  String get typeComplaint => 'Complaint';
  @override
  String get typeFeedbackSuggestion => 'Feedback / Suggestion';
  @override
  String get typeAppreciation => 'Appreciation';
  @override
  String get receivedFromLabel => 'Received from *';
  @override
  String get receivedFromParent => 'Parent';
  @override
  String get receivedFromStudent => 'Student';
  @override
  String get receivedFromStaff => 'Staff member';
  @override
  String get channelLabel => 'Channel *';
  @override
  String get whichGroupPlaceLabel => 'Which group / place (optional)';
  @override
  String get whichGroupPlaceHint => 'e.g. Class 6B Parents';
  @override
  String get receivedOnLabel => 'Received on *';

  @override
  String get studentNameLabel => 'Student name *';
  @override
  String get studentNameHint => 'e.g. Aarav Reddy';
  @override
  String get classSectionLabel => 'Class & section *';
  @override
  String get classSectionHint => 'e.g. 6-B';
  @override
  String get admissionNoLabel => 'Admission no.';
  @override
  String get admissionNoHint => 'optional';
  @override
  String get parentNameLabel => 'Parent name';
  @override
  String get parentNameHint => 'e.g. Mrs. Kavitha Reddy';
  @override
  String get parentMobileLabel => 'Parent mobile (the ticket number is sent here)';
  @override
  String get parentMobileHint => '10-digit number';
  @override
  String get keepParentAnonymous => 'Keep the parent anonymous';
  @override
  String get keepParentAnonymousSubtext => 'Name, mobile and evidence stay visible to the campus head and Director only. The ticket number is still sent.';
  @override
  String get raiseAnonymously => 'Raise this anonymously';
  @override
  String get raiseAnonymouslyDesc => 'Your name stays visible to the Director only — not to the person or department it is about.';
  @override
  String get aboutLabel => 'About *';
  @override
  String get aboutStaffMember => 'Staff member';
  @override
  String get aboutDepartment => 'Department';
  @override
  String get aboutTransport => 'Transport';
  @override
  String get aboutFacility => 'Facility';
  @override
  String get aboutGeneral => 'General';
  @override
  String get staffMemberSubtext => 'Staff member (leave as "not named" if they don\'t want to say)';
  @override
  String get staffMemberDirectorDecides => 'Not named — the Director decides';
  @override
  String staffMemberAppreciationSubtitle(int points) => '(not named -> the Director decides who gets the $points points)';
  @override
  String get notNamedOption => "Not named — they don't want to say";

  @override
  String get priorityLabel => 'Priority';
  @override
  String get priorityEmergency => 'Emergency';
  @override
  String get priorityTopMost => 'Top Most';
  @override
  String get priorityHigh => 'High';
  @override
  String get priorityMedium => 'Medium';
  @override
  String get priorityLow => 'Low';
  @override
  String targetDateDaysFromToday(int days) => 'Target date: $days days from today.';
  @override
  String get visibilityLabel => 'Visibility *';
  @override
  String get visibilityGeneral => 'General — visible to all staff';
  @override
  String get visibilityConfidential => 'Confidential';
  @override
  String get whatWasSaidLabel => 'What was said? *';
  @override
  String get whatWasSaidHint => 'What happened, when, and what does the parent / student want?';
  @override
  String get evidenceLabel => 'Evidence * (WhatsApp screenshot, photo of the slip or letter)';
  @override
  String get addFileButton => 'Add file';
  @override
  String get fileUploadedSuccess => 'File attached successfully';
  @override
  String get uploadingFile => 'Uploading file...';
  @override
  String bannerTicketTaskCreated(String ticketNo, String taskNo, String ownerName) =>
      'Ticket $ticketNo and task $taskNo will be created and assigned to $ownerName. The parent gets the ticket number on WhatsApp.';
  @override
  String get registerComplaintButton => 'Register Complaint';
  @override
  String get recordAppreciationButton => 'Record Appreciation';
  @override
  String get saveDraftButton => 'Save draft';
  @override
  String savedDraftsCount(int count) => '$count saved draft${count == 1 ? '' : 's'}';
  @override
  String get resumeButton => 'Resume';
  @override
  String get draftSavedSuccess => 'Draft saved successfully';
  @override
  String get draftDeletedSuccess => 'Draft removed';
  @override
  String get draftResumedSuccess => 'Draft loaded successfully';
  @override
  String get fillRequiredFieldsDraftError => 'Please enter at least a student name, staff, or description to save a draft';
  @override
  String get complaintRegisteredTitle => 'Complaint registered';
  @override
  String get ticketNumberLabel => 'TICKET NUMBER';
  @override
  String get shareNumberNotice => 'Share this number if the parent or student follows up.';
  @override
  String get whatHappensNext => 'What happens next';
  @override
  String taskAssignedNotice(String taskNo, String owner, String due) =>
      'Task $taskNo assigned to $owner · due $due';
  @override
  String whatsappTicketSentNotice(String mobile) =>
      'WhatsApp with the ticket number sent to $mobile.';
  @override
  String get doneButton => 'Done';
  @override
  String get openTicketButton => 'Open ticket';
  @override
  String get fillRequiredFieldsError => 'Please fill all required fields.';
  @override
  String get invalidMobileNumberError => 'Please enter a valid 10-digit mobile number.';

  // Suggestion Box & Filters

  @override
  String get assignedByMe => 'Assigned by me';
  @override
  String get suggestionBoxEntryTitle => 'Suggestion Box Entry';
  @override
  String get backToTracker => '← Back to tracker';
  @override
  String get suggestionBoxSub =>
      'One row per slip. Rows without a student name are recorded as anonymous. Complaints and feedback create a task for the campus head; appreciations are recorded.';
  @override
  String get boxOpenedLabel => 'Box opened';
  @override
  String get branchPlaceholder => 'Branch…';
  @override
  String get addRowButton => '＋ Add row';
  @override
  String saveRequestsButton(int count) =>
      'Save ${count > 0 ? "$count " : ""}request${count == 1 ? "" : "s"}';
  @override
  String get savingRequests => 'Saving…';
  @override
  String get typeAtLeastOneSlipWarning =>
      'Type at least one slip before saving.';
  @override
  String attachPhotoWarning(int count) =>
      'Attach a photo of every slip — $count still ${count == 1 ? "needs" : "need"} one.';
  @override
  String registeredBannerTitle(int count) => 'REGISTERED ($count)';
  @override
  String slipTitle(int index) => 'SLIP $index';
  @override
  String get removeButton => '✕ Remove';
  @override
  String get studentBlankAnonymous => 'Student (blank = anonymous)';
  @override
  String get anonymousHint => 'Anonymous';
  @override
  String get classLabel => 'Class';
  @override
  String get classPlaceholder => '8-A';
  @override
  String get aboutLabelSimple => 'About';
  @override
  String get generalOption => 'General';
  @override
  String get staffMemberOption => 'Staff member';
  @override
  String get transportOption => 'Transport';
  @override
  String get facilityOption => 'Facility';

  @override
  String get categoryLabelSimple => 'Category';
  @override
  String get whatSlipSays => 'What the slip says *';
  @override
  String get typeSlipPlaceholder => 'Type the slip…';
  @override
  String get photoOfSlip => 'Photo of the slip *';
  @override
  String get addPhotoButton => '📎 Add photo';
  @override
  String get uploadingPhoto => 'Uploading…';
  @override
  String suggestionBoxFootnote(String ownerName, int points) =>
      'Tickets go to $ownerName of the selected branch. Appreciations naming a staff member add $points reward points; without a name the Director decides.';

  // History & Insights
  @override
  String get voiceOfParentsAndStudents => 'Voice of Parents & Students';
  @override
  String academicYearSubtitle(String year) => 'Academic year $year · June to May';
  @override
  String get complaintsAndFeedbacksDashboard => 'Complaints & Feedbacks Dashboard';
  @override
  String complaintsDashboardSubtitle(String year) =>
      'Everything parents, students and staff told us · academic year $year (June to May)';
  @override
  String get allTicketsButton => 'All tickets';
  @override
  String get openRightNow => 'Open right now';
  @override
  String get pastTargetDate => 'Past target date';
  @override
  String get fromParents => 'From parents';
  @override
  String get fromStudents => 'From students';
  @override
  String get fromStaff => 'From staff';
  @override
  String get avgDaysToResolve => 'Avg. days to resolve';
  @override
  String get complaintsHeader => 'COMPLAINTS';
  @override
  String get feedbackHeader => 'FEEDBACK';
  @override
  String get appreciationsHeader => 'APPRECIATIONS';
  @override
  String get lastHeader => 'LAST';
  @override
  String get complaintsDashboardTitle => 'Dashboard';
  @override
  String get receivedPerMonth => 'RECEIVED PER MONTH';
  @override
  String get complaintsByCategory => 'COMPLAINTS BY CATEGORY';
  @override
  String get byStaffMemberDirectorOnly => 'BY STAFF MEMBER · Director only';
  @override
  String get byStudentFamily => 'BY STUDENT / FAMILY';
  @override
  String get statTotalReceived => 'Total received';
  @override
  String get staffHeader => 'STAFF';
  @override
  String get studentHeader => 'STUDENT';
  @override
  String get classHeader => 'CLASS';
  @override
  @override
  String get noDataAvailable => 'No data available';

  // Parents & Students Complaints
  @override
  String get parentsComplaintsAndFeedbacks => 'Parents Complaints & Feedbacks';
  @override
  String get parentsComplaintsSubtitle =>
      'What parents told us — from the class WhatsApp groups, calls and walk-ins.';
  @override
  String get studentsComplaintsAndFeedbacks => 'Students Complaints & Feedbacks';
  @override
  String get studentsComplaintsSubtitle =>
      'What students told us — suggestion-box slips and anything they raise in person.';
  @override
  String get staffComplaintsAndFeedbacks => 'Staff Complaints & Feedbacks';
  @override
  String get staffComplaintsSubtitle =>
      'What staff told us — feedback, concerns and issues.';
  @override
  String get appreciations => 'Appreciations';
  @override
  String get appreciationsSubtitle =>
      'Every good word parents, students and staff had for our people — in one place.';
  @override
  String get appreciationsReceived => 'Appreciations received';
  @override
  String get recordedBadge => 'Recorded';
  @override
  String get awaitingDirectorApproval => 'Awaiting Director approval';
  @override
  String get rewardPointsGiven => 'Reward points given';
  @override
  String get rewardLabel => 'REWARD';
  @override
  String get onlyDirectorCanChange => 'Only the Director can change this.';
  @override
  String get resolutionLabel => 'Resolution';
  @override
  String get everyoneScope => 'Everyone';
  @override
  String get everyonesFilter => "Everyone's";
  @override
  String get tabEverything => 'Everything';
  @override
  String get statEverythingReceived => 'Everything received';
  @override
  String get filterComplaintsAndFeedback => 'Complaints & feedback';
  @override
  String get filterComplaintsOnly => 'Complaints only';
  @override
  String get filterFeedbackOnly => 'Feedback only';

  // Task Stats & Filters
  @override
  String get statTotalCard => 'Total';
  @override
  String get statNeedsReview => 'Needs Review';
  @override
  String get statAwaitingSignOff => 'awaiting for sign-off';
  @override
  String get statAcrossStatuses => 'across statuses';
  @override
  String get statFootnotePrefix => 'Click any card to see just those tasks. Newest Task ID first.';
  @override
  String get statFootnoteOverdue => 'Overdue';
  @override
  String get statFootnoteSuffix => ' is an overlay — open tasks past their date (not those awaiting review), already counted above.';
  @override
  String get createdByAssignedToAll => 'Created by / Assigned to: All';
  @override
  String get createdByMe => 'Created by me';
  @override
  String get assignedToMe => 'Assigned to me';
  @override
  String get anyCompletionPercent => 'Any completion %';
  @override
  String get toLabel => 'to';
  @override
  String selectAllWithCount(int count) => 'Select all ($count)';
  @override
  String byAuthor(String name) => 'By $name';
  @override
  String subtasksCountBadge(int done, int total) => '$done/$total sub-tasks';
  @override
  String get taskNoPrefix => 'Task ID ';
  @override
  String get completion0 => '0%';
  @override
  String get completion1To25 => '1-25%';
  @override
  String get completion26To50 => '26-50%';
  @override
  String get completion51To75 => '51-75%';
  @override
  String get completion76To99 => '76-99%';
  @override
  String get completion100 => '100%';
  @override
  String get newRecurringButton => '+ New Recurring';
  @override
  String get newTaskButton => 'New Task';
  @override
  String get bulkUploadButton => 'Bulk Upload';
  @override
  String get categoryAll => 'All';
  @override
  String get categoryConfidential => 'Confidential';
  @override
  String get categoryGeneral => 'General';
  @override
  String get viewList => 'List';
  @override
  String get viewBoard => 'Board';
  @override
  String get viewCalendar => 'Calendar';
  @override
  String get statComplaints => 'Complaints';
  @override
  String get statFeedback => 'Feedback';
  @override
  String get statAppreciations => 'Appreciations';
  @override
  String get taskIdSettings => 'Task ID Settings';
  @override
  String get taskIdSettingsSubtitle =>
      'Task IDs look like SS01-0001/09-26 — branch code, a 4-digit number, and the month-year the task was created. Sub-tasks add -1, -2 ... to their main task\'s ID.';
  @override
  String get counterPerBranch => 'COUNTER PER BRANCH';
  @override
  String get counterPerBranchSubtitle =>
      'Every branch counts on its own, from 0001 to 9999; after 9999 it starts again at 0001. All of them restart at 0001 automatically on 01 Jun 2027.';
  @override
  String get resetTo0001 => 'Reset to 0001';
  @override
  String get resetEveryBranch => 'Reset every branch to 0001';
  @override
  String get lastUsed => 'LAST USED';
  @override
  String get nextTaskId => 'NEXT TASK ID';
  @override
  String get lastReset => 'LAST RESET';
  @override
  String get complaintsDeskTitle => 'COMPLAINTS DESK — WHO RECEIVES TICKETS';
  @override
  String get complaintsDeskSubtitle =>
      'On Automatic a branch\'s complaints and feedback go to its own Principal / Campus Head. Name someone here to send that branch\'s tickets to them instead. Staff complaints always go to the Director.';
  @override
  String get fallbackLabel => 'fallback';
  @override
  String get automaticCurrentlyPrefix => 'Automatic — currently';
  @override
  String get resetConfirmTitle => 'Reset Counter';
  @override
  String resetConfirmMessage(String branch) =>
      'Are you sure you want to reset counter for $branch to 0001?';
  @override
  String get resetAllConfirmTitle => 'Reset All Branches';
  @override
  String get resetAllConfirmMessage =>
      'Are you sure you want to reset every branch counter to 0001? This will restart numbering for all branches.';
  @override
  String get centerHeadPrincipalRole => 'Center Head / Principal';
  @override
  String get teamLeadRole => 'Team Lead';
  @override
  String get managerRole => 'Manager';
  @override
  String centerHeadPrincipalScope(int count) => 'Team scope — $count people in view.';
  @override
  String get operationalScopeYourOwn => 'Operational scope — your own tasks & reports.';
  @override
  String get moreFilters => 'More filters';
  @override
  String get confidentialAndGeneral => 'Confidential & general';
  @override
  String get confidentialOnly => 'Confidential only';
  @override
  String get generalOnly => 'General only';
  @override
  String get updateEdit => 'Update / Edit';
  @override
  String get changeStatusTitle => 'Change Status';
  @override
  String get newStatusLabel => 'New Status';
  @override
  String get completionLabel => 'Completion';
  @override
  String get commentRequiredLabel => 'Comment * (required for every update)';
  @override
  String get commentPlaceholder => 'Add an update note... type @ to mention someone';
  @override
  String get addFiles => 'Add files';
  @override
  String get attachmentsLabel => 'Attachments';
  @override
  String get commentRequiredError => 'Please enter an update comment';
  @override
  String get taskUpdatedSuccess => 'Task updated successfully';
  @override
  String get blockedStatus => 'Blocked';

  // Ticket Details & Actions Dialog Strings
  @override
  String get linkedTask => 'LINKED TASK';
  @override
  String get openTask => 'Open task';
  @override
  String get assignTo => 'Assign to...';
  @override
  String get assignThisTicket => 'ASSIGN THIS TICKET';
  @override
  String get searchPeoplePlaceholder => 'Search people...';
  @override
  String get whatShouldTheyDoPlaceholder => 'What should they do? (required)';

  @override
  String get closeTheLoop => 'CLOSE THE LOOP';
  @override
  String get resolveTab => 'Resolve';
  @override
  String get notValidTab => 'Not valid';
  @override
  String get whatWasDonePlaceholder => 'What was done, and what are we telling the parent?';
  @override
  String get reasonWhyNotValidPlaceholder => 'Reason why this is not valid...';
  @override
  String get markResolvedButton => 'Mark Resolved';
  @override
  String get closeAsNotValidButton => 'Close as not valid';
  @override
  String get downloadLabel => 'Download';
  @override
  String get evidenceVisibleCampusHeadOnly => 'Evidence is visible to the campus head only.';
  @override
  String get historyLabel => 'History';
  @override
  String get detailsSectionLabel => 'Details';
  @override
  String get confidentialBadge => 'Confidential';
  @override
  String get editTicketButton => 'Edit ticket';
  @override
  String get anonymousHidden => 'Anonymous — hidden';
  @override
  String get editTicketTitlePrefix => 'Edit';

  @override
  String get classAndSectionLabel => 'Class & section';


  @override
  String get detailsLabel => 'Details';

  @override
  String get addEvidenceLabel => 'Add evidence';

  @override
  String get reasonForChangeLabel => 'Reason for this change *';
  @override
  String get reasonForChangePlaceholder => 'e.g. Parent gave the correct class section';
  @override
  String get saveChangesButton => 'Save changes';

  @override
  String get campusHeadLabel => 'campus head';

  @override
  String get closedSectionLabel => 'Closed';

  @override
  String get resolvedSectionLabel => 'Resolved';

  // Audit Execution & Scheduling Strings
  @override
  String get scheduleAnAudit => 'Schedule an audit';
  @override
  String get auditTitleLabel => 'Title';
  @override
  String get scopeNoteLabel => 'Scope note';
  @override
  String get auditorLabel => 'Auditor';
  @override
  String get auditeeTypeLabel => 'Auditee';
  @override
  String get auditeeLabel => 'Auditee Branch / Person';
  @override
  String get scheduledDateLabel => 'Scheduled date';
  @override
  String get dueDateLabel => 'Due date';
  @override
  String get checklistOnePerLine => 'Checklist (one item per line)';
  @override
  String get scheduleAuditButton => 'Schedule audit';
  @override
  String get closeAudit => 'Close audit';
  @override
  String get conductedBy => 'Conducted by';
  @override
  String get scheduledFor => 'Scheduled for';
  @override
  String get dueOn => 'Due on';
  @override
  String get closedOn => 'Closed on';
  @override
  String get noAuditsFound => 'No audits found.';
  @override
  String get threeMonthsView => '3 Months';
  @override
  String get eventsInTheseThreeMonths => 'EVENTS IN THESE 3 MONTHS';
  @override
  String get listViewLabel => 'List';
  @override
  String get fineLabel => 'Fine';
  @override
  String get issuedByLabel => 'Issued by';
  @override
  String get policyRules => 'Fine & Reward Policies';
  @override
  String get availablePointsLabel => 'Points Available';
  @override
  String get scopeEveryone => 'Everyone';
  @override
  String get scopeParents => 'Parents';
  @override
  String get scopeStudents => 'Students';
  @override
  String get scopeStaff => 'Staff';
  @override
  String get studentFamilyListTitle => 'By student / family';
  @override
  String get lastRecordedLabel => 'Last';
  @override
  String get branchScopeLabel => 'Branch';

  // ── Clone Task ─────────────────────────────────────────────────────────────
  @override
  String get cloneTaskTitle => 'Clone Task';
  @override
  String get cloneTaskBannerHint => 'A new Task ID is assigned on save. Change anything you need, then create.';
  @override
  String get taskIdLabel => 'Task ID';
  @override
  String get taskTitleLabel => 'Task Title';
  @override
  String get taskDescLabel => 'Task Description';

  @override
  String get schoolBranchLabel => 'School Branch';

  @override
  String get targetDateLabel => 'Target Date';

  @override
  String get confidentialLabel => 'Confidential';
  @override
  String get generalLabel => 'General';
  @override
  String get makeRecurringLabel => 'Make this a recurring task';
  @override
  String get assignedToLabel => 'Assigned To';
  @override
  String get searchUsersHint => 'Search users...';

  @override
  String get addFilesButton => 'Add files';
  @override
  String get taskChecklistLabel => 'Task Checklist';
  @override
  String get generateButton => 'Generate';
  @override
  String get addItemButton => '+ Add item';
  @override
  String get remarksLabel => 'Remarks';
  @override
  String get saveTaskButton => 'Save Task';

  @override
  String get statusLabel => 'Status';

  // ── Status Report PDF ──────────────────────────────────────────────────────
  @override
  String get savePdfButton => 'Save PDF';
  @override
  String get statusReportPdfTitle => 'Status Report';

  @override
  String get submittedAtLabel => 'Submitted At';
  @override
  String get exportedOnLabel => 'Exported on';
  @override
  String get unlockReportButton => 'Unlock Report';

  // ── Appreciation Award Strings ─────────────────────────────────────────────
  @override
  String get rewardDirectorOnly => 'REWARD — DIRECTOR ONLY';
  @override
  String get updateFacultyAndPoints => 'Update faculty & points';
  @override
  String get rewardPointsLabel => 'Reward points';
  @override
  String get facultyLabel => 'Faculty *';
  @override
  String get reasonRequiredLabel => 'Reason *';
  @override
  String get whyIsThisBeingChangedHint => 'Why is this being changed?';
  @override
  String get pointsUpdatedSuccessfully => 'Points updated successfully.';
  @override
  String get pleaseEnterPoints => 'Please enter reward points.';
  @override
  String get pleaseEnterReason => 'Please enter reason why this is being changed.';
  @override
  String get selectFacultyPrompt => 'Please select a faculty.';
  @override
  String get searchFacultyPlaceholder => 'Search faculty...';
  @override
  String get changingThisMovesPoints => 'Changing this moves the points.';

  // ── Announcements Module Strings ──────────────────────────────────────────
  @override
  String get announcements => 'Announcements';
  @override
  String get announcementsTickerLabel => 'ANNOUNCEMENTS';
  @override
  String get announcementsSubtitle =>
      'Posts here scroll across the top of every page for the whole team. Managers & above can create them.';
  @override
  String get newAnnouncement => 'New announcement';
  @override
  String get editAnnouncement => 'Edit announcement';
  @override
  String get postAnnouncement => 'Post announcement';
  @override
  String get announcementTitleLabel => 'Title *';
  @override
  String get announcementTitleHint => 'e.g., Half-day on Friday for Sports Day';
  @override
  String get announcementDetailsLabel => 'Details';
  @override
  String get announcementDetailsHint => 'Optional longer message shown in the ticker...';
  @override
  String get priorityInfo => 'Info';
  @override
  String get priorityCritical => 'Critical';
  @override
  String get priorityWarning => 'Warning';
  @override
  String get activeShowNow => 'Active (show now)';
  @override
  String get showFromOptional => 'Show from (optional)';
  @override
  String get showUntilOptional => 'Show until (optional)';
  @override
  String get deactivate => 'Deactivate';
  @override
  String get activate => 'Activate';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String deleteAnnouncementConfirmation(String title) => 'Delete announcement "$title"?';
  @override
  String get noAnnouncementsFound => 'No announcements found';
  @override
  String get announcementCreatedSuccess => 'Announcement posted successfully';
  @override
  String get announcementUpdatedSuccess => 'Announcement updated successfully';
  @override
  String get announcementDeletedSuccess => 'Announcement deleted successfully';
  @override
  String get announcementDeactivatedSuccess => 'Announcement deactivated successfully';
  @override
  String get announcementActivatedSuccess => 'Announcement activated successfully';
  @override
  String get themeModeLight => 'Light';
  @override
  String get themeModeDark => 'Dark';
  @override
  String get themeModeSystem => 'System Comfortable';

  // Hourly Log Strings
  @override
  String get hourlyLog => 'Hourly Log';
  @override
  String get dailyHourlyLog => 'Daily Hourly Log';
  @override
  String get dailyHourlyLogSubtitle =>
      'Log what you did each hour — add one or more entries per slot. Every slot except your lunch hour is required. Auto-submits at 9 PM if you don\'t submit it yourself.';
  @override
  String slotsFilledCount(int filled, int total) => '$filled/$total slots filled';
  @override
  String get submitDsr => 'Submit DSR';
  @override
  String get setAsLunch => 'Set as lunch';
  @override
  String get lunchHour => 'Lunch Hour';
  @override
  String get whatDidYouWorkOn => 'What did you work on...';
  @override
  String get deleteItemConfirm => 'Are you sure you want to delete this log entry?';
  @override
  String get editLogEntry => 'Edit Log Entry';
  @override
  String get dsrSubmittedSuccessfully => 'DSR submitted successfully';
  @override
  String get addEntry => 'Add';
  @override
  String get noEntriesYet => 'No entries yet for this slot';
  @override
  String hourlyLogPromptTitle(String slot) => 'Hourly log — $slot';
  @override
  String whatDidYouWorkOnDuring(String slot) => 'What did you work on during $slot?';
  @override
  String get addQuickEntryHint => 'Add a quick entry...';
  @override
  String get logButton => 'Log';
  @override
  String get openFullLog => 'Open full log →';
  @override
  String get remindMeLater => 'Remind me later';
  @override
  String get submitDsrConfirmTitle => 'Submit DSR?';
  @override
  String get submitDsrConfirmMessage =>
      'Submit your hourly log for today? You won’t be able to edit it afterwards.';
  @override
  String get submittedStatus => 'Submitted';
  @override
  String get notFilledStatus => 'Not filled';
  @override
  String entryLoggedSuccess(String slot) => 'Entry logged successfully for $slot!';
  @override
  String get hourlyLogSubmittedSuccess => 'Hourly log submitted successfully!';
  @override
  String get announcementsHeader => 'ANNOUNCEMENTS';

  @override
  String get joinGoogleMeet => 'Join Google Meet';
  @override
  String get needLink => 'Need link';
  @override
  String get meetingLinkCopied => 'Meeting link copied to clipboard';
  @override
  String get noMeetingLinkAvailable => 'No meeting link available';
  @override
  String get syncWithGoogleCalendar => 'Sync with Google Calendar';
  @override
  String get syncWithGoogleCalendarSubtitle => '(sends Google invites to participants)';
  @override
  String get createGoogleMeetVideoLink => 'Create Google Meet video link automatically';
  @override
  String get googleCalendarIntegration => 'Google Calendar Integration';
  @override
  String get notConnected => 'Not Connected';
  @override
  String get connectedStatus => 'Connected';
  @override
  String get googleCalendarConnectDescription =>
      'Connect your Google Calendar so meeting invites are sent directly from your email address.';
  @override
  String get connectGoogleCalendar => 'Connect Google Calendar';
  @override
  String get disconnect => 'Disconnect';
  @override
  String get disconnectGoogleCalendarConfirmation =>
      'Are you sure you want to disconnect your Google Calendar?';
  @override
  String get disconnectGoogleCalendarTitle => 'Disconnect Google Calendar';
  @override
  String googleCalendarConnectedDescription(String email) =>
      'Connected to $email. Meeting invites will be sent directly from your email address.';
  @override
  String get googleCalendarDisconnectedSuccess =>
      'Google Calendar disconnected successfully';
  @override
  String get googleCalendarConnectedSuccess =>
      'Google Calendar connected successfully!';

  @override
  String get budgetIndents => 'Budget Indents';
  @override
  String get budgetIndentsSubtitle =>
      'Raise a purchase indent; the amount decides how far up it must be approved. A voucher prints once it’s fully signed off.';
  @override
  String get toApproveTab => 'To approve';
  @override
  String get myIndentsTab => 'My indents';
  @override
  String get allIndentsTab => 'All';
  @override
  String get raiseIndent => 'Raise indent';
  @override
  String get voucherReady => 'ready';
  @override
  String get neededBy => 'Needed by';
  @override
  String get purposeLabel => 'PURPOSE';
  @override
  String get approvalChain => 'Approval chain';
  @override
  String get itemHeader => 'ITEM';
  @override
  String get qtyHeader => 'QTY';
  @override
  String get unitHeader => 'UNIT PRICE';

  @override
  String get grandTotal => 'Grand Total';
  @override
  String get printVoucherPdf => 'Print voucher (PDF)';
  @override
  String get printSaveAsPdf => 'Print / Save as PDF';
  @override
  String get authorisedSignatory => 'Authorised Signatory';
  @override
  String get computerGeneratedNotice =>
      'This is a computer-generated voucher · no physical signature is required.';

  // Raise Purchase Indent Dialog
  @override
  String get raisePurchaseIndent => 'Raise a purchase indent';
  @override
  String get indentTitleLabel => 'Title *';
  @override
  String get indentTitleHint => 'e.g., Whiteboard markers for Grade 6 block';
  @override
  String get purposeJustificationLabel => 'Purpose / justification';
  @override
  String get purposeJustificationHint => 'Why is this needed?';
  @override
  String get lineItemsLabel => 'Line items *';
  @override
  String get descriptionColumn => 'Description';
  @override
  String get qtyColumn => 'Qty';
  @override
  String get unitPriceColumn => 'Unit ₹';
  @override
  String get amountColumn => 'Amount';
  @override
  String get itemHint => 'Item';
  @override
  String get addItem => '+ Add item';
  @override
  String get neededByOptional => 'Needed by (optional)';
  @override
  String get totalLabel => 'Total';
  @override
  String get autoApprovedNotice =>
      'You\'re at or above the required level — this indent will be auto-approved and a voucher issued immediately.';
  @override
  String get submitIndentButton => 'Submit indent';
  @override
  String get indentCreatedSuccess => 'Indent submitted successfully';

  // Appreciation Approvals

  @override
  String get waitingBadge => 'waiting';
  @override
  String get appreciationApprovalsSubtitle =>
      'Appreciations from parents and students that did not name a faculty member. Read the full entry, then decide who receives the reward points.';
  @override
  String get openFullTicket => 'Open full ticket';
  @override
  String get awaitingYourApproval => 'Awaiting your approval';
  @override
  String get evidenceAttachedNotice =>
      'Open the full ticket to see the evidence attached by';
  @override
  String get approveAppreciationHeader => 'APPROVE APPRECIATION';
  @override
  String get noFacultyNamedSubtitle =>
      'No faculty was named. Choose who receives the points.';
  @override
  String get facultyRequiredLabel => 'Faculty *';
  @override
  String get selectStaffMemberHint => 'Select staff member...';

  @override
  String get whyThisFacultyHint => 'Why this faculty / these points?';
  @override
  String get approveAndAwardPoints => 'Approve & award';
  @override
  String get approveAndAward50Points => '🏅 Approve & award 50 points';
  @override
  String get searchStaffHint => 'Search staff member...';
  @override
  String get noStaffFound => 'No staff members found';
  @override
  String get noAppreciationsWaiting => 'No appreciations waiting for approval';
  @override
  String get pointsAwardedSuccess => 'Points awarded successfully';
  @override
  String get anonymousLabel => 'Anonymous';
  @override
  String get notNamedYetLabel => 'Not named yet';
  @override
  String get fromLabel => 'From';
  @override
  String get studentLabel => 'Student';

  @override
  String get receivedLabel => 'Received';
  @override
  String get raisedByLabel => 'Raised by';

  // Sub-task & Edit Task Strings
  @override
  String get subTasksTitle => 'Sub-tasks';
  @override
  String get addSubTaskButton => '+ Add sub-task';
  @override
  String get subTasksSubtitle => 'Split this task into smaller pieces, each with its own assignee and date.';
  @override
  String get subTaskOf => 'Sub-task of';
  @override
  String get taskIdAutoGenerated => 'Task ID (auto-generated)';
  @override
  String get taskIdAutoGeneratedHint => 'Confirmed when you save — may move up if someone else saves first.';

  @override
  String get taskTitleHint => 'e.g., Prepare admissions data sheet';
  @override
  String get taskDescriptionLabel => 'Task Description';
  @override
  String get taskDescriptionHint => 'Describe the task in detail...';

  @override
  String get assignedBySubtext => 'You\'re assigning this task. To raise it under someone else\'s authority, use "Assigning on Behalf of".';
  @override
  String get assigningOnBehalfOfLabel => 'Assigning on Behalf of (optional)';
  @override
  String get assigningOnBehalfOfSubtext => 'Leave as yourself, or pick the person you\'re assigning this on behalf of. You (the creator) are recorded separately; the review goes to this person.';

  @override
  String get targetDateSubtext => 'Auto-set from priority — editable. Must be on or before the main task\'s date.';

  @override
  String get searchPeopleHint => 'Search people...';
  @override
  String get groupsLabel => 'GROUPS';
  @override
  String get selectedLabel => 'SELECTED';
  @override
  String get pickUsersFromLeft => 'Pick users or a group from the left';

  @override
  String get addChecklistItemHint => 'Add a checklist item...';

  @override
  String get saveSubTaskButton => '✓ Save Sub-task';
  @override
  String get reassignButton => 'Reassign';
  @override
  String get editTaskTitle => 'Edit Task';

  @override
  String get commentLabel => 'Comment';
  @override
  String get commentSubtext => '(what changed and why — added to the task\'s comments)';
  @override
  String get commentHint => 'e.g. Target date moved — venue booking delayed';
  @override
  String get priorityActNow => 'Emergency · Act NOW';
  @override
  String get priorityActToday => 'Top Most · Act Today';
  @override
  String get priorityActThisWeek => 'High · Act this Week';
  @override
  String get priorityScheduleToAct => 'Medium · Schedule to Act';
  @override
  String get priorityWhenTimePermits => 'Low · When time Permits';
  @override
  String get subtaskCreatedSuccess => 'Sub-task created successfully!';

  @override
  String get forbiddenErrorTitle => 'Action Not Allowed';
  @override
  String get noSubtasksYet => 'No sub-tasks added yet.';
  @override
  String get approveAndClose => 'Approve & close';
  @override
  String get sendBack => 'Send back';
  @override
  String get btnAccept => 'Accept';
  @override
  String get btnDecline => 'Decline';
  @override
  String get btnTentative => 'Tentative';
  @override
  String get completionSignOff => 'Completion sign-off';
  @override
  String get completionSignOffSubtitle => 'someone reported these meetings took place';
  @override
  String get btnReject => 'Reject';
}

