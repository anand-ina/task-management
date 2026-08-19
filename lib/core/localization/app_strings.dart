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

  // Dialogs & Safety
  String get noInternetTitle;
  String get noInternetMessage;
  String forceLogoutNotice(int seconds);
  String get retryButton;
  String get exitAppTitle;
  String get exitAppMessage;
  String get cancelButton;
  String get exitButton;
}
