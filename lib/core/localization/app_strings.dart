import 'package:flutter/material.dart';
import 'app_strings_en.dart';
import 'app_strings_te.dart';
import 'app_strings_hi.dart';
import 'app_strings_kn.dart';

abstract class AppStrings {
  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return fromLocale(locale);
  }

  static AppStrings fromLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'te':
        return AppStringsTe();
      case 'hi':
        return AppStringsHi();
      case 'kn':
        return AppStringsKn();
      case 'en':
      default:
        return AppStringsEn();
    }
  }

  // App & Auth Strings
  String get appTitle;
  String get welcomeBack;
  String get signInToAccount;
  String get quickLoginAs;
  String get credentials;
  String get emailLabel;
  String get passwordLabel;
  String get signInButton;
  String get demoPasswordHint;

  // Quick Login Role Titles
  String get directorVamsi;
  String get principalMadhumathi;
  String get managerMurali;
  String get managerSwapnika;
  String get teamLeadNarasimha;
  String get executiveAnamika;
  String get executiveGyapika;

  // Navigation Drawer Headers & Items
  String get dashboard;
  String get organizationOverview;
  String get tasksHeader;
  String get allTasks;
  String get myTasks;
  String get recurringTasks;
  String get approvalsHeader;
  String get taskApprovals;
  String get escalations;
  String get meetingApprovals;
  String get budgetApprovals;
  String get meetingsHeader;
  String get monthlyOneOnOnePending;
  String get myScheduledMeetings;
  String get meetingCalendar;
  String get eventsHeader;
  String get events;
  String get eventsCalendar;
  String get reportsHeader;
  String get statusReports;
  String get reportsDashboard;
  String get todoHeader;
  String get today;
  String get history;
  String get performanceHeader;
  String get leaderboard;
  String get teamPerformance;
  String get finesAndRewards;
  String get settings;
  String get organizationHeader;
  String get staff;
  String get aiAndSettingsHeader;
  String get sutraAi;
  String get myPreferences;
  String get directorBadgeScope;

  // App Bar Strings
  String get searchPlaceholder;
  String get newButton;
  String get newTask;
  String get newTodo;
  String get newMeeting;
  String get newEvent;
  String get allBranches;
  String get directorRole;
  String get myProfile;
  String get faq;
  String get logout;

  // Dashboard Greeting & Stats
  String get directorHeadOffice;
  String get greetingNamaste;
  String get dashboardSubtitle;
  String approvalsBadge(int count);
  String toStartBadge(int count);
  String inProgressBadge(int count);
  String overdueBadge(int count);
  String completionBadge(int rate);

  // Performance Section
  String get performanceTitle;
  String get performanceSubtitle;
  String get dayWise;
  String get weekWise;
  String get monthWise;
  String get quarterly;
  String get yearly;

  // Tasks by Priority Section
  String get tasksByPriority;
  String get emergencyPriority;
  String get topMostPriority;
  String get highPriority;
  String get mediumPriority;
  String get lowPriority;

  // Total Organisation Section
  String get totalOrganisation;
  String get readOnlyTransparency;
  String get totalTasks;
  String get completed;
  String get inProgress;
  String get overdue;
  String get dropped;

  // Recent Activity & Team Section
  String get recentActivityTitle;
  String get teamLoginAnalyticsTitle;
  String get activeToday;
  String get daysAway1To3;
  String get daysAway4To6;
  String get daysAway7Plus;
  String get neverSignedIn;

  // To-Do Today Dialog
  String get todoTodayTitle;
  String get todoTodaySubtitle;
  String get reviewPendingApprovals;
  String get checkScheduledMeetings;
  String get addNotePlaceholder;
  String get addButton;

  // Settings Screen
  String get appearance;
  String get appearanceSubtitle;
  String get themeMode;
  String get themeLight;
  String get themeDark;
  String get themeSystem;
  String get language;
  String get languageSubtitle;
  String get langEnglish;
  String get langTelugu;
  String get langHindi;
  String get langKannada;

  // Total Organisation Details
  String get toBeStarted;
  String get workUnderway;
  String get needsAttention;
  String get notYetPickedUp;
  String get closedWithoutCompletion;

  // Action Center Card
  String get actionCenterTitle;
  String get clickRowToOpen;
  String get approvalsToReview;
  String get overdueTasks;
  String get dueToday;
  String get emergencyHighOpen;

  // Scheduled Meetings Card
  String get noMeetingsScheduled;

  // Login Activity Card
  String get myLoginActivityTitle;
  String get loginsToday;
  String get loginsThisWeek;
  String get activeTodaySpan;
  String get activeThisWeekSpan;
  String get firstLoginToday;
  String get activeDays;
  String get lastLoginLabel;
  String get activeSpanNotice;

  // Overdue Tasks by Age Card
  String get overdueTasksByAgeTitle;
  String get overdueTasksByAgeSubtitle;
  String get days1To3;
  String get days4To7;
  String get days8To14;
  String get days15Plus;

  // Team & Recent Activity Section
  String get myTeam;
  String get membersLabel;
  String get teamWide;
  String get clickRowForDetails;
  String get recentActivityDetail;
  String get viewTask;
  String get branchLabel;
  String get dueLabel;
  String get completedLabel;
  String get clickGroupForMembers;

  // Dialogs & Safety
  String get noInternetTitle;
  String get noInternetMessage;
  String forceLogoutNotice(int seconds);
  String get retryButton;
  String get exitAppTitle;
  String get exitAppMessage;
  String get cancelButton;
  String get exitButton;

  // Tasks Due Today & Detail Modal
  String get tasksDueTodayTitle;
  String get showingRangeText;
  String get sortByLabel;
  String get entryDateLabel;
  String get branchLegendLabel;
  String get taskIdHeader;
  String get descriptionHeader;
  String get branchHeader;
  String get priorityHeader;
  String get statusHeader;
  String get dueHeader;
  String get assignedByLabel;
  String get categoryLabel;
  String get locationLabel;
  String get assigneesLabel;
  String get activityLabel;
  String get closeButton;

  // Organization Overview Strings
  String get everyCampusDeptAtAGlance;
  String get byBranchUnit;
  String get searchBranchPlaceholder;
  String get clickRowOrFilterTopBar;
  String get analyticsTitle;
  String get exportButton;
  String get organizationWide;
  String get trendsOverTime;
  String get weeklyBucket;
  String get monthlyBucket;
  String get quarterlyBucket;
  String get yearlyBucket;
  String get createdLegend;
  String get completedLegend;
  String get onTimeCompletionDueWindow;
  String get taskStatusDistribution;
  String get priorityLoadTitle;
  String get completionByBranch;
  String get workloadByDeadlineOpenTasks;

  // All Tasks Screen Strings
  String get tasksInYourScope;
  String get needsAction;
  String get newRecurring;
  String get bulkUpload;
  String get allScope;
  String get confidentialScope;
  String get generalScope;
  String get searchTasksPlaceholder;
  String get allStatuses;
  String get allPriorities;
  String get selectAllText;

  // My Tasks & Recurring Tasks Screen Strings
  String get tasksAssignedToOrCreatedByYou;
  String get repeatingDutiesAutoGenerated;
  String get dailyFrequency;
  String get weeklyFrequency;
  String get monthlyFrequency;
  String get biMonthlyFrequency;
  String get quarterlyFrequency;
  String get halfYearlyFrequency;
  String get yearlyFrequency;
  String get othersFrequency;
  String get listView;
  String get boardView;
  String get calendarView;

  // Meetings & Calendar Screen Strings
  String get staffWhoHaventCompletedMandatory;
  String get scheduleOneOnOne;
  String get oneOnOnePendingBadge;
  String get meetingsYouOrganizeOrInvitedTo;
  String get previewReminder;
  String get initiatedByMe;
  String get receivedByMe;
  String get joinMarkAttended;
  String get meetingHappened;
  String get reminderText;

  // New Meeting Dialog & Calendar Strings
  String get scheduleAMeetingTitle;
  String get meetingTitleLabel;
  String get meetingTitleHint;
  String get mandatoryOneOnOneDirectorLabel;
  String get dateLabel;
  String get timeLabel;
  String get durationLabel;
  String get inviteesAvailabilityHeader;
  String get sendRequestButton;
  String get freeStatus;
  String get busyStatus;
  String get notificationsTitle;
  String get markAllAsRead;
  String get noNotifications;
  String get previewRemindersButton;
  String get meetingsOrganizeOrInvitedSubtitle;
  String get joinMarkAttendedButton;
  String get meetingHappenedButton;
  String get reminderButton;
  String get allTab;
  String get meetingCalendarSubtitle;
  String get todayButton;
  String get dayView;
  String get workWeekView;
  String get weekView;
  String get monthView;

  // Events Screen & Events Calendar Strings
  String get eventsTitle;
  String get eventsSubtitle;
  String get eventsCalendarTitle;
  String get eventsCalendarSubtitle;
  String get assignedToMeTab;
  String get eventsTab;
  String get checklistLabel;

  // Reports Dashboard Strings
  String get reportsDashboardTitle;
  String get submittedTodayLabel;
  String get totalReportsLabel;
  String get submittedLabel;
  String get draftLabel;
  String get dailyDsrLabel;
  String get weeklyWsrLabel;
  String get monthlyMsrLabel;
  String get dsrComplianceHeader;
  String get dsrComplianceSubtitle;
  String get filedLabel;
  String get missedLabel;

  // To-Do History Strings
  String get todoHistoryTitle;
  String get todoHistorySubtitle;
  String get doneCountBadge;

  // Leaderboard & Coaching Strings
  String get leaderboardTitle;
  String get leaderboardSubtitle;
  String get teamLeaderboardHeader;
  String get teamLeaderboardSubtitle;
  String get memberHeader;
  String get departmentHeader;
  String get doneHeader;
  String get assignedHeader;
  String get overdueHeader;
  String get pointsHeader;
  String get myPointsLedgerHeader;
  String get runningBalanceLabel;
  String get reasonHeader;
  String get changeHeader;
  String get balanceHeader;
  String get achievementBadgesHeader;

  // Team Performance Strings
  String get teamPerformanceTitle;
  String get teamPerformanceSubtitle;
  String get teamSizeLabel;
  String get assignmentsLabel;
  String get inProgressLabel;
  String get toStartLabel;
  String get onTimeLabel;
  String get onTimeHeader;
  String get workloadDeliveryHeader;
  String get workloadDeliverySubtitle;
  String get completionHeader;
  String get dueTodayHeader;
  String get emgHighHeader;
  String get droppedHeader;
  String get avgDaysHeader;
  String get byDepartmentHeader;
  String get byDepartmentSubtitle;

  // Fines & Rewards Strings
  String get finesRewardsTitle;
  String get finesRewardsSubtitle;
  String get issueFineRewardLabel;
  String get overviewTab;
  String get summaryTab;
  String get auditTrailTab;
  String get samskarMerchandiseStoreHeader;
  String get redeemButton;

  // Performance Settings Strings
  String get performanceSettingsTitle;
  String get performanceSettingsSubtitle;
  String get directorOnlyBadge;
  String get finePolicyHeader;
  String get finePolicySubtitle;
  String get rewardPolicyHeader;
  String get rewardPolicySubtitle;
  String get amountHeader;
  String get addFineTypeButton;
  String get addRewardTypeButton;
  String get saveSettingsButton;
  String get resetToDefaultsButton;

  // Staff Management Strings
  String get staffTitle;
  String get staffSubtitle;
  String get addStaffTitle;
  String get searchStaffPlaceholder;
  String get staffTypeHeader;
  String get rbacRoleHeader;
  String get firstNameLabel;
  String get lastNameLabel;
  String get mobileLabel;
  String get teachingOption;
  String get nonTeachingOption;
  String get departmentLabel;
  String get responsibilitiesLabel;
  String get taskCreatorLabel;
  String get confidentialAccessLabel;
  String get createdStat;
  String get finesStat;
  String get allOption;

  // Sūtra AI Strings
  String get sutraTitle;
  String get sutraBadge;
  String get sutraSubtitle;
  String get askSutraHeader;
  String get askSutraPlaceholder;
  String get interpretButton;
  String get pendingBadge;
  String get emergencyBadge;
  String get completedBadge;
  String get needsHumanBadge;
  String get needsHumanTab;
  String get activityFeedTab;
  String get composeTab;
  String get activeTasksTab;
  String get composeHeader;
  String get composePlaceholder;
  String get suggestPriorityChip;
  String get pickAssigneeChip;
  String get setDueDateChip;
  String get createTaskButton;
  String get approveButton;
  String get assignButton;
  String get reviewButton;
  String get trackingBadge;

  // My Preferences Strings
  String get myPreferencesTitle;
  String get myPreferencesSubtitle;
  String get profileCardHeader;
  String get yourPermissionsHeader;
  String get dailyDigestHeader;
  String get dailyDigestSubtitle;
  String get taskOperationsHeader;
  String get meetingsEventsHeader;
  String get prefReportsHeader;
  String get notificationTypeHeader;
  String get inAppChannel;
  String get emailChannel;
  String get smsChannel;
  String get whatsappChannel;
  String get pushChannel;

  // My Profile & FAQ Strings
  String get myProfileTitle;
  String get personalInfoSection;
  String get performanceStatsSection;
  String get fullNameLabel;
  String get totalTasksStat;
  String get completedStatLabel;
  String get overdueStatLabel;
  String get currentStreakStat;
  String get totalPointsStat;
  String get onTimeRateStat;
  String get completionRateStat;
  String get faqTitle;
  String get faqSubtitle;
  String get faqQ1;
  String get faqA1;
  String get faqQ2;
  String get faqA2;
  String get faqQ3;
  String get faqA3;
  String get faqQ4;
  String get faqA4;
  String get faqQ5;
  String get faqA5;
}
