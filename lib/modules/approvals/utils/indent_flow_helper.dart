import '../../auth/models/user_profile.dart';
import '../models/indent_model.dart';

/// One link in the budget approval chain shown while raising an indent.
class IndentChainLink {
  final String role;
  final String label;
  final bool optional;
  final bool isFinal;

  const IndentChainLink(this.role, this.label, {this.optional = false, this.isFinal = false});
}

/// Visual tone used by the UI to pick an AppColors value.
enum IndentTone { pending, approved, rejected, muted }

class IndentStepStatus {
  final String text;
  final IndentTone tone;
  final String? actor;
  final String? at;
  final String? comment;

  const IndentStepStatus(this.text, this.tone, {this.actor, this.at, this.comment});
}

/// Mirrors the multi-tier budget rules of the web portal (dev-task.srivyn.in/budget):
///  * <= ₹2,000  → Center Head (optional) → Director (optional) → Finance Manager (final)
///  * <= ₹5,000  → Center Head (mandatory) → Director (optional) → Finance Manager (final)
///  * >  ₹5,000  → Center Head (mandatory) → Director (mandatory) → Finance Manager (final)
class IndentFlowHelper {
  IndentFlowHelper._();

  static const double tierOneLimit = 2000;
  static const double tierTwoLimit = 5000;

  // ---------- Roles ----------
  static String _role(UserProfile? u) => (u?.role ?? '').toLowerCase();

  static bool isDirector(UserProfile? u) {
    if (u == null) return false;
    final r = _role(u);
    return r == 'director' || r == 'admin' || u.level >= 5;
  }

  static bool isCenterHead(UserProfile? u) {
    if (u == null) return false;
    final r = _role(u);
    return r == 'principal' || r == 'center_head' || u.level == 4;
  }

  static bool isFinanceManager(UserProfile? u) {
    if (u == null) return false;
    final r = _role(u);
    return r == 'finance_manager' || r == 'manager';
  }

  /// Who gets the "All requests" tab (and /indents/all).
  static bool canViewAll(UserProfile? u) {
    if (u == null) return false;
    return isDirector(u) || isCenterHead(u) || isFinanceManager(u) || u.level >= 3;
  }

  // ---------- Chain ----------
  static List<IndentChainLink> chainFor(double amount) {
    if (amount <= tierOneLimit) {
      return const [
        IndentChainLink('principal', 'Center Head (Optional)', optional: true),
        IndentChainLink('director', 'Director (Optional)', optional: true),
        IndentChainLink('finance_manager', 'Finance Manager (Final)', isFinal: true),
      ];
    }
    if (amount <= tierTwoLimit) {
      return const [
        IndentChainLink('principal', 'Center Head (Mandatory)'),
        IndentChainLink('director', 'Director (Optional)', optional: true),
        IndentChainLink('finance_manager', 'Finance Manager (Final)', isFinal: true),
      ];
    }
    return const [
      IndentChainLink('principal', 'Center Head (Mandatory)'),
      IndentChainLink('director', 'Director (Mandatory)'),
      IndentChainLink('finance_manager', 'Finance Manager (Final)', isFinal: true),
    ];
  }

  static String chainNote(double amount) {
    if (amount <= tierOneLimit) {
      return 'Center Head & Director reviews are optional. Finance Manager gives final approval and issues voucher.';
    }
    if (amount <= tierTwoLimit) {
      return 'Center Head approval is mandatory. Director review is optional. Finance Manager gives final approval and issues voucher.';
    }
    return 'Center Head & Director approvals are both mandatory. Finance Manager gives final approval and issues voucher.';
  }

  /// Amber line on a pending card.
  static String pendingSummary(IndentItemModel i) {
    final step = i.currentStep ?? 1;
    if (i.amount <= tierOneLimit) {
      return 'Ready for Finance Manager final approval (CH/Director optional)';
    }
    if (i.amount <= tierTwoLimit) {
      return step == 1
          ? 'Awaiting Center Head approval (Mandatory)'
          : 'Ready for Finance Manager final approval (Director optional)';
    }
    if (step == 1) return 'Awaiting Center Head approval (Mandatory · Step 1/3)';
    if (step == 2) return 'Awaiting Director approval (Mandatory · Step 2/3)';
    return 'Ready for Finance Manager final approval (Step 3/3)';
  }

  // ---------- Detail helpers ----------
  static bool _centerHeadApproved(IndentItemModel i) =>
      i.steps.any((s) => s.isPrincipalStep && s.decision == 'approved');

  static bool _directorApproved(IndentItemModel i) =>
      i.steps.any((s) => s.isDirectorStep && s.decision == 'approved');

  static bool financeReady(IndentItemModel i) {
    final ch = _centerHeadApproved(i);
    final dir = _directorApproved(i);
    return i.amount <= tierOneLimit || (i.amount <= tierTwoLimit && ch) || (i.amount > tierTwoLimit && ch && dir);
  }

  static bool isRaiser(IndentItemModel i, UserProfile? u) {
    if (u == null || i.raisedBy == null) return false;
    return i.raisedBy!.toLowerCase() == u.name.toLowerCase();
  }

  /// The step this user has already approved (if any).
  static IndentStepModel? mySignedStep(IndentItemModel i, UserProfile? u) {
    if (u == null) return null;
    for (final s in i.steps) {
      if (s.decision != 'approved') continue;
      if (s.decidedByUserId != null && s.decidedByUserId == u.id) return s;
      if (s.decidedBy != null && s.decidedBy!.toLowerCase() == u.name.toLowerCase()) return s;
    }
    return null;
  }

  /// The step the current user can act on right now, or null.
  static IndentStepModel? actionableStep(IndentItemModel i, UserProfile? u) {
    if (u == null || i.status != 'pending') return null;
    IndentStepModel? pick;
    IndentStepModel? firstWhere(bool Function(IndentStepModel) test) {
      for (final s in i.steps) {
        if (test(s)) return s;
      }
      return null;
    }

    final finance = firstWhere((s) => s.isFinanceStep && s.decision == 'pending');
    final principal = firstWhere((s) => s.isPrincipalStep && s.decision == 'pending');
    final director = firstWhere((s) => s.isDirectorStep && s.decision == 'pending');

    if (isFinanceManager(u) && finance != null && financeReady(i)) pick = finance;
    if (pick == null && isCenterHead(u) && principal != null) pick = principal;
    if (pick == null && isDirector(u) && director != null) pick = director;
    if (pick == null) return null;

    final raiser = isRaiser(i, u);
    if (raiser && !isDirector(u)) return null;
    if (mySignedStep(i, u) != null) return null;
    return pick;
  }

  static String stepKind(IndentStepModel s) {
    if (s.isFinanceStep) return 'Final Approval';
    return s.isOptional ? 'Optional Review' : 'Mandatory';
  }

  static IndentStepStatus stepStatus(IndentItemModel i, IndentStepModel s) {
    if (s.decision == 'approved') {
      return IndentStepStatus('Approved', IndentTone.approved, actor: s.decidedBy, at: s.decidedAt, comment: s.comment);
    }
    if (s.decision == 'rejected') {
      return IndentStepStatus('Rejected', IndentTone.rejected, actor: s.decidedBy, at: s.decidedAt, comment: s.comment);
    }
    if (i.isOverridden) {
      if (s.isDirectorStep || s.approverLevel >= 5) {
        final ok = i.overrideDecision == 'approved';
        return IndentStepStatus(
          ok ? '★ Approved (Director Override)' : '★ Rejected (Director Override)',
          ok ? IndentTone.approved : IndentTone.rejected,
          actor: i.overrideByName ?? 'Director',
          at: i.overriddenAt,
          comment: i.overrideComment,
        );
      }
      return const IndentStepStatus('Bypassed by Director Override', IndentTone.muted);
    }
    if (i.status == 'approved') {
      if (s.isFinanceStep) return const IndentStepStatus('Final Financial Approval Granted', IndentTone.approved);
      return IndentStepStatus(s.isOptional ? 'Bypassed (Optional)' : 'Approved', IndentTone.approved);
    }
    if (i.status == 'rejected') return const IndentStepStatus('Not reached (Request rejected)', IndentTone.muted);
    if (i.status == 'cancelled') return const IndentStepStatus('Cancelled', IndentTone.muted);
    if (s.isFinanceStep) {
      return financeReady(i)
          ? const IndentStepStatus('Ready for final sign-off', IndentTone.pending)
          : const IndentStepStatus('Awaiting prerequisites', IndentTone.muted);
    }
    if (s.stepNo == i.currentStep) {
      return IndentStepStatus(s.isOptional ? 'Optional review' : 'Awaiting sign-off', IndentTone.pending);
    }
    return IndentStepStatus(s.isOptional ? 'Optional review' : 'Pending', IndentTone.muted);
  }
}
