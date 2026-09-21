import 'app_strings.dart';

class AppStringsHi extends AppStrings {
  @override
  String get appTitle => 'संस्कार टास्क मैनेजर';
  @override
  String get welcomeBack => 'वापसी पर स्वागत है';
  @override
  String get signInToAccount => 'अपने खाते में साइन इन करें';
  @override
  String get quickLoginAs => 'त्वरित लॉगिन करें';
  @override
  String get credentials => 'लॉगिन क्रेडेंशियल';
  @override
  String get emailLabel => 'ईमेल पता';
  @override
  String get passwordLabel => 'पासवर्ड';
  @override
  String get signInButton => 'साइन इन करें';
  @override
  String get demoPasswordHint => 'डेमो पासवर्ड: Samskar@123';

  @override
  String get forgotPasswordTitle => 'पासवर्ड भूल गए';
  @override
  String get forgotPasswordSubtitle => 'अपना ईमेल, फोन या उपयोगकर्ता नाम दर्ज करें। हम व्हाट्सएप (और ईमेल) द्वारा 6 अंकों का रीसेट कोड भेजेंगे।';
  @override
  String get emailPhoneOrUsernameLabel => 'ईमेल, फोन या उपयोगकर्ता नाम';
  @override
  String get sendResetCodeButton => 'रीसेट कोड भेजें';
  @override
  String get backToSignInLink => 'साइन इन पर वापस जाएं';
  @override
  String get resetCodeSentNotice => 'यदि खाता मौजूद है, तो एक रीसेट कोड आ रहा है। इसे अगली स्क्रीन पर दर्ज करें।';
  @override
  String get enterResetCodeButton => 'रीसेट कोड दर्ज करें';
  @override
  String get resetPasswordTitle => 'पासवर्ड रीसेट करें';
  @override
  String get resetPasswordSubtitle => 'आपको प्राप्त 6 अंकों का कोड दर्ज करें और एक नया पासवर्ड चुनें।';
  @override
  String get resetCodeLabel => 'रीसेट कोड';
  @override
  String get resetCodeHint => '6 अंकों का कोड';
  @override
  String get newPasswordLabel => 'नया पासवर्ड';
  @override
  String get newPasswordHint => 'न्यूनतम 8 अक्षर, एक अक्षर और एक संख्या';
  @override
  String get confirmNewPasswordLabel => 'नए पासवर्ड की पुष्टि करें';
  @override
  String get resetPasswordButton => 'पासवर्ड रीसेट करें';


  @override
  String get dashboard => 'डैशबोर्ड';
  @override
  String get organizationOverview => 'संगठन अवलोकन';
  @override
  String get campusOverview => 'परिसर अवलोकन';
  @override
  String get tasksHeader => 'कार्य (TASKS)';
  @override
  String get allTasks => 'सभी कार्य';
  @override
  String get myTasks => 'मेरे कार्य';
  @override
  String get recurringTasks => 'आवर्ती कार्य';
  @override
  String get approvalsHeader => 'स्वीकृतियां';
  @override
  String get taskApprovals => 'कार्य स्वीकृतियां';
  @override
  String get escalations => 'वृद्धि (Escalations)';
  @override
  String get meetingApprovals => 'बैठक स्वीकृतियां';
  @override
  String get budgetApprovals => 'बजट स्वीकृतियां';
  @override
  String get meetingsHeader => 'बैठकें';
  @override
  String get monthlyOneOnOnePending => 'मासिक 1:1 लंबित';
  @override
  String get myScheduledMeetings => 'मेरी निर्धारित बैठकें';
  @override
  String get meetingCalendar => 'बैठक कैलेंडर';
  @override
  String get eventsHeader => 'कार्यक्रम';
  @override
  String get events => 'कार्यक्रम (Events)';
  @override
  String get eventsCalendar => 'कार्यक्रम कैलेंडर';
  @override
  String get reportsHeader => 'रिपोर्ट्स';
  @override
  String get statusReports => 'स्थिति रिपोर्ट्स';
  @override
  String get reportsDashboard => 'रिपोर्ट्स डैशबोर्ड';
  @override
  String get todoHeader => 'टू-डू';
  @override
  String get today => 'आज';
  @override
  String get history => 'इतिहास';
  @override
  String get performanceHeader => 'प्रदर्शन';
  @override
  String get leaderboard => 'लीडरबोर्ड';
  @override
  String get teamPerformance => 'टीम प्रदर्शन';
  @override
  String get finesAndRewards => 'दंड और पुरस्कार';
  @override
  String get settings => 'सेटिंग्स';
  @override
  String get organizationHeader => 'संगठन';
  @override
  String get staff => 'कर्मचारी (Staff)';
  @override
  String get administrationHeader => 'प्रशासन (Administration)';
  @override
  String get userManagement => 'उपयोगकर्ता प्रबंधन';
  @override
  String get branchesAndDepartments => 'शाखाएं और विभाग';
  @override
  String get reportingStructure => 'रिपोर्टिंग संरचना';
  @override
  String get rolesAndPermissions => 'भूमिकाएं और अनुमतियां';
  @override
  String get auditLog => 'ऑडिट लॉग';
  @override
  String get administratorRole => 'प्रशासक (Administrator)';
  @override
  String get administratorBadgeScope => 'पूरा संगठन अवलोकन — प्रत्येक परिसर और विभाग।';
  @override
  String get branchesAndDepartmentsSubtitle => 'शाखाओं और विभागों को जोड़ें और उनका नाम बदलें, और प्रत्येक से जुड़े उपयोगकर्ताओं को देखें।';
  @override
  String get branchesHeader => 'शाखाएं (Branches)';
  @override
  String get departmentsHeader => 'विभाग (Departments)';
  @override
  String get codePlaceholder => 'कोड';
  @override
  String get branchNamePlaceholder => 'शाखा का नाम';
  @override
  String get newDepartmentPlaceholder => 'नया विभाग';
  @override
  String get editButton => 'संपादित करें (Edit)';
  @override
  String get saveButton => 'सहेजें';
  @override
  String get cancelEditButton => 'रद्द करें';
  @override
  String get reportingStructureSubtitle => 'संगठन में कौन किसे रिपोर्ट करता है';
  @override
  String get personColumn => 'व्यक्ति';
  @override
  String get reportsToColumn => 'रिपोर्ट करता है (प्राथमिक)';
  @override
  String get dottedLineColumn => 'डॉटेड-लाइन (द्वितीयक)';
  @override
  String get addManagerLabel => '+ प्रबंधक जोड़ें...';
  @override
  String get addDottedLabel => '+ डॉटेड जोड़ें...';
  @override
  String get noReportingDataFound => 'कोई रिपोर्टिंग डेटा नहीं मिला।';
  @override
  String get rolesAndPermissionsSubtitle => 'प्रत्येक भूमिका क्या देख और कर सकती है';
  @override
  String get addRoleButton => '+ भूमिका जोड़ें';
  @override
  String rolesCount(int count) => '$count भूमिकाएं';
  @override
  String get levelLabel => 'स्तर';
  @override
  String get permissionsLabel => 'अनुमतियाँ';
  @override
  String get usersLabel => 'उपयोगकर्ता';
  @override
  String get savePermissionsButton => 'अनुमतियाँ सहेजें';
  @override
  String get addRoleTitle => 'नई भूमिका जोड़ें';
  @override
  String get roleLabelField => 'भूमिका लेबल (प्रदर्शन नाम)';
  @override
  String get roleKeyField => 'भूमिका कुंजी (सिस्टम नाम)';
  @override
  String get roleLevelField => 'स्तर (1–5)';
  @override
  String get noRolesFound => 'कोई भूमिका नहीं मिली।';

  // Role Badges
  @override
  String get academicExecutiveRole => 'अकादमिक कार्यकारी (Academic Executive)';
  @override
  String get academicExecutiveScope => 'परिचालन दायरा — आपके अपने कार्य और रिपोर्ट।';

  // New Drawer Headers & Nav Items
  @override
  String get adminOrgChart => 'व्यवस्थापक संगठनात्मक चार्ट';
  @override
  String get myReportingStructure => 'मेरी रिपोर्टिंग संरचना';
  @override
  String get rolesAndResponsibilitiesHeader => 'भूमिकाएं और जिम्मेदारियां';
  @override
  String get myResponsibilities => 'मेरी जिम्मेदारियां';
  @override
  String get myAuditsHeader => 'मेरे ऑडिट';
  @override
  String get asAnInternalAuditor => 'आंतरिक लेखा परीक्षक के रूप में';
  @override
  String get asAnAuditee => 'एक लेखा परीक्षार्थी के रूप में';

  // Admin Org Chart Screen
  @override
  String get adminOrgChartSubtitle => 'प्रशासन टीम की रिपोर्टिंग संरचना — प्रकाशित संगठन चार्ट से प्रतिबिंबित।';
  @override
  String peopleCount(int count) => '$count लोग';
  @override
  String get primaryReportingLegend => 'प्राथमिक रिपोर्टिंग (ठोस)';
  @override
  String get secondaryReportingLegend => 'द्वितीयक / डॉटेड लाइन';
  @override
  String get reportsToPrefix => 'रिपोर्ट करता है';
  @override
  String get dottedPrefix => 'डॉटेड:';
  @override
  String get youBadge => 'आप';
  @override
  String get noOrgChartDataFound => 'कोई संगठन चार्ट डेटा नहीं मिला।';

  // My Reporting Structure Screen
  @override
  String get myReportingSubtitle => 'आप किसे रिपोर्ट करते हैं, और कौन आपको रिपोर्ट करता है।';
  @override
  String get meSectionTitle => 'मैं';
  @override
  String get iReportToSectionTitle => 'मैं रिपोर्ट करता हूँ';
  @override
  String get reportsToMeSectionTitle => 'मुझे रिपोर्ट करते हैं';
  @override
  String get peersSectionTitle => 'सहकर्मी';
  @override
  String get shareManagerSubtitle => 'एक प्रबंधक साझा करते हैं';
  @override
  String get primarySolidLegend => 'प्राथमिक (ठोस)';
  @override
  String get secondaryDottedLegend => 'माध्यमिक (बिंदीदार)';
  @override
  String get noneText => 'कोई नहीं।';
  @override
  String get noReportingStructureFound => 'कोई रिपोर्टिंग संरचना नहीं मिली।';

  // My Responsibilities Screen
  @override
  String get myResponsibilitiesSubtitle => 'आपकी प्राथमिक और द्वितीयक जिम्मेदारी के क्षेत्र।';
  @override
  String get primaryResponsibilitiesTitle => 'प्राथमिक';
  @override
  String get secondaryResponsibilitiesTitle => 'द्वितीयक';
  @override
  String get addPrimaryResponsibilityPlaceholder => 'एक प्राथमिक जिम्मेदारी जोड़ें...';
  @override
  String get addSecondaryResponsibilityPlaceholder => 'एक द्वितीयक जिम्मेदारी जोड़ें...';
  @override
  String get noneYetText => 'अभी तक कोई नहीं।';
  @override
  String get noResponsibilitiesFound => 'कोई जिम्मेदारी नहीं मिली।';

  // My Audits Screens
  @override
  String get auditsAuditeeTitle => 'मेरे ऑडिट — एक परीक्षार्थी के रूप में';
  @override
  String get auditsAuditeeSubtitle => 'आप पर, आपके विभाग या शाखा पर किए गए ऑडिट। निष्कर्षों का जवाब दें और उन्हें हल करें।';
  @override
  String get noAuditsInvolveYouYet => 'अभी तक कोई ऑडिट आप पर नहीं है।';
  @override
  String get auditsAuditorTitle => 'मेरे ऑडिट — एक आंतरिक लेखा परीक्षक के रूप में';
  @override
  String get auditsAuditorSubtitle => 'वे ऑडिट जिन्हें आप संचालित कर रहे हैं या जिनमें भाग ले रहे हैं।';
  @override
  String get noAuditsAssignedYet => 'अभी तक आपको कोई ऑडिट नहीं सौंपा गया है।';

  // Audit Log Screen
  @override
  String get auditLogSubtitle => 'उपयोगकर्ता निर्माण, पासवर्ड परिवर्तन और लॉगिन / लॉगआउट गतिविधि।';
  @override
  String get allActivityFilter => 'सभी गतिविधि';
  @override
  String get loginAction => 'लॉगिन';
  @override
  String get logoutAction => 'लॉगआउट';
  @override
  String get passwordChangedAction => 'पासवर्ड बदला गया';
  @override
  String get noAuditLogsFound => 'कोई ऑडिट लॉग नहीं मिला।';

  // Calendar Navigation
  @override
  String get previousMonth => 'पिछला महीना';
  @override
  String get nextMonth => 'अगला महीना';

  @override
  String get aiAndSettingsHeader => 'एआई और सेटिंग्स';
  @override
  String get sutraAi => 'सूत्र एआई';
  @override
  String get myPreferences => 'मेरी प्राथमिकताएं';
  @override
  String get directorBadgeScope => 'पूरा संगठन अवलोकन — हर परिसर और विभाग।';

  @override
  String get searchPlaceholder => 'कार्य, लोग, रिपोर्ट खोजें...';
  @override
  String get newButton => '+ नया';
  @override
  String get newTask => 'नया कार्य';
  @override
  String get newTodo => 'नया टू-डू';
  @override
  String get newMeeting => 'नई बैठक';
  @override
  String get newEvent => 'नया कार्यक्रम';
  @override
  String get allBranches => 'सभी शाखाएं';
  @override
  String get directorRole => 'निदेशक';
  @override
  String get myProfile => 'मेरी प्रोफ़ाइल';
  @override
  String get faq => 'अक्सर पूछे जाने वाले प्रश्न';
  @override
  String get logout => 'लॉग आउट';

  @override
  String get directorHeadOffice => 'निदेशक · मुख्य कार्यालय';
  @override
  String get greetingNamaste => 'नमस्ते, वामसी 🙏';
  @override
  String get dashboardSubtitle => 'हर परिसर और विभाग में पूरा संगठन अवलोकन।';
  @override
  String approvalsBadge(int count) => '$count स्वीकृतियां';
  @override
  String toStartBadge(int count) => '$count शुरू करने के लिए';
  @override
  String inProgressBadge(int count) => '$count प्रगति में';
  @override
  String overdueBadge(int count) => '$count अतिदेय';
  @override
  String completionBadge(int rate) => '$rate% पूर्णता';

  @override
  String get performanceTitle => 'मेरा प्रदर्शन';
  @override
  String get performanceSubtitle => 'अवधि के अनुसार पूर्णता';
  @override
  String get dayWise => 'दैनिक';
  @override
  String get weekWise => 'साप्ताहिक';
  @override
  String get monthWise => 'मासिक';
  @override
  String get quarterly => 'त्रैमासिक';
  @override
  String get yearly => 'वार्षिक';

  @override
  String get tasksByPriority => 'प्राथमिकता के अनुसार मेरे कार्य';
  @override
  String get emergencyPriority => 'आपातकालीन';
  @override
  String get topMostPriority => 'सर्वोच्च';
  @override
  String get highPriority => 'उच्च';
  @override
  String get mediumPriority => 'मध्यम';
  @override
  String get lowPriority => 'निम्न';

  @override
  String get totalOrganisation => 'कुल संगठन';
  @override
  String get readOnlyTransparency => 'केवल पढ़ने योग्य पारदर्शिता';
  @override
  String get totalTasks => 'कुल कार्य';
  @override
  String get completed => 'पूरा हुआ';
  @override
  String get inProgress => 'प्रगति पर है';
  @override
  String get overdue => 'अतिदेय';
  @override
  String get dropped => 'छोड़ दिया गया';

  @override
  String get recentActivityTitle => 'हाल की गतिविधि';
  @override
  String get teamLoginAnalyticsTitle => 'टीम लॉगिन विश्लेषण';
  @override
  String get activeToday => 'आज सक्रिय';
  @override
  String get daysAway1To3 => '1-3 दिन दूर';
  @override
  String get daysAway4To6 => '4-6 दिन दूर';
  @override
  String get daysAway7Plus => '7+ दिन दूर';
  @override
  String get neverSignedIn => 'कभी साइन इन नहीं किया';

  @override
  String get todoTodayTitle => 'आज का टू-डू';
  @override
  String get todoTodaySubtitle => 'आज के लिए अपने प्रमुख कार्यों को प्रबंधित करें';
  @override
  String get reviewPendingApprovals => 'लंबित कार्य स्वीकृतियों की समीक्षा करें';
  @override
  String get checkScheduledMeetings => 'सप्ताह के लिए निर्धारित बैठकों की जाँच करें';
  @override
  String get addNotePlaceholder => 'एक त्वरित टिप्पणी या कार्य जोड़ें...';
  @override
  String get addButton => 'जोड़ें';

  @override
  String get appearance => 'उपस्थिति';
  @override
  String get appearanceSubtitle => 'एप्लिकेशन थीम अनुकूलित करें';
  @override
  String get themeMode => 'थीम मोड';
  @override
  String get themeLight => 'लाइट मोड';
  @override
  String get themeDark => 'डार्क मोड';
  @override
  String get themeSystem => 'सिस्टम थीम';
  @override
  String get language => 'भाषा';
  @override
  String get languageSubtitle => 'एप्लिकेशन प्रदर्शन भाषा चुनें';
  @override
  String get langEnglish => 'English';
  @override
  String get langTelugu => 'తెలుగు (Telugu)';
  @override
  String get langHindi => 'हिंदी (Hindi)';
  @override
  String get langKannada => 'ಕನ್ನಡ (Kannada)';

  @override
  String get toBeStarted => 'शुरू किया जाना है';
  @override
  String get workUnderway => 'कार्य जारी है';
  @override
  String get needsAttention => 'ध्यान देने की आवश्यकता है';
  @override
  String get notYetPickedUp => 'अभी तक शुरू नहीं हुआ';
  @override
  String get closedWithoutCompletion => 'बिना पूरा किए बंद';

  @override
  String get actionCenterTitle => 'एक्शन सेंटर';
  @override
  String get clickRowToOpen => 'खोलने के लिए पंक्ति पर क्लिक करें';
  @override
  String get approvalsToReview => 'समीक्षा के लिए स्वीकृतियां';
  @override
  String get overdueTasks => 'अतिदेय कार्य';
  @override
  String get dueToday => 'आज देय';
  @override
  String get emergencyHighOpen => 'आपातकालीन + उच्च (खुला)';

  @override
  String get noMeetingsScheduled => 'आज कोई बैठक निर्धारित नहीं है।';

  @override
  String get myLoginActivityTitle => 'मेरी लॉगिन गतिविधि';
  @override
  String get loginsToday => 'आज लॉगिन';
  @override
  String get loginsThisWeek => 'इस सप्ताह लॉगिन';
  @override
  String get activeTodaySpan => 'आज सक्रिय (प्रथम से अंतिम)';
  @override
  String get activeThisWeekSpan => 'इस सप्ताह सक्रिय';
  @override
  String get firstLoginToday => 'आज पहला लॉगिन';
  @override
  String get activeDays => 'सक्रिय दिन';
  @override
  String get lastLoginLabel => 'अंतिम लॉगिन';
  @override
  String get activeSpanNotice => '"सक्रिय" = आपके पहले से अंतिम साइन-इन की अवधि।';

  @override
  String get overdueTasksByAgeTitle => 'आयु के अनुसार अतिदेय कार्य';
  @override
  String get overdueTasksByAgeSubtitle =>
      'अतिदेय कार्यों का समूह इस आधार पर कि वे कितने विलंबित हैं';
  @override
  String get days1To3 => '1–3 दिन';
  @override
  String get days4To7 => '4–7 दिन';
  @override
  String get days8To14 => '8–14 दिन';
  @override
  String get days15Plus => '15+ दिन';

  @override
  String get myTeam => 'मेरी टीम';
  @override
  String get membersLabel => 'सदस्य';
  @override
  String get teamWide => 'टीम-व्यापी';
  @override
  String get clickRowForDetails => 'विवरण के लिए पंक्ति पर क्लिक करें';
  @override
  String get recentActivityDetail => 'हाल की गतिविधि विवरण';
  @override
  String get viewTask => 'कार्य देखें';
  @override
  String get branchLabel => 'शाखा';
  @override
  String get dueLabel => 'देय';
  @override
  String get completedLabel => 'पूरा हुआ';
  @override
  String get clickGroupForMembers => 'सदस्यों के लिए समूह पर क्लिक करें';

  @override
  String get noInternetTitle => 'कृपया इंटरनेट कनेक्ट करें';
  @override
  String get noInternetMessage => 'कोई इंटरनेट कनेक्शन नहीं मिला। आगे बढ़ने के लिए कृपया इंटरनेट कनेक्ट करें।';
  @override
  String forceLogoutNotice(int seconds) =>
      'कृपया इंटरनेट कनेक्ट करें। $seconds सेकंड में बलपूर्वक लॉग आउट कर दिया जाएगा...';
  @override
  String get retryButton => 'पुनः प्रयास करें';
  @override
  String get exitAppTitle => 'ऐप से बाहर निकलें';
  @override
  String get exitAppMessage => 'क्या आप निश्चित रूप से ऐप से बाहर निकलना चाहते हैं?';
  @override
  String get cancelButton => 'रद्द करें';
  @override
  String get exitButton => 'बाहर निकलें';

  @override
  String get tasksDueTodayTitle => 'आज देय कार्य';
  @override
  String get showingRangeText => '10 में से 1–10 दिखा रहा है';
  @override
  String get sortByLabel => 'क्रमानुसार';
  @override
  String get entryDateLabel => 'प्रविष्टि तिथि';
  @override
  String get branchLegendLabel => 'शाखा विवरण';
  @override
  String get taskIdHeader => 'कार्य आईडी';
  @override
  String get descriptionHeader => 'विवरण';
  @override
  String get branchHeader => 'शाखा';
  @override
  String get priorityHeader => 'प्राथमिकता';
  @override
  String get statusHeader => 'स्थिति';
  @override
  String get dueHeader => 'देय तिथि';
  @override
  String get assignedByLabel => 'द्वारा सौंपा गया';
  @override
  String get categoryLabel => 'श्रेणी';
  @override
  String get locationLabel => 'स्थान';
  @override
  String get assigneesLabel => 'सौंपे गए सदस्य';
  @override
  String get activityLabel => 'गतिविधि';
  @override
  String get closeButton => 'बंद करें';

  @override
  String get everyCampusDeptAtAGlance => 'प्रत्येक परिसर और विभाग एक नज़र में';
  @override
  String get byBranchUnit => 'शाखा इकाई द्वारा';
  @override
  String get searchBranchPlaceholder => 'शाखा खोजें...';
  @override
  String get clickRowOrFilterTopBar => 'पंक्ति पर क्लिक करें या शीर्ष बार से फ़िल्टर करें';
  @override
  String get analyticsTitle => 'विश्लेषण';
  @override
  String get exportButton => 'निर्यात';
  @override
  String get organizationWide => 'संगठन-व्यापी';
  @override
  String get trendsOverTime => 'समय के साथ रुझान — निर्मित बनाम पूर्ण';
  @override
  String get weeklyBucket => 'साप्ताहिक';
  @override
  String get monthlyBucket => 'मासिक';
  @override
  String get quarterlyBucket => 'तिमाही';
  @override
  String get yearlyBucket => 'वार्षिक';
  @override
  String get createdLegend => 'निर्मित';
  @override
  String get completedLegend => 'पूर्ण';
  @override
  String get onTimeCompletionDueWindow => 'समय पर पूर्णता (देय विंडो द्वारा)';
  @override
  String get taskStatusDistribution => 'कार्य स्थिति वितरण';
  @override
  String get priorityLoadTitle => 'प्राथमिकता लोड';
  @override
  String get completionByBranch => 'शाखा द्वारा पूर्णता';
  @override
  String get workloadByDeadlineOpenTasks => 'समय सीमा के अनुसार कार्यभार (खुले कार्य)';

  @override
  String get tasksInYourScope => 'आपके दायरे में कार्य';
  @override
  String get needsAction => 'कार्रवाई की आवश्यकता है';
  @override
  String get newRecurring => 'नया आवर्ती कार्य';
  @override
  String get bulkUpload => 'थोक अपलोड';
  @override
  String get exportCsv => 'CSV निर्यात';
  @override
  String get exportExcel => 'Excel निर्यात';
  @override
  String get exportPdf => 'PDF निर्यात';
  @override
  String get bulkUploadTasksTitle => 'थोक अपलोड कार्य';
  @override
  String get bulkUploadSubtitle => 'एक्सेल या सीएसवी · पुष्टि करने तक कुछ भी\n सहेजा नहीं जाएगा';
  @override
  String get chooseAFile => 'एक फ़ाइल चुनें';
  @override
  String get acceptedFormats => 'स्वीकृत: .xlsx, .xls, .csv';
  @override
  String get columnsImporterReads => 'इम्पोर्टर द्वारा पढ़े जाने वाले कॉलम';
  @override
  String get columnHeader => 'कॉलम हेडर';
  @override
  String get exampleHeader => 'उदाहरण';
  @override
  String get notesHeader => 'टिप्पणियाँ';
  @override
  String get rowsFound => 'पाई गई पंक्तियाँ';
  @override
  String get willImport => 'आयात होगा';
  @override
  String get skippedCount => 'छोड़ा गया';
  @override
  String get headerRowLabel => 'हेडर पंक्ति';
  @override
  String get previewTitle => 'पूर्वावलोकन';
  @override
  String get rowHeader => 'पंक्ति';
  @override
  String get taskHeader => 'कार्य';
  @override
  String get assignedToHeader => 'सौंपा गया';
  @override
  String get targetHeader => 'लक्ष्य तिथि';
  @override
  String get noteHeader => 'टिप्पणी';
  @override
  String get chooseAnotherFile => 'दूसरी फ़ाइल चुनें';
  @override
  String importTasksCount(int count) => '$count कार्य आयात करें';
  @override
  String bulkImportSuccess(int count, String taskNos) => 'सफलतापूर्वक $count कार्य आयात किए गए: $taskNos';
  @override
  String get allScope => 'सभी';
  @override
  String get confidentialScope => 'गोपनीय';
  @override
  String get generalScope => 'सामान्य';
  @override
  String get searchTasksPlaceholder => 'कार्य खोजें...';
  @override
  String get allStatuses => 'सभी स्थितियाँ';
  @override
  String get allPriorities => 'सभी प्राथमिकताएं';
  @override
  String get selectAllText => 'सभी का चयन करें';

  @override
  String get tasksAssignedToOrCreatedByYou => 'आपको सौंपे गए या आपके द्वारा बनाए गए कार्य';
  @override
  String get repeatingDutiesAutoGenerated => 'आवर्ती कर्तव्य — अनुसूची पर \nस्वचालित रूप से उत्पन्न';
  @override
  String get dailyFrequency => 'दैनिक';
  @override
  String get weeklyFrequency => 'साप्ताहिक';
  @override
  String get monthlyFrequency => 'मासिक';
  @override
  String get biMonthlyFrequency => 'द्वि-मासिक';
  @override
  String get quarterlyFrequency => 'त्रैमासिक';
  @override
  String get halfYearlyFrequency => 'अर्ध-वार्षिक';
  @override
  String get yearlyFrequency => 'वार्षिक';
  @override
  String get othersFrequency => 'अन्य';
  @override
  String get listView => 'सूची';
  @override
  String get boardView => 'बोर्ड';
  @override
  String get calendarView => 'कैलेंडर';

  @override
  String get staffWhoHaventCompletedMandatory => 'वे कर्मचारी जिन्होंने आपके साथ इस \nमहीने की अनिवार्य 1:1 बैठक पूरी नहीं की है।';
  @override
  String get scheduleOneOnOne => '1:1 अनुसूची करें';
  @override
  String get oneOnOnePendingBadge => '1:1 लंबित';
  @override
  String get meetingsYouOrganizeOrInvitedTo => 'बैठकें जिन्हें आप आयोजित करते हैं या जिनमें आपको आमंत्रित किया जाता है';
  @override
  String get previewReminder => 'रिमाइंडर का पूर्वावलोकन';
  @override
  String get initiatedByMe => 'मेरे द्वारा शुरू की गई';
  @override
  String get receivedByMe => 'मुझे प्राप्त हुई';
  @override
  String get joinMarkAttended => 'शामिल हों / उपस्थित चिह्नित करें';
  @override
  String get meetingHappened => 'बैठक हुई';
  @override
  String get reminderText => 'रिमाइंडर';

  @override
  String get scheduleAMeetingTitle => 'एक बैठक निर्धारित करें';
  @override
  String get meetingTitleLabel => 'शीर्षक';
  @override
  String get meetingTitleHint => 'जैसे, शुल्क समाधान समीक्षा';
  @override
  String get mandatoryOneOnOneDirectorLabel => 'निदेशक के साथ अनिवार्य मासिक 1:1 — निदेशक स्वचालित रूप से जोड़े जाते हैं; पूरा होने पर इसे पूर्ण चिह्नित करें।';
  @override
  String get dateLabel => 'तिथि';
  @override
  String get timeLabel => 'समय';
  @override
  String get durationLabel => 'अवधि';
  @override
  String get inviteesAvailabilityHeader => 'आमंत्रित और उपलब्धता — प्रत्येक को अनिवार्य या वैकल्पिक के रूप में सेट करें';
  @override
  String get sendRequestButton => 'अनुरोध भेजें';
  @override
  String get freeStatus => 'मुफ्त / उपलब्ध';
  @override
  String get busyStatus => 'व्यस्त';
  @override
  String get notificationsTitle => 'सूचनाएं';
  @override
  String get markAllAsRead => 'सभी को पढ़ा हुआ चिह्नित करें';
  @override
  String get noNotifications => 'कोई सूचना नहीं मिली';
  @override
  String get previewRemindersButton => 'रिमाइंडर का पूर्वावलोकन';
  @override
  String get meetingsOrganizeOrInvitedSubtitle => 'बैठकें जिन्हें आप आयोजित करते हैं या जिनमें आपको आमंत्रित किया जाता है · DSR/WSR/MSR स्लॉट स्वचालित रूप से जोड़े गए';
  @override
  String get joinMarkAttendedButton => 'शामिल हों / उपस्थित चिह्नित करें';
  @override
  String get meetingHappenedButton => 'बैठक हुई';
  @override
  String get reminderButton => 'रिमाइंडर';
  @override
  String get allTab => 'सभी';
  @override
  String get meetingCalendarSubtitle => 'अपनी बैठकों और ऑटो स्थिति-रिपोर्ट स्लॉट ब्राउज़ करें — दिन, कार्य सप्ताह, सप्ताह या महीना';
  @override
  String get todayButton => 'आज';
  @override
  String get dayView => 'दिन';
  @override
  String get workWeekView => 'कार्य सप्ताह';
  @override
  String get weekView => 'सप्ताह';
  @override
  String get monthView => 'महीना';

  @override
  String get eventsTitle => 'कार्यक्रम';
  @override
  String get eventsSubtitle => 'चेकलिस्ट और प्रगति के साथ बहु-विभागीय कार्यक्रम';
  @override
  String get eventsCalendarTitle => 'कार्यक्रम कैलेंडर';
  @override
  String get eventsCalendarSubtitle => 'महीने के अनुसार सभी परिसरों में स्कूल कार्यक्रम';
  @override
  String get assignedToMeTab => 'मुझे सौंपे गए';
  @override
  String get eventsTab => 'कार्यक्रम';
  @override
  String get checklistLabel => 'चेकलिस्ट';

  @override
  String get reportsDashboardTitle => 'रिपोर्ट डैशबोर्ड';
  @override
  String get submittedTodayLabel => 'आज प्रस्तुत किए गए';
  @override
  String get totalReportsLabel => 'कुल रिपोर्ट';
  @override
  String get submittedLabel => 'प्रस्तुत की गई';
  @override
  String get draftLabel => 'ड्राफ्ट';
  @override
  String get dailyDsrLabel => 'दैनिक (DSR)';
  @override
  String get weeklyWsrLabel => 'साप्ताहिक (WSR)';
  @override
  String get monthlyMsrLabel => 'मासिक (MSR)';
  @override
  String get dsrComplianceHeader => 'DSR अनुपालन';
  @override
  String get dsrComplianceSubtitle => 'दैनिक रिपोर्ट दाखिल करने वाले बनाम छूटने वाले — पिछले 14 दिन';
  @override
  String get filedLabel => 'दाखिल किए गए';
  @override
  String get missedLabel => 'छूटे हुए';

  @override
  String get todoHistoryTitle => 'टू-डू · इतिहास';
  @override
  String get todoHistorySubtitle => 'आपकी सूचियों की हर चीज़ का दैनिक बही-खाता — पूर्ण, आगे बढ़ाई गई या अभी भी खुली।';
  @override
  String get doneCountBadge => 'पूर्ण';

  @override
  String get leaderboardTitle => 'लीडरबोर्ड और कोचिंग';
  @override
  String get leaderboardSubtitle => 'जवाबदेही बढ़ाने के लिए बैज, लकीरें और पुरस्कार';
  @override
  String get teamLeaderboardHeader => 'टीम लीडरबोर्ड';
  @override
  String get teamLeaderboardSubtitle => 'आपके दायरे में पूरे किए गए कार्यों के आधार पर रैंकिंग';
  @override
  String get memberHeader => 'सदस्य';
  @override
  String get departmentHeader => 'विभाग';
  @override
  String get doneHeader => 'पूर्ण';
  @override
  String get assignedHeader => 'सौंपे गए';
  @override
  String get overdueHeader => 'बकाया';
  @override
  String get pointsHeader => 'अंक';
  @override
  String get myPointsLedgerHeader => 'मेरा अंक बही-खाता';
  @override
  String get runningBalanceLabel => 'कुल शेष';
  @override
  String get reasonHeader => 'कारण';
  @override
  String get changeHeader => 'परिवर्तन';
  @override
  String get balanceHeader => 'शेष';
  @override
  String get achievementBadgesHeader => 'उपलब्धि बैज';

  @override
  String get teamPerformanceTitle => 'टीम का प्रदर्शन';
  @override
  String get teamPerformanceSubtitle => 'टीमों, विभागों और सदस्यों के बीच पूर्ण प्रदर्शन मैट्रिक्स';
  @override
  String get teamSizeLabel => 'टीम का आकार';
  @override
  String get assignmentsLabel => 'असाइनमेंट';
  @override
  String get inProgressLabel => 'प्रगति पर';
  @override
  String get toStartLabel => 'शुरू होना बाकी';
  @override
  String get onTimeLabel => 'समय पर';
  @override
  String get onTimeHeader => 'समय पर %';
  @override
  String get workloadDeliveryHeader => 'कार्यभार और वितरण';
  @override
  String get workloadDeliverySubtitle => 'प्रत्येक नंबर क्लिक करने योग्य है · किसी भी कॉलम के आधार पर क्रमित करें';
  @override
  String get completionHeader => 'पूर्णता %';
  @override
  String get dueTodayHeader => 'आज देय';
  @override
  String get emgHighHeader => 'आपातकालीन+उच्च';
  @override
  String get droppedHeader => 'छोड़े गए';
  @override
  String get avgDaysHeader => 'औसत दिन';
  @override
  String get byDepartmentHeader => 'विभाग अनुसार';
  @override
  String get byDepartmentSubtitle => 'आपके दायरे में पूर्णता';

  @override
  String get finesRewardsTitle => 'जुर्माना और पुरस्कार';
  @override
  String get finesRewardsSubtitle => 'आपकी टीम में अंक, पुरस्कार और जुर्माने';
  @override
  String get issueFineRewardLabel => '+ जुर्माना / पुरस्कार जारी करें';
  @override
  String get overviewTab => 'अवलोकन';
  @override
  String get summaryTab => 'सारांश';
  @override
  String get auditTrailTab => 'ऑडिट ट्रेल';
  @override
  String get samskarMerchandiseStoreHeader => 'संस्कार मर्चेंडाइज स्टोर';
  @override
  String get redeemButton => 'रिडीम करें';

  @override
  String get performanceSettingsTitle => 'प्रदर्शन सेटिंग्स';
  @override
  String get performanceSettingsSubtitle => 'जुर्माना और पुरस्कार नीतियां';
  @override
  String get directorOnlyBadge => 'केवल निदेशक';
  @override
  String get finePolicyHeader => 'जुर्माना नीति';
  @override
  String get finePolicySubtitle => 'कार्य और रिपोर्ट में देरी की दरें';
  @override
  String get rewardPolicyHeader => 'पुरस्कार नीति';
  @override
  String get rewardPolicySubtitle => 'समय पर और अच्छे कार्य के अंक';
  @override
  String get amountHeader => 'राशि';
  @override
  String get addFineTypeButton => '+ जुर्माना प्रकार जोड़ें';
  @override
  String get addRewardTypeButton => '+ पुरस्कार प्रकार जोड़ें';
  @override
  String get saveSettingsButton => 'सेटिंग्स सहेजें';
  @override
  String get resetToDefaultsButton => 'डिफ़ॉल्ट पर रीसेट करें';

  @override
  String get staffTitle => 'कर्मचारी';
  @override
  String get staffSubtitle => 'कर्मचारियों, भूमिकाओं और पहुंच का प्रबंधन करें';
  @override
  String get addStaffTitle => 'कर्मचारी जोड़ें';
  @override
  String get searchStaffPlaceholder => 'नाम, ईमेल द्वारा खोजें...';
  @override
  String get staffTypeHeader => 'कर्मचारी प्रकार';
  @override
  String get rbacRoleHeader => 'RBAC भूमिका';
  @override
  String get firstNameLabel => 'पहला नाम';
  @override
  String get lastNameLabel => 'अंतिम नाम';
  @override
  String get mobileLabel => 'मोबाइल';
  @override
  String get teachingOption => 'शिक्षण';
  @override
  String get nonTeachingOption => 'गैर-शिक्षण';
  @override
  String get departmentLabel => 'विभाग';
  @override
  String get responsibilitiesLabel => 'जिम्मेदारियां';
  @override
  String get taskCreatorLabel => 'कार्य निर्माता';
  @override
  String get confidentialAccessLabel => 'गोपनीय कार्य पहुंच';
  @override
  String get createdStat => 'बनाए गए';
  @override
  String get finesStat => 'जुर्माने';
  @override
  String get allOption => 'सभी';

  // Sūtra AI Strings
  @override
  String get sutraTitle => 'सूत्र AI';
  @override
  String get sutraBadge => 'कमांड सेंटर';
  @override
  String get sutraSubtitle => 'जोड़ने वाला सूत्र — कार्यों को ऑटो-ड्राफ्ट करता है, मानव आवश्यकता को चिन्हित करता है।';
  @override
  String get askSutraHeader => 'सूत्र से पूछें — आवाज़ या टेक्स्ट से बनाएं';
  @override
  String get askSutraPlaceholder => 'उदा. "कल शाम 4 बजे बैठक निर्धारित करें"';
  @override
  String get interpretButton => 'व्याख्या करें';
  @override
  String get pendingBadge => 'लंबित: ';
  @override
  String get emergencyBadge => 'आपातकालीन: ';
  @override
  String get completedBadge => 'पूर्ण: ';
  @override
  String get needsHumanBadge => 'मानव आवश्यकता: ';
  @override
  String get needsHumanTab => 'मानव आवश्यकता';
  @override
  String get activityFeedTab => 'गतिविधि फ़ीड';
  @override
  String get composeTab => 'रचना करें';
  @override
  String get activeTasksTab => 'सक्रिय कार्य';
  @override
  String get composeHeader => 'सूत्र के साथ रचना करें';
  @override
  String get composePlaceholder => 'सरल भाषा में अनुरोध टाइप करें...';
  @override
  String get suggestPriorityChip => '✦ प्राथमिकता का सुझाव दें';
  @override
  String get pickAssigneeChip => '✦ असाइनी चुनें';
  @override
  String get setDueDateChip => '✦ देय तिथि निर्धारित करें';
  @override
  String get createTaskButton => 'कार्य बनाएं';
  @override
  String get approveButton => 'स्वीकृत करें';
  @override
  String get assignButton => 'सौंपें';
  @override
  String get reviewButton => 'समीक्षा करें';
  @override
  String get trackingBadge => 'ट्रैकिंग';

  // My Preferences Strings
  @override
  String get myPreferencesTitle => 'मेरी प्राथमिकताएं';
  @override
  String get myPreferencesSubtitle => 'नियंत्रित करें कि आप कौन सी सूचनाएं किस चैनल से प्राप्त करते हैं।';
  @override
  String get profileCardHeader => 'प्रोफ़ाइल';
  @override
  String get yourPermissionsHeader => 'आपकी अनुमति';
  @override
  String get dailyDigestHeader => 'दैनिक सार';
  @override
  String get dailyDigestSubtitle => 'हर सुबह 8 बजे एक सारांश सूचना प्राप्त करें।';
  @override
  String get taskOperationsHeader => 'कार्य संचालन';
  @override
  String get meetingsEventsHeader => 'बैठकें और कार्यक्रम';
  @override
  String get prefReportsHeader => 'रिपोर्ट';
  @override
  String get notificationTypeHeader => 'सूचना का प्रकार';
  @override
  String get inAppChannel => 'इन-ऐप';
  @override
  String get emailChannel => 'ईमेल';
  @override
  String get smsChannel => 'एसएमएस';
  @override
  String get whatsappChannel => 'व्हाट्सएप';
  @override
  String get pushChannel => 'पुश';

  // My Profile & FAQ Strings
  @override
  String get myProfileTitle => 'मेरी प्रोफ़ाइल';
  @override
  String get personalInfoSection => 'व्यक्तिगत जानकारी';
  @override
  String get performanceStatsSection => 'प्रदर्शन आँकड़े';
  @override
  String get fullNameLabel => 'पूरा नाम';
  @override
  String get totalTasksStat => 'कुल कार्य';
  @override
  String get completedStatLabel => 'पूर्ण';
  @override
  String get overdueStatLabel => 'अतिदेय';
  @override
  String get currentStreakStat => 'वर्तमान लकीर';
  @override
  String get totalPointsStat => 'कुल अंक';
  @override
  String get onTimeRateStat => 'समय पर दर';
  @override
  String get completionRateStat => 'पूर्णता दर';
  @override
  String get faqTitle => 'सामान्य प्रश्न (FAQ)';
  @override
  String get faqSubtitle => 'संस्कार टास्क मैनेजर के बारे में अक्सर पूछे जाने वाले प्रश्न';
  @override
  String get faqQ1 => 'मैं कोई कार्य कैसे बनाऊं?';
  @override
  String get faqA1 => 'All Tasks → New Task पर जाएं। शीर्षक, विवरण, प्राथमिकता, शाखा और असाइनी भरें।';
  @override
  String get faqQ2 => 'मैं अपना स्वयं का कार्य बंद क्यों नहीं कर सकता?';
  @override
  String get faqA2 => 'असाइनी कार्य को Done के रूप में चिह्नित करते हैं, जो समीक्षा के लिए भेजा जाता है।';
  @override
  String get faqQ3 => 'DSR / WSR / MSR रिमाइंडर कब भेजे जाते हैं?';
  @override
  String get faqA3 => 'रोजाना शाम 5:30 और 5:45 बजे रिमाइंडर भेजे जाते हैं।';
  @override
  String get faqQ4 => 'शाखा फ़िल्टर कैसे काम करता है?';
  @override
  String get faqA4 => 'शीर्ष बार में "All Branches" चयनकर्ता द्वारा डैशबोर्ड को फ़िल्टर कर सकते हैं।';
  @override
  String get faqQ5 => 'मैं थीम या भाषा कैसे बदलूं?';
  @override
  String get faqA5 => 'अवतार मेनू → Settings खोलें। लाइट / डार्क / सिस्टम और अंग्रेजी / तेलुगु / हिंदी चुनें।';

  @override
  String get myStatusReports => 'मेरी स्टेटस रिपोर्ट';
  @override
  String get myStatusReportsSubtitle => 'आपके द्वारा जमा की गई दैनिक, साप्ताहिक और मासिक रिपोर्ट';
  @override
  String get newReportButton => '+ नई रिपोर्ट';
  @override
  String get newStatusReport => 'नई स्टेटस रिपोर्ट';
  @override
  String get dailyDsr => 'दैनिक (DSR)';
  @override
  String get weeklyWsr => 'साप्ताहिक (WSR)';
  @override
  String get monthlyMsr => 'मासिक (MSR)';
  @override
  String get reportTypeLabel => 'रिपोर्ट प्रकार';
  @override
  String get periodDateLabel => 'अवधि तिथि';
  @override
  String get periodDateHint => 'वह दिन जिसे यह रिपोर्ट कवर करती है। रात 9:00 बजे लॉक हो जाती है।';
  @override
  String get autoFillBannerNote => 'पंक्ति आपके कार्यों से स्वतः भरी गई और लॉक है। आप केवल नीचे अतिरिक्त पंक्तियाँ जोड़ सकते हैं।';
  @override
  String get workCompletedLabel => 'पूरा किया गया कार्य *';
  @override
  String get workInProgressLabel => 'प्रगति पर कार्य';
  @override
  String get pendingTasksLabel => 'लंबित कार्य';
  @override
  String get challengesBlockersLabel => 'चुनौतियां / बाधाएं';
  @override
  String get lockedContactDirector => 'लॉक — अनलॉक के लिए निदेशक/प्रधानाचार्य से संपर्क करें';
  @override
  String get enterDetailsPlaceholder => 'विवरण दर्ज करें...';
  @override
  String get saveDraft => 'ड्राफ्ट सहेजें';
  @override
  String get submitButton => 'सबमिट करें';
  @override
  String get noClosureRequestsAwaiting => 'आपके निर्णय की प्रतीक्षा में कोई समाप्ति अनुरोध नहीं है। 🎉';
  @override
  String get targetDateChange => 'लक्ष्य तिथि परिवर्तन';
  @override
  String get resolveApprove => 'समाधान करें · स्वीकृत करें';
  @override
  String get saveChanges => 'परिवर्तन सहेजें';
  @override
  String get autoStatusReportSlotsToday => 'आज ऑटो स्थिति-रिपोर्ट स्लॉट: ';
  @override
  String get dsrTimeSlot => 'DSR · 5:30 PM';
  @override
  String get completionAwaitingApproval => 'समाप्ति अनुमोदन की प्रतीक्षा में';
  @override
  String get noFinesOrRewardsYet => 'अभी तक कोई जुर्माना या पुरस्कार नहीं।';
  @override
  String get youHaveNotOrganizedAnyMeetingsYet => 'आपने अभी तक कोई बैठक आयोजित नहीं की है। 🎉';
  @override
  String get cancelReminderButton => 'रिमाइंडर रद्द करें';
  @override
  String get reportsDashboardSubtitle => 'आपके DSR / WSR / MSR स्थिति रिपोर्ट एक नज़र में।';
  @override
  String get myReportsTitle => 'मेरी रिपोर्ट';
  @override
  String get noReportsFound => 'कोई रिपोर्ट नहीं मिली।';
  @override
  String get complianceTitle => 'अनुपालन';
  @override
  String get complianceSubtitle => 'साइकिल के अनुसार किसने अपनी रिपोर्ट दायर की बनाम किसकी छूट गई';
  @override
  String get noComplianceDataAvailable => 'कोई अनुपालन डेटा उपलब्ध नहीं है।';
  @override
  String noReportDueToday(String type, String nextDue) => 'आज कोई $type देय नहीं है। अगला $type $nextDue को है।';
  @override
  String lastReportCycleInfo(String type, String cycle, int filed, int missed) => 'अंतिम $type — $cycle: $filed पूरा हुआ · $missed छूट गया';
  @override
  String get whoButton => 'कौन?';

  // Complaints & Feedback Module Strings
  @override
  String get complaintsAndFeedbackHeader => 'शिकायतें और प्रतिक्रिया';
  @override
  String get complaintsTracker => 'शिकायत ट्रैकर';
  @override
  String get suggestionBoxEntry => 'सुझाव पेटी प्रविष्टि';
  @override
  String get historyAndInsights => 'इतिहास और अंतर्दृष्टि';
  @override
  String get appreciationApprovals => 'प्रशंसा अनुमोदन';

  @override
  String get complaintsAndFeedbackTitle => 'शिकायतें और प्रतिक्रिया';
  @override
  String get complaintsAndFeedbackSubtitle => 'माता-पिता और छात्रों से शिकायतें, प्रतिक्रिया और प्रशंसाएं — प्रत्येक को समाधान तक ट्रैक किया जाता है।';
  @override
  String get suggestionBoxEntryButton => 'सुझाव पेटी प्रविष्टि';
  @override
  String get historyAndInsightsButton => 'इतिहास और अंतर्दृष्टि';
  @override
  String get raiseRequestButton => '+ अनुरोध दर्ज करें';

  @override
  String get statNewNotPickedUp => 'नई — अभी शुरू नहीं हुई';
  @override
  String get statInProgress => 'प्रगति पर है';
  @override
  String get statPastTargetDate => 'लक्ष्य तिथि बीत चुकी';
  @override
  String get statResolvedThisMonth => 'इस माह में हल की गईं';
  @override
  String get statAwaitingDirectorApproval => 'निदेशक के अनुमोदन की प्रतीक्षा';
  @override
  String get statAvgTimeToResolve => 'औसत समाधान समय';

  @override
  String get tabOpen => 'खुली हुई';
  @override
  String get tabPastTargetDate => 'लक्ष्य तिथि बीत चुकी';
  @override
  String get tabResolved => 'हल की गईं';
  @override
  String get tabAll => 'सभी';

  @override
  String get searchTicketsPlaceholder => 'टिकट संख्या, छात्र, स्टाफ खोजें...';
  @override
  String get filterAllTypes => 'सभी प्रकार';
  @override
  String get filterParentsAndStudents => 'माता-पिता और छात्र';
  @override
  String get filterAllCategories => 'सभी श्रेणियां';
  @override
  String get filterEveryones => 'सभी का';

  @override
  String get colTicket => 'टिकट';
  @override
  String get colType => 'प्रकार';
  @override
  String get colFrom => 'प्रेषक';
  @override
  String get colStudent => 'छात्र';
  @override
  String get colAbout => 'विषय';
  @override
  String get colCategory => 'श्रेणी';
  @override
  String get colStatus => 'स्थिति';
  @override
  String get colWith => 'किसके पास';
  @override
  String get colReceived => 'प्राप्त';
  @override
  String get colTask => 'कार्य';
  @override
  String get noTicketsFound => 'आपके मानदंडों से मेल खाने वाला कोई टिकट नहीं मिला।';

  @override
  String get raiseARequestTitle => 'अनुरोध दर्ज करें';
  @override
  String get typeLabel => 'प्रकार *';
  @override
  String get typeComplaint => 'शिकायत';
  @override
  String get typeFeedbackSuggestion => 'प्रतिक्रिया / सुझाव';
  @override
  String get typeAppreciation => 'प्रशंसा';
  @override
  String get receivedFromLabel => 'कहाँ से प्राप्त *';
  @override
  String get receivedFromParent => 'अभिभावक';
  @override
  String get receivedFromStudent => 'छात्र';
  @override
  String get channelLabel => 'माध्यम *';
  @override
  String get whichGroupPlaceLabel => 'कौन सा समूह / स्थान (वैकल्पिक)';
  @override
  String get whichGroupPlaceHint => 'उदा. कक्षा 6B अभिभावक';
  @override
  String get receivedOnLabel => 'प्राप्ति तिथि *';

  @override
  String get studentNameLabel => 'छात्र का नाम *';
  @override
  String get studentNameHint => 'उदा. आरव रेड्डी';
  @override
  String get classSectionLabel => 'कक्षा और अनुभाग *';
  @override
  String get classSectionHint => 'उदा. 6-B';
  @override
  String get admissionNoLabel => 'प्रवेश संख्या';
  @override
  String get admissionNoHint => 'वैकल्पिक';
  @override
  String get parentNameLabel => 'अभिभावक का नाम';
  @override
  String get parentNameHint => 'उदा. श्रीमती कविता रेड्डी';
  @override
  String get parentMobileLabel => 'अभिभावक का मोबाइल (टिकट नंबर यहाँ भेजा जाएगा)';
  @override
  String get parentMobileHint => '10-अंकों का नंबर';
  @override
  String get keepParentAnonymous => 'अभिभावक की पहचान गुप्त रखें';
  @override
  String get keepParentAnonymousSubtext => 'नाम, मोबाइल और साक्ष्य केवल कैंपस हेड और डायरेक्टर को दिखाई देंगे। टिकट नंबर भेजा जाएगा।';
  @override
  String get aboutLabel => 'के बारे में *';
  @override
  String get aboutStaffMember => 'स्टाफ सदस्य';
  @override
  String get aboutDepartment => 'विभाग';
  @override
  String get aboutTransport => 'परिवहन';
  @override
  String get aboutFacility => 'सुविधा';
  @override
  String get aboutGeneral => 'सामान्य';
  @override
  String get staffMemberSubtext => 'स्टाफ सदस्य (यदि नाम नहीं बताना चाहते तो "नाम नहीं बताया" रहने दें)';
  @override
  String get notNamedOption => 'नाम नहीं बताया — वे नहीं बताना चाहते';

  @override
  String get priorityLabel => 'प्राथमिकता';
  @override
  String get priorityEmergency => 'आपातकालीन';
  @override
  String get priorityTopMost => 'सर्वोच्च';
  @override
  String get priorityHigh => 'उच्च';
  @override
  String get priorityMedium => 'मध्यम';
  @override
  String get priorityLow => 'कम';
  @override
  String targetDateDaysFromToday(int days) => 'लक्ष्य तिथि: आज से $days दिन।';
  @override
  String get visibilityLabel => 'दृश्यता *';
  @override
  String get visibilityGeneral => 'सामान्य — सभी कर्मचारियों को दृश्यमान';
  @override
  String get visibilityConfidential => 'गोपनीय';
  @override
  String get whatWasSaidLabel => 'क्या कहा गया? *';
  @override
  String get whatWasSaidHint => 'क्या हुआ, कब हुआ, और अभिभावक/छात्र क्या चाहते हैं?';
  @override
  String get evidenceLabel => 'साक्ष्य * (व्हाट्सएप स्क्रीनशॉट, रसीद या पत्र की फोटो)';
  @override
  String get addFileButton => 'फ़ाइल जोड़ें';
  @override
  String get fileUploadedSuccess => 'फ़ाइल सफलतापूर्वक संलग्न की गई';
  @override
  String get uploadingFile => 'फ़ाइल अपलोड हो रही है...';
  @override
  String bannerTicketTaskCreated(String ticketNo, String taskNo, String ownerName) =>
      'टिकट $ticketNo और कार्य $taskNo बनाया जाएगा और $ownerName को सौंपा जाएगा। अभिभावक को व्हाट्सएप पर टिकट नंबर प्राप्त होगा।';
  @override
  String get registerComplaintButton => 'शिकायत दर्ज करें';
  @override
  String get complaintRegisteredTitle => 'शिकायत दर्ज की गई';
  @override
  String get ticketNumberLabel => 'टिकट संख्या';
  @override
  String get shareNumberNotice => 'फॉलो अप के लिए यह नंबर साझा करें।';
  @override
  String get whatHappensNext => 'आगे क्या होगा';
  @override
  String taskAssignedNotice(String taskNo, String owner, String due) =>
      'कार्य $taskNo $owner को सौंपा गया · देय तिथि $due';
  @override
  String whatsappTicketSentNotice(String mobile) =>
      '$mobile पर टिकट नंबर के साथ व्हाट्सएप भेजा गया।';
  @override
  String get doneButton => 'संपन्न';
  @override
  String get openTicketButton => 'टिकट खोलें';
  @override
  String get fillRequiredFieldsError => 'कृपया सभी आवश्यक फ़ील्ड भरें।';
  @override
  String get invalidMobileNumberError => 'कृपया एक वैध 10-अंकों का मोबाइल नंबर दर्ज करें।';

  // Suggestion Box & Filters

  @override
  String get assignedByMe => 'मेरे द्वारा सौंपे गए';
  @override
  String get suggestionBoxEntryTitle => 'सुझाव पेटी प्रविष्टि';
  @override
  String get backToTracker => '← ट्रैकर पर वापस जाएं';
  @override
  String get suggestionBoxSub =>
      'प्रति पर्ची एक पंक्ति। बिना छात्र नाम की पंक्तियां अज्ञात के रूप में दर्ज की जाती हैं। शिकायतें और प्रतिक्रिया कैंपस प्रमुख के लिए एक कार्य बनाती हैं; प्रशंसाएं दर्ज की जाती हैं।';
  @override
  String get boxOpenedLabel => 'पेटी खोली गई';
  @override
  String get branchPlaceholder => 'शाखा…';
  @override
  String get addRowButton => '＋ पंक्ति जोड़ें';
  @override
  String saveRequestsButton(int count) =>
      '${count > 0 ? "$count " : ""}अनुरोध सहेजें';
  @override
  String get savingRequests => 'सहेजा जा रहा है…';
  @override
  String get typeAtLeastOneSlipWarning =>
      'सहेजने से पहले कम से कम एक पर्ची टाइप करें।';
  @override
  String attachPhotoWarning(int count) =>
      'प्रत्येक पर्ची की एक तस्वीर संलग्न करें — $count अभी भी बाकी ${count == 1 ? "है" : "हैं"}।';
  @override
  String registeredBannerTitle(int count) => 'पंजीकृत ($count)';
  @override
  String slipTitle(int index) => 'पर्ची $index';
  @override
  String get removeButton => '✕ हटाएं';
  @override
  String get studentBlankAnonymous => 'छात्र (खाली = अज्ञात)';
  @override
  String get anonymousHint => 'अज्ञात';
  @override
  String get classLabel => 'कक्षा';
  @override
  String get classPlaceholder => '8-A';
  @override
  String get aboutLabelSimple => 'के बारे में';
  @override
  String get generalOption => 'सामान्य';
  @override
  String get staffMemberOption => 'स्टाफ सदस्य';
  @override
  String get transportOption => 'परिवहन';
  @override
  String get facilityOption => 'सुविधा';

  @override
  String get categoryLabelSimple => 'श्रेणी';
  @override
  String get whatSlipSays => 'पर्ची में क्या लिखा है *';
  @override
  String get typeSlipPlaceholder => 'पर्ची टाइप करें…';
  @override
  String get photoOfSlip => 'पर्ची की तस्वीर *';
  @override
  String get addPhotoButton => '📎 तस्वीर जोड़ें';
  @override
  String get uploadingPhoto => 'अपलोड हो रहा है…';
  @override
  String suggestionBoxFootnote(String ownerName, int points) =>
      'टिकट चयनित शाखा के $ownerName के पास जाते हैं। स्टाफ सदस्य का नाम देने वाली प्रशंसा पर $points इनाम अंक मिलते हैं; बिना नाम के निदेशक निर्णय लेते हैं।';

  // History & Insights
  // History & Insights
  @override
  String get voiceOfParentsAndStudents => 'अभिभावकों और छात्रों की आवाज़';
  @override
  String academicYearSubtitle(String year) => 'शैक्षणिक वर्ष $year · जून से मई';
  @override
  String get complaintsAndFeedbacksDashboard => 'शिकायत एवं प्रतिक्रिया डैशबोर्ड';
  @override
  String complaintsDashboardSubtitle(String year) =>
      'अभिभावकों, छात्रों और कर्मचारियों द्वारा दी गई जानकारी · शैक्षणिक वर्ष $year (जून से मई)';
  @override
  String get allTicketsButton => 'सभी टिकट';
  @override
  String get openRightNow => 'वर्तमान में खुले';
  @override
  String get pastTargetDate => 'नियत तिथि समाप्त';
  @override
  String get fromParents => 'अभिभावकों से';
  @override
  String get fromStudents => 'छात्रों से';
  @override
  String get fromStaff => 'स्टाफ से';
  @override
  String get avgDaysToResolve => 'समाधान के औसत दिन';
  @override
  String get complaintsHeader => 'शिकायतें';
  @override
  String get feedbackHeader => 'प्रतिक्रिया';
  @override
  String get appreciationsHeader => 'प्रशंसा';
  @override
  String get lastHeader => 'अंतिम';
  @override
  String get complaintsDashboardTitle => 'डैशबोर्ड';
  @override
  String get receivedPerMonth => 'प्रति माह प्राप्त';
  @override
  String get complaintsByCategory => 'श्रेणी के अनुसार शिकायतें';
  @override
  String get byStaffMemberDirectorOnly => 'स्टाफ सदस्य के अनुसार · केवल निदेशक';
  @override
  String get byStudentFamily => 'छात्र / परिवार के अनुसार';
  @override
  String get statTotalReceived => 'कुल प्राप्त';
  @override
  String get staffHeader => 'स्टाफ';
  @override
  String get studentHeader => 'छात्र';
  @override
  String get classHeader => 'कक्षा';
  @override
  @override
  String get noDataAvailable => 'कोई डेटा उपलब्ध नहीं है';

  // Parents & Students Complaints
  @override
  String get parentsComplaintsAndFeedbacks => 'माता-पिता की शिकायतें एवं प्रतिक्रिया';
  @override
  String get parentsComplaintsSubtitle =>
      'माता-पिता ने हमें जो बताया — कक्षा व्हाट्सएप ग्रुप, कॉल और व्यक्तिगत मुलाकातों से।';
  @override
  String get studentsComplaintsAndFeedbacks => 'छात्रों की शिकायतें एवं प्रतिक्रिया';
  @override
  String get studentsComplaintsSubtitle =>
      'छात्रों ने हमें जो बताया — सुझाव बॉक्स पर्चियां और व्यक्तिगत रूप से उठाई गई बातें।';
  @override
  String get staffComplaintsAndFeedbacks => 'कर्मचारी शिकायतें और प्रतिक्रियाएं';
  @override
  String get staffComplaintsSubtitle =>
      'कर्मचारियों ने हमें क्या बताया — प्रतिक्रिया, चिंताएं और मुद्दे।';
  @override
  String get appreciations => 'प्रशंसा';
  @override
  String get appreciationsSubtitle =>
      'माता-पिता, छात्रों और कर्मचारियों द्वारा हमारे लोगों के लिए कहे गए हर अच्छे शब्द — एक ही स्थान पर।';
  @override
  String get appreciationsReceived => 'प्राप्त प्रशंसा';
  @override
  String get recordedBadge => 'दर्ज किया गया';
  @override
  String get awaitingDirectorApproval => 'निदेशक की मंजूरी की प्रतीक्षा में';
  @override
  String get rewardPointsGiven => 'दिए गए इनाम अंक';
  @override
  String get rewardLabel => 'इनाम';
  @override
  String get onlyDirectorCanChange => 'केवल निदेशक इसे बदल सकते हैं।';
  @override
  String get resolutionLabel => 'समाधान';
  @override
  String get everyoneScope => 'सभी';
  @override
  String get everyonesFilter => 'सभी का';
  @override
  String get tabEverything => 'सब कुछ';
  @override
  String get statEverythingReceived => 'कुल प्राप्त';
  @override
  String get filterComplaintsAndFeedback => 'शिकायतें एवं प्रतिक्रिया';
  @override
  String get filterComplaintsOnly => 'केवल शिकायतें';
  @override
  String get filterFeedbackOnly => 'केवल प्रतिक्रिया';

  // Task Stats & Filters
  @override
  String get statTotalCard => 'कुल';
  @override
  String get statNeedsReview => 'समीक्षा आवश्यक';
  @override
  String get statAwaitingSignOff => 'हस्ताक्षर की प्रतीक्षा है';
  @override
  String get statAcrossStatuses => 'सभी स्थितियों में';
  @override
  String get statFootnotePrefix => 'फ़िल्टर करने के लिए कार्ड पर क्लिक करें। शुरू होने वाले + प्रगति में + समीक्षा आवश्यक + पूर्ण + छोड़े गए = कुल। ';
  @override
  String get statFootnoteOverdue => 'अतिदेय';
  @override
  String get statFootnoteSuffix => ' एक ओवरले है — अपनी तिथि पार कर चुके खुले कार्य (समीक्षाधीन वाले नहीं), जो ऊपर पहले से गिने गए हैं।';
  @override
  String get createdByAssignedToAll => 'निर्मित / सौंपे गए: सभी';
  @override
  String get createdByMe => 'मेरे द्वारा बनाए गए';
  @override
  String get assignedToMe => 'मुझे सौंपे गए';
  @override
  String get anyCompletionPercent => 'कोई भी पूर्णता %';
  @override
  String get toLabel => 'तक';
  @override
  String selectAllWithCount(int count) => 'सभी चुनें ($count)';
  @override
  String byAuthor(String name) => '$name द्वारा';
  @override
  String subtasksCountBadge(int done, int total) => '$done/$total उप-कार्य';
  @override
  String get taskNoPrefix => 'कार्य आईडी ';
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
  String get newRecurringButton => '+ नया आवर्ती कार्य';
  @override
  String get newTaskButton => '+ नया कार्य';
  @override
  String get bulkUploadButton => 'थोक अपलोड';
  @override
  String get categoryAll => 'सभी';
  @override
  String get categoryConfidential => 'गोपनीय';
  @override
  String get categoryGeneral => 'सामान्य';
  @override
  String get viewList => 'सूची';
  @override
  String get viewBoard => 'बोर्ड';
  @override
  String get viewCalendar => 'कैलेंडर';
  @override
  String get statComplaints => 'शिकायतें';
  @override
  String get statFeedback => 'प्रतिक्रिया';
  @override
  String get statAppreciations => 'प्रशंसा';
  @override
  String get taskIdSettings => 'कार्य आईडी सेटिंग्स';
  @override
  String get taskIdSettingsSubtitle =>
      'कार्य आईडी SS01-0001/09-26 जैसी दिखती हैं — शाखा कोड, 4-अंकीय संख्या, और कार्य बनने का माह-वर्ष।';
  @override
  String get counterPerBranch => 'प्रति शाखा काउंटर';
  @override
  String get counterPerBranchSubtitle =>
      'प्रत्येक शाखा अपने दम पर 0001 से 9999 तक गिनती है। 01 Jun 2027 को सभी अपने आप 0001 पर रीसेट हो जाते हैं।';
  @override
  String get resetTo0001 => '0001 पर रीसेट करें';
  @override
  String get resetEveryBranch => 'प्रत्येक शाखा को 0001 पर रीसेट करें';
  @override
  String get lastUsed => 'अंतिम उपयोग';
  @override
  String get nextTaskId => 'अगली कार्य आईडी';
  @override
  String get lastReset => 'अंतिम रीसेट';
  @override
  String get complaintsDeskTitle => 'शिकायत डेस्क — टिकट कौन प्राप्त करता है';
  @override
  String get complaintsDeskSubtitle =>
      'स्वचालित पर शाखा की शिकायतें उसके प्रिंसिपल को जाती हैं। टिकट किसी अन्य को भेजने के लिए यहाँ नाम चुनें।';
  @override
  String get fallbackLabel => 'फ़ॉलबैक';
  @override
  String get automaticCurrentlyPrefix => 'स्वचालित — वर्तमान में';
  @override
  String get resetConfirmTitle => 'काउंटर रीसेट करें';
  @override
  String resetConfirmMessage(String branch) =>
      'क्या आप निश्चित हैं कि $branch का काउंटर 0001 पर रीसेट करना चाहते हैं?';
  @override
  String get resetAllConfirmTitle => 'सभी शाखाएं रीसेट करें';
  @override
  String get resetAllConfirmMessage =>
      'क्या आप सभी शाखाओं के काउंटरों को 0001 पर रीसेट करना चाहते हैं?';
  @override
  String get centerHeadPrincipalRole => 'सेंटर हेड / प्रिंसिपल';
  @override
  String get teamLeadRole => 'टीम लीड';
  @override
  String get managerRole => 'प्रबंधक';
  @override
  String centerHeadPrincipalScope(int count) => 'टीम दायरा — $count लोग दृश्य में हैं।';
  @override
  String get operationalScopeYourOwn => 'परिचालन दायरा — आपके अपने कार्य और रिपोर्ट।';
  @override
  String get moreFilters => 'अधिक फ़िल्टर';
  @override
  String get confidentialAndGeneral => 'गोपनीय और सामान्य';
  @override
  String get confidentialOnly => 'केवल गोपनीय';
  @override
  String get generalOnly => 'केवल सामान्य';
  @override
  String get updateEdit => 'अपडेट / संपादित करें';
  @override
  String get changeStatusTitle => 'स्थिति बदलें';
  @override
  String get newStatusLabel => 'नई स्थिति';
  @override
  String get completionLabel => 'पूर्णता';
  @override
  String get commentRequiredLabel => 'टिप्पणी * (प्रत्येक अपडेट के लिए आवश्यक)';
  @override
  String get commentPlaceholder => 'एक अपडेट नोट जोड़ें... किसी का उल्लेख करने के लिए @ टाइप करें';
  @override
  String get addFiles => 'फ़ाइलें जोड़ें';
  @override
  String get attachmentsLabel => 'संलग्नक';
  @override
  String get commentRequiredError => 'कृपया एक अपडेट टिप्पणी दर्ज करें';
  @override
  String get taskUpdatedSuccess => 'कार्य सफलतापूर्वक अपडेट किया गया';
  @override
  String get blockedStatus => 'अवरुद्ध';

  // Ticket Details & Actions Dialog Strings
  @override
  String get linkedTask => 'लिंक किया गया कार्य';
  @override
  String get openTask => 'कार्य खोलें';
  @override
  String get assignTo => 'सौंपें...';
  @override
  String get assignThisTicket => 'यह टिकट सौंपें';
  @override
  String get searchPeoplePlaceholder => 'लोगों को खोजें...';
  @override
  String get whatShouldTheyDoPlaceholder => 'उन्हें क्या करना चाहिए? (आवश्यक)';

  @override
  String get closeTheLoop => 'लूप बंद करें';
  @override
  String get resolveTab => 'समाधान करें';
  @override
  String get notValidTab => 'मान्य नहीं';
  @override
  String get whatWasDonePlaceholder => 'क्या किया गया, और हम माता-पिता को क्या बता रहे हैं?';
  @override
  String get reasonWhyNotValidPlaceholder => 'यह मान्य क्यों नहीं है इसका कारण...';
  @override
  String get markResolvedButton => 'समाधान चिह्नित करें';
  @override
  String get closeAsNotValidButton => 'अमान्य के रूप में बंद करें';
  @override
  String get downloadLabel => 'डाउनलोड';
  @override
  String get evidenceVisibleCampusHeadOnly => 'साक्ष्य केवल कैंपस प्रमुख को दिखाई देता है।';
  @override
  String get historyLabel => 'इतिहास';
  @override
  String get detailsSectionLabel => 'विवरण';
  @override
  String get confidentialBadge => 'गोपनीय';
  @override
  String get editTicketButton => 'टिकट संपादित करें';
  @override
  String get anonymousHidden => 'अनाम — छिपा हुआ';
  @override
  String get editTicketTitlePrefix => 'संपादित करें';

  @override
  String get classAndSectionLabel => 'कक्षा और अनुभाग';


  @override
  String get detailsLabel => 'विवरण';

  @override
  String get addEvidenceLabel => 'साक्ष्य जोड़ें';

  @override
  String get reasonForChangeLabel => 'इस बदलाव का कारण *';
  @override
  String get reasonForChangePlaceholder => 'उदा. अभिभावक ने सही कक्षा अनुभाग दिया';
  @override
  String get saveChangesButton => 'परिवर्तन सहेजें';

  @override
  String get campusHeadLabel => 'कैंपस हेड';

  @override
  String get closedSectionLabel => 'बंद किया गया';

  @override
  String get resolvedSectionLabel => 'हल किया गया';

  // Audit Execution & Scheduling Strings
  @override
  String get scheduleAnAudit => 'ऑडिट शेड्यूल करें';
  @override
  String get auditTitleLabel => 'शीर्षक';
  @override
  String get scopeNoteLabel => 'दायरा नोट';
  @override
  String get auditorLabel => 'ऑडिटर';
  @override
  String get auditeeTypeLabel => 'ऑडिटी';
  @override
  String get auditeeLabel => 'ऑडिटी शाखा / व्यक्ति';
  @override
  String get scheduledDateLabel => 'निर्धारित तिथि';
  @override
  String get dueDateLabel => 'अंतिम तिथि';
  @override
  String get checklistOnePerLine => 'चेकलिस्ट (प्रति पंक्ति एक मद)';
  @override
  String get scheduleAuditButton => 'ऑडिट शेड्यूल करें';
  @override
  String get closeAudit => 'ऑडिट बंद करें';
  @override
  String get conductedBy => 'द्वारा आयोजित';
  @override
  String get scheduledFor => 'इसके लिए निर्धारित';
  @override
  String get dueOn => 'अंतिम तिथि';
  @override
  String get closedOn => 'बंद किया गया';
  @override
  String get noAuditsFound => 'कोई ऑडिट नहीं मिला।';
  @override
  String get threeMonthsView => '3 महीने';
  @override
  String get eventsInTheseThreeMonths => 'इन 3 महीनों में कार्यक्रम';
  @override
  String get listViewLabel => 'सूची';
  @override
  String get fineLabel => 'जुर्माना';
  @override
  String get issuedByLabel => 'द्वारा जारी किया गया';
  @override
  String get policyRules => 'जुर्माना एवं पुरस्कार नीतियां';
  @override
  String get availablePointsLabel => 'उपलब्ध अंक';
  @override
  String get scopeEveryone => 'सभी';
  @override
  String get scopeParents => 'अभिभावक';
  @override
  String get scopeStudents => 'छात्र';
  @override
  String get scopeStaff => 'कर्मचारी';
  @override
  String get studentFamilyListTitle => 'छात्र / परिवार द्वारा';
  @override
  String get lastRecordedLabel => 'अंतिम';
  @override
  String get branchScopeLabel => 'शाखा';
}

