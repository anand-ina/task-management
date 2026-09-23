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

  // Forgot Password & Reset Password Strings
  String get forgotPasswordTitle;
  String get forgotPasswordSubtitle;
  String get emailPhoneOrUsernameLabel;
  String get sendResetCodeButton;
  String get backToSignInLink;
  String get resetCodeSentNotice;
  String get enterResetCodeButton;
  String get resetPasswordTitle;
  String get resetPasswordSubtitle;
  String get resetCodeLabel;
  String get resetCodeHint;
  String get newPasswordLabel;
  String get newPasswordHint;
  String get confirmNewPasswordLabel;
  String get resetPasswordButton;

  // Navigation Drawer Headers & Items
  String get dashboard;

  String get organizationOverview;

  String get campusOverview;

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

  String get administrationHeader;

  String get userManagement;

  String get branchesAndDepartments;

  String get reportingStructure;

  String get rolesAndPermissions;

  String get auditLog;

  String get administratorRole;

  String get administratorBadgeScope;

  String get branchesAndDepartmentsSubtitle;

  String get branchesHeader;

  String get departmentsHeader;

  String get codePlaceholder;

  String get branchNamePlaceholder;

  String get newDepartmentPlaceholder;

  String get editButton;

  String get saveButton;
  String get cancelEditButton;

  // Reporting Structure Screen
  String get reportingStructureSubtitle;
  String get personColumn;
  String get reportsToColumn;
  String get dottedLineColumn;
  String get addManagerLabel;
  String get addDottedLabel;
  String get noReportingDataFound;

  // Roles & Permissions Screen
  String get rolesAndPermissionsSubtitle;
  String get addRoleButton;
  String rolesCount(int count);
  String get levelLabel;
  String get permissionsLabel;
  String get usersLabel;
  String get savePermissionsButton;
  String get addRoleTitle;
  String get roleLabelField;
  String get roleKeyField;
  String get roleLevelField;
  String get noRolesFound;

  // Role Badges
  String get academicExecutiveRole;
  String get academicExecutiveScope;

  // New Drawer Headers & Nav Items
  String get adminOrgChart;
  String get myReportingStructure;
  String get rolesAndResponsibilitiesHeader;
  String get myResponsibilities;
  String get myAuditsHeader;
  String get asAnInternalAuditor;
  String get asAnAuditee;

  // Admin Org Chart Screen
  String get adminOrgChartSubtitle;
  String peopleCount(int count);
  String get primaryReportingLegend;
  String get secondaryReportingLegend;
  String get reportsToPrefix;
  String get dottedPrefix;
  String get youBadge;
  String get noOrgChartDataFound;

  // My Reporting Structure Screen
  String get myReportingSubtitle;
  String get meSectionTitle;
  String get iReportToSectionTitle;
  String get reportsToMeSectionTitle;
  String get peersSectionTitle;
  String get shareManagerSubtitle;
  String get primarySolidLegend;
  String get secondaryDottedLegend;
  String get noneText;
  String get noReportingStructureFound;

  // My Responsibilities Screen
  String get myResponsibilitiesSubtitle;
  String get primaryResponsibilitiesTitle;
  String get secondaryResponsibilitiesTitle;
  String get addPrimaryResponsibilityPlaceholder;
  String get addSecondaryResponsibilityPlaceholder;
  String get noneYetText;
  String get noResponsibilitiesFound;

  // My Audits Screens
  String get auditsAuditeeTitle;
  String get auditsAuditeeSubtitle;
  String get noAuditsInvolveYouYet;
  String get auditsAuditorTitle;
  String get auditsAuditorSubtitle;
  String get noAuditsAssignedYet;

  // Audit Log Screen
  String get auditLogSubtitle;
  String get allActivityFilter;
  String get loginAction;
  String get logoutAction;
  String get passwordChangedAction;
  String get noAuditLogsFound;

  // Calendar Navigation
  String get previousMonth;
  String get nextMonth;

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

  String get exportCsv;

  String get exportExcel;

  String get exportPdf;

  String get bulkUploadTasksTitle;

  String get bulkUploadSubtitle;

  String get chooseAFile;

  String get acceptedFormats;

  String get columnsImporterReads;

  String get columnHeader;

  String get exampleHeader;

  String get notesHeader;

  String get rowsFound;

  String get willImport;

  String get skippedCount;

  String get headerRowLabel;

  String get previewTitle;

  String get rowHeader;

  String get taskHeader;

  String get assignedToHeader;

  String get targetHeader;

  String get noteHeader;

  String get chooseAnotherFile;

  String importTasksCount(int count);

  String bulkImportSuccess(int count, String taskNos);

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

  String get discardChangesButton;

  String get typeColumnHeader;

  String get rupeeAmountColumnHeader;

  String get pointsColumnHeader;

  String get deleteFineTypeConfirmTitle;

  String get deleteRewardTypeConfirmTitle;

  String get deleteButton;

  String deleteFineTypeConfirmMessage(String label);

  String deleteRewardTypeConfirmMessage(String label);

  String get addFineTypeDialogTitle;

  String get addRewardTypeDialogTitle;

  String get policyNameLabel;

  String get policyAmountLabel;

  String get policyPointsLabel;

  String get settingsSavedSuccessfully;

  String get fineTypeAddedSuccessfully;

  String get rewardTypeAddedSuccessfully;

  String get fineTypeDeletedSuccessfully;

  String get rewardTypeDeletedSuccessfully;

  String get noChangesToSave;

  String get pleaseEnterValidLabel;

  String get pleaseEnterValidAmount;

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

  // Status Reports
  String get myStatusReports;

  String get myStatusReportsSubtitle;

  String get newReportButton;

  String get newStatusReport;

  String get dailyDsr;

  String get weeklyWsr;

  String get monthlyMsr;

  String get reportTypeLabel;

  String get periodDateLabel;

  String get periodDateHint;

  String get autoFillBannerNote;

  String get workCompletedLabel;

  String get workInProgressLabel;

  String get pendingTasksLabel;

  String get challengesBlockersLabel;

  String get lockedContactDirector;

  String get enterDetailsPlaceholder;

  String get saveDraft;

  String get submitButton;

  String get noClosureRequestsAwaiting;

  String get targetDateChange;

  String get resolveApprove;

  String get saveChanges;

  String get autoStatusReportSlotsToday;

  String get dsrTimeSlot;

  String get completionAwaitingApproval;

  String get noFinesOrRewardsYet;

  String get youHaveNotOrganizedAnyMeetingsYet;

  String get cancelReminderButton;

  String get reportsDashboardSubtitle;

  String get myReportsTitle;

  String get noReportsFound;

  String get complianceTitle;

  String get complianceSubtitle;

  String get noComplianceDataAvailable;

  String noReportDueToday(String type, String nextDue);

  String lastReportCycleInfo(String type, String cycle, int filed, int missed);

  String get whoButton;

  // Complaints & Feedback Module Strings
  String get complaintsAndFeedbackHeader;
  String get complaintsTracker;
  String get suggestionBoxEntry;
  String get historyAndInsights;
  String get appreciationApprovals;

  String get complaintsAndFeedbackTitle;
  String get complaintsAndFeedbackSubtitle;
  String get suggestionBoxEntryButton;
  String get historyAndInsightsButton;
  String get raiseRequestButton;

  String get statNewNotPickedUp;
  String get statInProgress;
  String get statPastTargetDate;
  String get statResolvedThisMonth;
  String get statAwaitingDirectorApproval;
  String get statAvgTimeToResolve;

  String get tabOpen;
  String get tabPastTargetDate;
  String get tabResolved;
  String get tabAll;

  String get searchTicketsPlaceholder;
  String get filterAllTypes;
  String get filterParentsAndStudents;
  String get filterAllCategories;
  String get filterEveryones;

  String get colTicket;
  String get colType;
  String get colFrom;
  String get colStudent;
  String get colAbout;
  String get colCategory;
  String get colStatus;
  String get colWith;
  String get colReceived;
  String get colTask;
  String get noTicketsFound;

  String get raiseARequestTitle;
  String get typeLabel;
  String get typeComplaint;
  String get typeFeedbackSuggestion;
  String get typeAppreciation;
  String get receivedFromLabel;
  String get receivedFromParent;
  String get receivedFromStudent;
  String get channelLabel;
  String get whichGroupPlaceLabel;
  String get whichGroupPlaceHint;
  String get receivedOnLabel;
   String get studentNameLabel;
  String get studentNameHint;
  String get classSectionLabel;
  String get classSectionHint;
  String get admissionNoLabel;
  String get admissionNoHint;
  String get parentNameLabel;
  String get parentNameHint;
  String get parentMobileLabel;
  String get parentMobileHint;
  String get keepParentAnonymous;
  String get keepParentAnonymousSubtext;
  String get aboutLabel;
  String get aboutStaffMember;
  String get aboutDepartment;
  String get aboutTransport;
  String get aboutFacility;
  String get aboutGeneral;
  String get staffMemberSubtext;
  String get notNamedOption;
    String get priorityLabel;
  String get priorityEmergency;
  String get priorityTopMost;
  String get priorityHigh;
  String get priorityMedium;
  String get priorityLow;
  String targetDateDaysFromToday(int days);
  String get visibilityLabel;
  String get visibilityGeneral;
  String get visibilityConfidential;
  String get whatWasSaidLabel;
  String get whatWasSaidHint;
  String get evidenceLabel;
  String get addFileButton;
  String get fileUploadedSuccess;
  String get uploadingFile;
  String bannerTicketTaskCreated(String ticketNo, String taskNo, String ownerName);
  String get registerComplaintButton;
  String get complaintRegisteredTitle;
  String get ticketNumberLabel;
  String get shareNumberNotice;
  String get whatHappensNext;
  String taskAssignedNotice(String taskNo, String owner, String due);
  String whatsappTicketSentNotice(String mobile);
  String get doneButton;
  String get openTicketButton;
  String get fillRequiredFieldsError;
  String get invalidMobileNumberError;

  // Suggestion Box & Filters
   String get assignedByMe;
  String get suggestionBoxEntryTitle;
  String get backToTracker;
  String get suggestionBoxSub;
  String get boxOpenedLabel;
  String get branchPlaceholder;
  String get addRowButton;
  String saveRequestsButton(int count);
  String get savingRequests;
  String get typeAtLeastOneSlipWarning;
  String attachPhotoWarning(int count);
  String registeredBannerTitle(int count);
  String slipTitle(int index);
  String get removeButton;
  String get studentBlankAnonymous;
  String get anonymousHint;
  String get classLabel;
  String get classPlaceholder;
  String get aboutLabelSimple;
  String get generalOption;
  String get staffMemberOption;
  String get transportOption;
  String get facilityOption;
   String get categoryLabelSimple;
  String get whatSlipSays;
  String get typeSlipPlaceholder;
  String get photoOfSlip;
  String get addPhotoButton;
  String get uploadingPhoto;
  String suggestionBoxFootnote(String ownerName, int points);

  // History & Insights
  String get voiceOfParentsAndStudents;
  String academicYearSubtitle(String year);
  String get complaintsAndFeedbacksDashboard;
  String complaintsDashboardSubtitle(String year);
  String get allTicketsButton;
  String get openRightNow;
  String get pastTargetDate;
  String get fromParents;
  String get fromStudents;
  String get fromStaff;
  String get avgDaysToResolve;
  String get complaintsHeader;
  String get feedbackHeader;
  String get appreciationsHeader;
  String get lastHeader;
  String get complaintsDashboardTitle;
  String get receivedPerMonth;
  String get complaintsByCategory;
  String get byStaffMemberDirectorOnly;
  String get byStudentFamily;
  String get statTotalReceived;
  String get staffHeader;
  String get studentHeader;
  String get classHeader;
  String get noDataAvailable;

  // Parents, Students & Staff Complaints
  String get parentsComplaintsAndFeedbacks;
  String get parentsComplaintsSubtitle;
  String get studentsComplaintsAndFeedbacks;
  String get studentsComplaintsSubtitle;
  String get staffComplaintsAndFeedbacks;
  String get staffComplaintsSubtitle;
  String get appreciations;
  String get appreciationsSubtitle;
  String get appreciationsReceived;
  String get recordedBadge;
  String get awaitingDirectorApproval;
  String get rewardPointsGiven;
  String get rewardLabel;
  String get onlyDirectorCanChange;
  String get resolutionLabel;
  String get everyoneScope;
  String get everyonesFilter;
  String get tabEverything;
  String get statEverythingReceived;
  String get filterComplaintsAndFeedback;
  String get filterComplaintsOnly;
  String get filterFeedbackOnly;

  // Task Stats & Filters
  String get statTotalCard;
  String get statNeedsReview;
  String get statAwaitingSignOff;
  String get statAcrossStatuses;
  String get statFootnotePrefix;
  String get statFootnoteOverdue;
  String get statFootnoteSuffix;
  String get createdByAssignedToAll;
  String get createdByMe;
  String get assignedToMe;
  String get anyCompletionPercent;
  String get toLabel;
  String selectAllWithCount(int count);
  String byAuthor(String name);
  String subtasksCountBadge(int done, int total);
  String get taskNoPrefix;
  String get completion0;
  String get completion1To25;
  String get completion26To50;
  String get completion51To75;
  String get completion76To99;
  String get completion100;
  String get newRecurringButton;
  String get newTaskButton;
  String get bulkUploadButton;
  String get categoryAll;
  String get categoryConfidential;
  String get categoryGeneral;
  String get viewList;
  String get viewBoard;
  String get viewCalendar;
  String get statComplaints;
  String get statFeedback;
  String get statAppreciations;
  String get taskIdSettings;
  String get taskIdSettingsSubtitle;
  String get counterPerBranch;
  String get counterPerBranchSubtitle;
  String get resetTo0001;
  String get resetEveryBranch;
  String get lastUsed;
  String get nextTaskId;
  String get lastReset;
  String get complaintsDeskTitle;
  String get complaintsDeskSubtitle;
  String get fallbackLabel;
  String get automaticCurrentlyPrefix;
  String get resetConfirmTitle;
  String resetConfirmMessage(String branch);
  String get resetAllConfirmTitle;
  String get resetAllConfirmMessage;
  String get centerHeadPrincipalRole;
  String get teamLeadRole;
  String get managerRole;
  String centerHeadPrincipalScope(int count);
  String get operationalScopeYourOwn;

  String get moreFilters;
  String get confidentialAndGeneral;
  String get confidentialOnly;
  String get generalOnly;
  String get updateEdit;
  String get changeStatusTitle;
  String get newStatusLabel;
  String get completionLabel;
  String get commentRequiredLabel;
  String get commentPlaceholder;
  String get addFiles;
  String get attachmentsLabel;
  String get commentRequiredError;
  String get taskUpdatedSuccess;
  String get blockedStatus;

  // Ticket Details & Actions Dialog Strings
  String get linkedTask;
  String get openTask;
  String get assignTo;
  String get assignThisTicket;
  String get searchPeoplePlaceholder;
  String get whatShouldTheyDoPlaceholder;
   String get closeTheLoop;
  String get resolveTab;
  String get notValidTab;
  String get whatWasDonePlaceholder;
  String get reasonWhyNotValidPlaceholder;
  String get markResolvedButton;
  String get closeAsNotValidButton;
  String get downloadLabel;
  String get evidenceVisibleCampusHeadOnly;
  String get historyLabel;
  String get detailsSectionLabel;
  String get confidentialBadge;
  String get editTicketButton;
  String get anonymousHidden;
  String get editTicketTitlePrefix;
   String get classAndSectionLabel;
    String get detailsLabel;
   String get addEvidenceLabel;
   String get reasonForChangeLabel;
  String get reasonForChangePlaceholder;
  String get saveChangesButton;
   String get campusHeadLabel;
   String get closedSectionLabel;
   String get resolvedSectionLabel;

  // Audit Execution & Scheduling Strings
  String get scheduleAnAudit;
  String get auditTitleLabel;
  String get scopeNoteLabel;
  String get auditorLabel;
  String get auditeeTypeLabel;
  String get auditeeLabel;
  String get scheduledDateLabel;
  String get dueDateLabel;
  String get checklistOnePerLine;
  String get scheduleAuditButton;
  String get closeAudit;
  String get conductedBy;
  String get scheduledFor;
  String get dueOn;
  String get closedOn;
  String get noAuditsFound;
  String get threeMonthsView;
  String get eventsInTheseThreeMonths;
  String get listViewLabel;
  String get fineLabel;
  String get issuedByLabel;
  String get policyRules;
  String get availablePointsLabel;
  String get scopeEveryone;
  String get scopeParents;
  String get scopeStudents;
  String get scopeStaff;
  String get studentFamilyListTitle;
  String get lastRecordedLabel;
  String get branchScopeLabel;

  // ── Clone Task Strings ─────────────────────────────────────────────────────
  String get cloneTaskTitle;
  String get cloneTaskBannerHint;
  String get taskIdLabel;
  String get taskTitleLabel;
  String get taskDescLabel;
   String get schoolBranchLabel;
   String get targetDateLabel;
   String get confidentialLabel;
  String get generalLabel;
  String get makeRecurringLabel;
  String get assignedToLabel;
  String get searchUsersHint;
   String get addFilesButton;
  String get taskChecklistLabel;
  String get generateButton;
  String get addItemButton;
  String get remarksLabel;
  String get saveDraftButton;
  String get saveTaskButton;

  String get statusLabel;

  // ── Status Report PDF Strings ──────────────────────────────────────────────
  String get savePdfButton;
  String get statusReportPdfTitle;

  String get submittedAtLabel;
  String get exportedOnLabel;
  String get unlockReportButton;

  // ── Appreciation Award Strings ─────────────────────────────────────────────
  String get rewardDirectorOnly;
  String get updateFacultyAndPoints;
  String get rewardPointsLabel;
  String get facultyLabel;
  String get reasonRequiredLabel;
  String get whyIsThisBeingChangedHint;
  String get pointsUpdatedSuccessfully;
  String get pleaseEnterPoints;
  String get pleaseEnterReason;
  String get selectFacultyPrompt;
  String get searchFacultyPlaceholder;
  String get changingThisMovesPoints;
}
