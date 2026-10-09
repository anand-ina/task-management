import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/app_navigator.dart';
import '../../../../core/utils/preferences_service.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/hourly_log_bloc.dart';
import '../bloc/hourly_log_event.dart';
import '../bloc/hourly_log_state.dart';
import '../models/hourly_log_model.dart';
import '../repository/hourly_log_repository.dart';
import '../screens/hourly_log_screen.dart';
import '../../../../shared_widgets/animations/app_animations.dart';

class HourlyLogPromptOverlay extends StatefulWidget {
  final Widget child;

  const HourlyLogPromptOverlay({super.key, required this.child});

  static const List<String> allSlots = [
    '08:30-09:30',
    '09:30-10:30',
    '10:30-11:30',
    '11:30-12:30',
    '12:30-13:30',
    '13:30-14:30',
    '14:30-15:30',
    '15:30-16:30',
    '16:30-17:30',
    '17:30-18:30',
  ];

  static String computeCurrentSlot([DateTime? now]) {
    final dt = now ?? DateTime.now();
    final currentMinutes = dt.hour * 60 + dt.minute;

    for (int i = 0; i < allSlots.length; i++) {
      final slot = allSlots[i];
      final parts = slot.split('-');
      final startParts = parts[0].split(':');
      final endParts = parts[1].split(':');
      final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      if (currentMinutes >= startMin && currentMinutes < endMin) {
        // Return previous section/slot time.
        // e.g. if present time is between 10:30 and 11:30, return 09:30-10:30
        if (i > 0) {
          return allSlots[i - 1];
        }
        return allSlots.first;
      }
    }

    if (currentMinutes < 8 * 60 + 30) {
      return allSlots.first;
    }
    return allSlots.last;
  }

  @override
  State<HourlyLogPromptOverlay> createState() => _HourlyLogPromptOverlayState();
}

class _HourlyLogPromptOverlayState extends State<HourlyLogPromptOverlay> {
  Timer? _scheduleTimer;
  bool _showPrompt = false;
  bool _isLogging = false;
  final TextEditingController _entryController = TextEditingController();

  static String computeCurrentSlot([DateTime? now]) => HourlyLogPromptOverlay.computeCurrentSlot(now);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _setPromptState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _startTimer([Duration duration = const Duration(seconds: 5)]) {
    _scheduleTimer?.cancel();
    _scheduleTimer = Timer(duration, () async {
      await _checkAndShowPrompt();
    });
  }

  Future<void> _checkAndShowPrompt() async {
    if (!mounted) return;
    final isAllowed = await _isAllowedRole();
    if (!isAllowed || !mounted) return;

    final token = await PreferencesService().getToken();
    if (token == null || token.isEmpty || !mounted) return;

    // Check if today's log is already submitted or if current slot is filled
    HourlyLogModel? log;
    try {
      final logState = context.read<HourlyLogBloc>().state;
      if (logState is HourlyLogLoadedState) {
        log = logState.hourlyLog;
      }
    } catch (_) {}

    log ??= await HourlyLogRepository().getHourlyLog();
    if (!mounted) return;

    if (log != null) {
      // 1. If today's log is already submitted, NEVER show the dialog box!
      if (log.isSubmitted) {
        debugPrint('⏱ [HourlyLogPromptOverlay] Today log is already submitted. Skipping dialog box.');
        return;
      }

      // 2. Check if current slot is already filled with items or marked as lunch
      final currentSlot = computeCurrentSlot();
      final matchingSlot = log.slots.firstWhere(
        (s) => s.slot == currentSlot,
        orElse: () => HourlySlotModel(slot: currentSlot, items: const []),
      );

      if (matchingSlot.lunch || matchingSlot.items.isNotEmpty) {
        debugPrint('⏱ [HourlyLogPromptOverlay] Slot $currentSlot already filled (${matchingSlot.items.length} items, lunch: ${matchingSlot.lunch}). Skipping dialog box.');
        return;
      }
    }

    _setPromptState(() {
      _showPrompt = true;
    });
  }

  Future<bool> _isAllowedRole() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        final rLower = authState.userProfile.role.toLowerCase();
        final rlLower = authState.userProfile.roleLabel.toLowerCase();
        if (rLower.contains('academic_executive') ||
            rLower.contains('academic executive') ||
            rLower.contains('executive') ||
            rLower.contains('ae') ||
            rlLower.contains('academic executive') ||
            rlLower.contains('executive') ||
            rLower.contains('team_lead') ||
            rLower.contains('team lead') ||
            rLower.contains('lead') ||
            rlLower.contains('team lead') ||
            rlLower.contains('team_lead')) {
          return true;
        }
      }
    } catch (_) {}

    final role = await PreferencesService().getUserRole();
    final roleLabel = await PreferencesService().getUserRoleLabel();
    final rLower = (role ?? '').toLowerCase();
    final rlLower = (roleLabel ?? '').toLowerCase();
    return rLower.contains('academic_executive') ||
        rLower.contains('academic executive') ||
        rLower.contains('executive') ||
        rLower.contains('ae') ||
        rlLower.contains('academic executive') ||
        rlLower.contains('executive') ||
        rLower.contains('team_lead') ||
        rLower.contains('team lead') ||
        rLower.contains('lead') ||
        rlLower.contains('team lead') ||
        rlLower.contains('team_lead');
  }

  void _dismissPrompt({bool remindLater = false}) {
    _setPromptState(() {
      _showPrompt = false;
    });
    if (remindLater) {
      _startTimer(const Duration(minutes: 15));
    }
  }

  Future<void> _submitQuickLog() async {
    final text = _entryController.text.trim();
    if (text.isEmpty) return;

    final slot = computeCurrentSlot();
    _setPromptState(() => _isLogging = true);

    final repo = HourlyLogRepository();
    final newId = await repo.addHourlyItem(slot, text);

    if (!mounted) return;
    _setPromptState(() {
      _isLogging = false;
      _showPrompt = false;
    });
    _entryController.clear();

    final navContext = AppNavigator.navigatorKey.currentContext;

    if (newId != null) {
      try {
        context.read<HourlyLogBloc>().add(AddHourlyItemEvent(slot: slot, body: text));
      } catch (_) {}

      final s = AppStrings.of(context);
      if (navContext != null && navContext.mounted) {
        ScaffoldMessenger.of(navContext).showSnackBar(
          SnackBar(
            content: Text(s.entryLoggedSuccess(slot)),
            backgroundColor: AppColors.green600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Handle error (e.g. today's log already submitted)
      final errorMsg = repo.lastErrorMessage;
      if (errorMsg != null && errorMsg.isNotEmpty) {
        if (errorMsg.toLowerCase().contains('already submitted')) {
          try {
            final logState = context.read<HourlyLogBloc>().state;
            if (logState is HourlyLogLoadedState) {
              context.read<HourlyLogBloc>().add(const FetchHourlyLogEvent());
            }
          } catch (_) {}
        }
        if (navContext != null && navContext.mounted) {
          ScaffoldMessenger.of(navContext).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.red700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _openFullLog() {
    _dismissPrompt();
    AppNavigator.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const HourlyLogScreen()),
    );
  }

  @override
  void dispose() {
    _scheduleTimer?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState is AuthenticatedState) {
              _startTimer();
            } else if (authState is UnauthenticatedState) {
              _scheduleTimer?.cancel();
              if (_showPrompt) _setPromptState(() => _showPrompt = false);
            }
          },
        ),
        BlocListener<HourlyLogBloc, HourlyLogState>(
          listener: (context, logState) {
            if (logState is HourlyLogLoadedState) {
              if (logState.hourlyLog.isSubmitted) {
                _scheduleTimer?.cancel();
                if (_showPrompt) _setPromptState(() => _showPrompt = false);
              } else {
                final currentSlot = computeCurrentSlot();
                final matching = logState.hourlyLog.slots.firstWhere(
                  (s) => s.slot == currentSlot,
                  orElse: () => HourlySlotModel(slot: currentSlot, items: const []),
                );
                if (matching.lunch || matching.items.isNotEmpty) {
                  if (_showPrompt) _setPromptState(() => _showPrompt = false);
                }
              }
            }
          },
        ),
      ],
      child: _buildOverlayContent(context),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    final s = AppStrings.of(context);
    final slot = computeCurrentSlot();
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isCompact = screenWidth < 500;

    return Stack(
      children: [
        widget.child,
        if (_showPrompt)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            bottom: (isCompact ? 16 : 24) + keyboardHeight,
            right: isCompact ? 16 : 24,
            left: isCompact ? 16 : null,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              tween: Tween<double>(begin: 0.88, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Material(
                color: AppColors.transparent,
                child: Container(
                  width: isCompact ? null : 380,
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Teal Header matching Image 1
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: const BoxDecoration(
                          color: AppColors.tealHeader,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.hourlyLogPromptTitle(slot),
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ScaleTap(
                              onTap: () => _dismissPrompt(),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question
                          Builder(
                            builder: (context) {
                              final promptText = s.whatDidYouWorkOnDuring(slot);
                              final parts = promptText.split(slot);
                              return Text.rich(
                                TextSpan(
                                  children: parts.length > 1
                                      ? [
                                          TextSpan(
                                            text: parts[0],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textPrimary(context),
                                            ),
                                          ),
                                          TextSpan(
                                            text: slot,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary(context),
                                            ),
                                          ),
                                          TextSpan(
                                            text: parts.sublist(1).join(slot),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textPrimary(context),
                                            ),
                                          ),
                                        ]
                                      : [
                                          TextSpan(
                                            text: promptText,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary(context),
                                            ),
                                          ),
                                        ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Quick Input Field + Log Button Row
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface(context),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border(context)),
                                  ),
                                  alignment: Alignment.center,
                                  child: TextField(
                                    controller: _entryController,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary(context),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: s.addQuickEntryHint,
                                      hintStyle: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary(context).withValues(alpha: 0.7),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onSubmitted: (_) => _submitQuickLog(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ScaleTap(
                                onTap: _isLogging ? null : _submitQuickLog,
                                child: SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.navyHeader,
                                      foregroundColor: AppColors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: _isLogging ? null : _submitQuickLog,
                                    child: _isLogging
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.white,
                                            ),
                                          )
                                        : Text(
                                            s.logButton,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Bottom Actions Row: Open full log -> & Remind me later
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ScaleTap(
                                onTap: _openFullLog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.border(context)),
                                    color: AppColors.surface(context),
                                  ),
                                  child: Text(
                                    s.openFullLog,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentBlue(context),
                                    ),
                                  ),
                                ),
                              ),
                              ScaleTap(
                                onTap: () => _dismissPrompt(remindLater: true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.border(context)),
                                    color: AppColors.surface(context),
                                  ),
                                  child: Text(
                                    s.remindMeLater,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary(context),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
