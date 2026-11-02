class ApprovalsConstStrings {
  // Screen Titles
  static const String taskApprovalsTitle = 'Task Approvals';
  static const String escalationsTitle = 'Escalations';
  static const String meetingApprovalsTitle = 'Meeting Approvals';
  static const String budgetApprovalsTitle = 'Budget Approvals';

  // Subtitles & Headers
  static const String approvalsHeader = 'Requests & Approvals';
  static const String approvalsSubtitle =
      'Every approval you need to handle — task closures, change requests, meeting invites, budget spend — in one place.';

  // Tabs
  static const String receivedByMe = 'Received by Me';
  static const String initiatedByMe = 'Initiated by Me';

  // Badges & Actions
  static const String awaitingYou = 'awaiting you';
  static const String approveClosure = 'Approve closure';
  static const String reject = 'Reject';
  static const String approve = 'Approve';
  static const String decline = 'Decline';
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';

  // Filters & Search
  static const String searchPlaceholder = 'Search tasks, people, reports...';
  static const String allBranches = 'All Branches';
  static const String directorRole = 'Director';

  // Empty Messages
  static const String noTaskApprovals = 'No task approvals found.';
  static const String noEscalations = 'No escalations found.';
  static const String noMeetingApprovals = 'No meeting approvals found.';
  static const String noBudgetApprovals = 'You haven’t raised any budget requests yet..';

  // ---------------- Budget Indents ----------------
  static const String budgetIndentsTitle = 'Budget Indents';
  static const String budgetIndentsSubtitle =
      'Multi-tier budget approval flow with Center Head review, Director executive oversight & override, and Finance Manager final sign-off.';
  static const String raiseIndentButton = '＋ Raise indent';
  static const String tabAllRequests = 'All requests';
  static const String tabToApprove = 'To approve';
  static const String tabMyIndents = 'My indents';
  static const String tabApproved = 'Approved';
  static const String tabRejected = 'Rejected';
  static const String searchIndentsHint = 'Search indents…';
  static const String clearSearch = 'Clear search';
  static const String noIndentsMatch = 'No indents match your search';
  static const String emptyInbox = 'Nothing awaiting your approval.';
  static const String emptyMine = 'You haven’t raised any indents yet.';
  static const String emptyApproved = 'No approved indents found.';
  static const String emptyRejected = 'No rejected indents found.';
  static const String emptyAll = 'No indents found.';
  static const String retry = 'Retry';
  static const String overriddenBadge = '★ OVERRIDDEN';
  static const String requestRejected = 'Request Rejected';
  static const String byDirectorOverride = ' (by Director Override)';
  static const String voucherPrefix = 'Voucher';
  static const String voucherReadySuffix = 'ready';

  // Indent detail
  static const String raisedBy = 'Raised by';
  static const String deptPrefix = 'Dept';
  static const String branchPrefix = 'Branch';
  static const String neededBy = 'Needed by';
  static const String lineItems = 'Line items';
  static const String total = 'Total';
  static const String qty = 'Qty';
  static const String unit = 'Unit';
  static const String sequentialChain = 'Sequential Approval Chain';
  static const String noStepsConfigured = 'No steps configured.';
  static const String step = 'Step';
  static const String auditHistory = 'Audit History & Decisions';
  static const String system = 'System';
  static const String fullyApprovedVoucher = 'Fully approved — voucher';
  static const String youSignedOff = 'You have signed off on';
  static const String awaitingChOnly =
      'Awaiting mandatory Center Head approval before Finance Manager final sign-off.';
  static const String awaitingChAndDirector =
      'Awaiting mandatory Center Head and Director approvals before Finance Manager final sign-off.';
  static const String yourDecision = 'Your decision';
  static const String mandatoryApproval = 'Mandatory Approval';
  static const String commentHint = 'Comment (required to reject, optional to approve)';
  static const String approveAndIssueVoucher = 'Approve & Issue Voucher';
  static const String approveAction = 'Approve';
  static const String rejectAction = '↩ Reject';
  static const String rejectReasonRequired = 'Please add a reason when rejecting';
  static const String indentRejected = 'Indent rejected';
  static const String fullyApprovedPrefix = 'Fully approved · voucher';
  static const String approvedNowWith = 'Approved — now with';
  static const String directorOversight = '👑 Director Executive Oversight & Override';
  static const String directorOversightSub = 'Full authority to override rejection or reject unneeded requests';
  static const String overrideRejectedInfo =
      'This request was rejected. As Director, you can override this rejection and approve the budget by providing justification.';
  static const String overrideApprovedInfo =
      'This request is currently approved. If deemed not necessary, you can revoke approval and reject it.';
  static const String overridePendingInfo =
      'You can exercise executive authority to approve or reject this request with justification.';
  static const String overrideRejectionApprove = '★ Override Rejection & Approve';
  static const String directorOverrideApprove = '★ Director Override: Approve';
  static const String revokeAndReject = '✕ Revoke Approval & Reject';
  static const String directorRejectNotNecessary = '✕ Director Reject (Not Necessary)';
  static const String overrideApproveTitle = 'Override & Approve';
  static const String overrideRejectTitle = 'Reject as Not Necessary';
  static const String overrideApproveLabel = 'Why does this rejected budget need to be approved? *';
  static const String overrideRejectLabel = 'Reason why this budget request is rejected / not necessary *';
  static const String overrideApproveHint = 'Provide detailed justification for approving this rejected budget...';
  static const String overrideRejectHint = 'Provide justification why this expense is not necessary...';
  static const String confirmOverrideApprove = 'Confirm Override & Approve';
  static const String confirmRejection = 'Confirm Rejection';
  static const String overrideCommentRequired = 'A comment / reason is required for Director override';
  static const String overrideApprovedToast = 'Director override: Indent approved · voucher issued!';
  static const String overrideRejectedToast = 'Director override: Indent rejected.';
  static const String directorOverridePrefix = '★ Director Override:';
  static const String actionTakenBy = 'Action taken by';
  static const String cancelIndent = 'Cancel this indent';
  static const String cancelIndentConfirm = 'Cancel this indent? This cannot be undone.';
  static const String indentCancelled = 'Indent cancelled';
  static const String keep = 'Keep';
  static const String cancel = 'Cancel';
  static const String yesCancel = 'Yes, cancel';
  static const String processing = 'Processing…';
  static const String loadFailed = 'Unable to load indent details';
  static const String approvalChainFor = 'Approval chain for';
}
