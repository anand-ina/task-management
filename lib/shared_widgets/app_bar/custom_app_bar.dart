import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/theme_cubit.dart';
import '../../modules/auth/bloc/auth_bloc.dart';
import '../../modules/auth/bloc/auth_event.dart';
import '../../modules/auth/bloc/auth_state.dart';
import '../../modules/dashboard/bloc/dashboard_bloc.dart';
import '../../modules/dashboard/bloc/dashboard_event.dart';
import '../../modules/dashboard/bloc/dashboard_state.dart';
import '../../modules/dashboard/models/branch_model.dart';
import '../../modules/dashboard/models/notification_model.dart';
import '../../modules/settings/screens/settings_screen.dart';

import '../../modules/profile/screens/my_profile_screen.dart';
import '../../modules/faq/screens/faq_screen.dart';
import '../../modules/auth/screens/login_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/preferences_service.dart';
import '../dialogs/create_task_dialog.dart';
import '../dialogs/create_todo_dialog.dart';
import '../dialogs/schedule_meeting_dialog.dart';
import '../dialogs/create_event_dialog.dart';
import '../../modules/complaints/dialogs/raise_complaint_dialog.dart';
import '../../modules/announcements/bloc/announcements_bloc.dart';
import '../../modules/announcements/bloc/announcements_event.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dashBloc = context.read<DashboardBloc>();
      final authState = context.read<AuthBloc>().state;
      int? initialBranchId;
      int? initialMine;
      if (authState is AuthenticatedState) {
        final u = authState.userProfile;
        if (u.isManager) {
          initialMine = 1;
          initialBranchId = null;
        } else if (u.isPrincipal) {
          initialBranchId = u.assignedBranchId;
        } else if (!u.isDirector) {
          initialMine = 1;
        }
      }
      if (dashBloc.state is DashboardInitialState) {
        dashBloc.add(FetchDashboardDataEvent(mine: initialMine, branchId: initialBranchId));
      } else if (dashBloc.state is DashboardLoadedState) {
        final loaded = dashBloc.state as DashboardLoadedState;
        if (loaded.branches.length <= 1) {
          dashBloc.add(FetchDashboardDataEvent(mine: initialMine, branchId: initialBranchId));
        }
      }
      context.read<AnnouncementsBloc>().add(const FetchActiveAnnouncementsEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600;

    final authState = context.watch<AuthBloc>().state;
    String userName = 'User';
    String userEmail = '';
    bool isDirector = false;
    bool isPrincipal = false;
    bool isAdmin = false;
    String userRoleLabel = '';
    String deptName = '';
    String userBranchName = '';
    bool hasMultiBranchAccess = false;

    if (authState is AuthenticatedState) {
      final user = authState.userProfile;
      userName = user.name.isNotEmpty ? user.name : (user.email.split('@').first);
      userEmail = user.email;
      userRoleLabel = user.roleLabel.isNotEmpty ? user.roleLabel : user.role;
      deptName = user.department?.name ?? '';
      userBranchName = user.firstBranchName.isNotEmpty ? user.firstBranchName : (user.branch?.name ?? '');
      isDirector = user.isDirector;
      isPrincipal = user.isPrincipal;
      isAdmin = user.isAdmin;
      hasMultiBranchAccess = user.hasMultiBranchAccess;
    }

    final List<BranchModel> meBranches = [];
    if (authState is AuthenticatedState) {
      final user = authState.userProfile;
      if (user.branches.isNotEmpty) {
        for (final b in user.branches) {
          if (!meBranches.any((existing) => existing.id == b.id && existing.code == b.code)) {
            meBranches.add(BranchModel(id: b.id, code: b.code, name: b.name, isAll: b.isAll));
          }
        }
      }
      if (user.branch != null) {
        final b = user.branch!;
        if (!meBranches.any((existing) => existing.id == b.id && existing.code == b.code)) {
          meBranches.add(BranchModel(id: b.id, code: b.code, name: b.name, isAll: b.isAll));
        }
      }
    }

    final initialChar = userName.isNotEmpty ? userName[0].toUpperCase() : 'V';

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, dashState) {
        List<BranchModel> branches = [];
        BranchModel? selectedBranch;
        int unreadCount = 0;

        if (dashState is DashboardLoadedState) {
          branches = List<BranchModel>.from(dashState.branches);
          if (branches.isEmpty) {
            branches = List<BranchModel>.from(meBranches);
          }

          if (!hasMultiBranchAccess && userBranchName.isNotEmpty) {
            branches = branches.where((b) => !b.isAll && (b.name == userBranchName || b.id == (authState is AuthenticatedState ? authState.userProfile.branch?.id : null))).toList();
            if (branches.isEmpty && meBranches.isNotEmpty) {
              branches = [meBranches.first];
            } else if (branches.isEmpty && userBranchName.isNotEmpty) {
              branches = [BranchModel(id: 1, code: '', name: userBranchName, isAll: false)];
            }
          } else {
            if (branches.isNotEmpty && !branches.any((b) => b.id == 0 || b.code.toUpperCase() == 'ALL' || b.name.toLowerCase().contains('all branches'))) {
              branches.insert(0, BranchModel(id: 0, code: 'ALL', name: 'All Branches', isAll: true));
            }
          }
          selectedBranch = dashState.selectedBranch;
          final assignedId = authState is AuthenticatedState ? authState.userProfile.assignedBranchId : null;
          if (isPrincipal && assignedId != null && assignedId > 0 && (selectedBranch == null || selectedBranch.isAll)) {
            final match = branches.where((b) => b.id == assignedId).firstOrNull;
            if (match != null) {
              selectedBranch = match;
            }
          }
          if (selectedBranch != null) {
            final matchIndex = branches.indexWhere((b) => b.id == selectedBranch?.id || b.code == selectedBranch?.code);
            if (matchIndex != -1) {
              selectedBranch = branches[matchIndex];
            } else {
              selectedBranch = branches.isNotEmpty ? branches.first : null;
            }
          } else {
            selectedBranch = branches.isNotEmpty ? branches.first : null;
          }
          unreadCount = dashState.notifications.unread;
        } else {
          if (!hasMultiBranchAccess && userBranchName.isNotEmpty) {
            branches = meBranches.isNotEmpty
                ? meBranches.where((b) => !b.isAll).toList()
                : [BranchModel(id: 1, code: '', name: userBranchName, isAll: false)];
          } else {
            branches = List<BranchModel>.from(meBranches);
            if (branches.isNotEmpty && !branches.any((b) => b.id == 0 || b.code.toUpperCase() == 'ALL' || b.name.toLowerCase().contains('all branches'))) {
              branches.insert(0, BranchModel(id: 0, code: 'ALL', name: 'All Branches', isAll: true));
            }
          }
          selectedBranch = branches.isNotEmpty ? branches.first : null;
        }

        String directBranchDisplayName = '';
        if (deptName.isNotEmpty && userBranchName.isNotEmpty) {
          directBranchDisplayName = '$deptName · $userBranchName';
        } else if (userBranchName.isNotEmpty) {
          directBranchDisplayName = userBranchName;
        } else if (branches.isNotEmpty && !branches.first.isAll) {
          directBranchDisplayName = branches.first.name;
        } else if (deptName.isNotEmpty) {
          directBranchDisplayName = deptName;
        } else {
          directBranchDisplayName = '';
        }

        String adminBranchName = userBranchName;
        if (adminBranchName.isEmpty) {
          final nonAll = branches.where((b) => !b.isAll && b.id != 0 && b.code.toUpperCase() != 'ALL').toList();
          if (nonAll.isNotEmpty) {
            adminBranchName = nonAll.first.name;
          } else if (branches.isNotEmpty) {
            adminBranchName = branches.first.name;
          } else {
            adminBranchName = '';
          }
        }

        return AppBar(
          backgroundColor: AppColors.appBarBg(context),
          elevation: 1,
          titleSpacing: 0,
          title: Row(
            children: [
              // Expanded(
              //   child: Container(
              //     height: 38,
              //     decoration: BoxDecoration(
              //       color: isDark ? AppColors.navyCard : AppColors.slate100,
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     padding: const EdgeInsets.symmetric(horizontal: 12),
              //     child: Row(
              //       children: [
              //         Icon(
              //           Icons.search_rounded,
              //           size: 18,
              //           color: isDark ? AppColors.white60 : AppColors.black45,
              //         ),
              //         const SizedBox(width: 8),
              //         Expanded(
              //           child: TextField(
              //             decoration: InputDecoration(
              //               hintText: s.searchPlaceholder,
              //               hintStyle: TextStyle(
              //                 fontSize: 13,
              //                 color: isDark ? AppColors.white54 : AppColors.black45,
              //               ),
              //               border: InputBorder.none,
              //               isDense: true,
              //             ),
              //             style: const TextStyle(fontSize: 13),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              if (isAdmin) ...[
                if (!isMobile) ...[
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.chipBg(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.subtleBorder(context)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      userRoleLabel.isNotEmpty
                          ? (userRoleLabel.toLowerCase().contains('admin') ? 'Administrator' : userRoleLabel)
                          : 'Administrator',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isTablet)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.chipBg(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.subtleBorder(context)),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏫 ', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              adminBranchName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.chipBg(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.subtleBorder(context)),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏫 ', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              adminBranchName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isTablet) const Spacer(),
              ] else ...[
                // + New Popup Button (non-admin users)
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'task') {
                      CreateTaskDialog.show(context);
                    } else if (value == 'todo') {
                      CreateTodoDialog.show(context);
                    } else if (value == 'meeting') {
                      ScheduleMeetingDialog.show(context);
                    } else if (value == 'event') {
                      CreateEventDialog.show(context);
                    } else if (value == 'raise_request') {
                      RaiseComplaintDialog.show(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'task',
                      child: Row(children: [
                        const Icon(Icons.check_rounded, size: 18, color: AppColors.blue),
                        const SizedBox(width: 8),
                        Text(s.newTask),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'todo',
                      child: Row(children: [
                        const Icon(Icons.assignment_outlined, size: 18, color: AppColors.orange),
                        const SizedBox(width: 8),
                        Text(s.newTodo),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'meeting',
                      child: Row(children: [
                        const Icon(Icons.access_time_rounded, size: 18, color: AppColors.purple),
                        const SizedBox(width: 8),
                        Text(s.newMeeting),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'event',
                      child: Row(children: [
                        const Icon(Icons.star_rounded, size: 18, color: AppColors.amber),
                        const SizedBox(width: 8),
                        Text(s.newEvent),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'raise_request',
                      child: Row(children: [
                        const Icon(Icons.feedback_outlined, size: 18, color: AppColors.maroon),
                        const SizedBox(width: 8),
                        Text(s.raiseRequestButton),
                      ]),
                    ),
                  ],
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.button(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          s.newButton,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.white),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 8 : 6),

                // Branch Selector: if hasMultiBranchAccess and (branches > 1 or isPrincipal or isDirector), show dropdown; otherwise direct branch name
                if (hasMultiBranchAccess && (branches.length > 1 || isPrincipal || isDirector))
                  isTablet
                      ? SizedBox(
                          width: 220,
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.chipBg(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.subtleBorder(context)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<BranchModel>(
                                value: selectedBranch,
                                isDense: true,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
                                items: branches.map((b) {
                                  final isAllItem = b.id == 0 || b.code.toUpperCase() == 'ALL' || b.name.toLowerCase().contains('all branches');
                                  final displayName = isAllItem
                                      ? 'All Branches'
                                      : (b.code.isNotEmpty ? '${b.code} · ${b.name}' : b.name);
                                  return DropdownMenuItem<BranchModel>(
                                    value: b,
                                    child: Row(
                                      children: [
                                        Text(isAllItem ? '🏛️ ' : '🏫 ', style: const TextStyle(fontSize: 12)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            displayName,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    context.read<DashboardBloc>().add(
                                      SelectBranchEvent(
                                        val,
                                        mine: (isDirector || isPrincipal) ? null : 1,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        )
                      : Flexible(
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: AppColors.chipBg(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.subtleBorder(context)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<BranchModel>(
                                value: selectedBranch,
                                isDense: true,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded, size: 16),
                                items: branches.map((b) {
                                  final isAllItem = b.id == 0 || b.code.toUpperCase() == 'ALL' || b.name.toLowerCase().contains('all branches');
                                  final displayName = isAllItem
                                      ? 'All Branches'
                                      : (b.code.isNotEmpty ? '${b.code} · ${b.name}' : b.name);
                                  return DropdownMenuItem<BranchModel>(
                                    value: b,
                                    child: Row(
                                      children: [
                                        Text(isAllItem ? '🏛️ ' : '🏫 ', style: const TextStyle(fontSize: 10)),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            displayName,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    context.read<DashboardBloc>().add(
                                      SelectBranchEvent(
                                        val,
                                        mine: (isDirector || isPrincipal) ? null : 1,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        )
                else
                  isTablet
                      ? SizedBox(
                          width: 220,
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.chipBg(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.subtleBorder(context)),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.textPrimary(context),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    directBranchDisplayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Flexible(
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.chipBg(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.subtleBorder(context)),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: AppColors.textPrimary(context),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    directBranchDisplayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                // Dynamic Role Badge (e.g. Academic Executive) - hidden on mobile view, shown comfortably on tablet/desktop
                if (!isMobile && userRoleLabel.isNotEmpty && !isAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.chipBg(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.subtleBorder(context)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      userRoleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                ],
                if (isTablet) const Spacer(),
              ],

              // Direct 2-Way Theme Mode Switching (Light White, Dark Black - No Dropdown)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: isDark ? s.themeModeLight : s.themeModeDark,
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 20,
                  color: isDark ? AppColors.amber : AppColors.textPrimary(context),
                ),
                onPressed: () {
                  context.read<ThemeCubit>().setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
                },
              ),

              // Notifications Bell with Dynamic Badge & Scrollable Dropdown List
              PopupMenuButton<void>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                offset: const Offset(0, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: AppColors.card(context),
                itemBuilder: (context) {
                  final notifications = dashState is DashboardLoadedState ? dashState.notifications.items : <NotificationItem>[];
                  return [
                    PopupMenuItem<void>(
                      enabled: false,
                      child: SizedBox(
                        width: 320,
                        height: 300,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  s.notificationsTitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryRed,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$unreadCount new',
                                      style: const TextStyle(fontSize: 10, color: AppColors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(height: 16),

                            // Notifications List
                            Expanded(
                              child: notifications.isEmpty
                                  ? Center(
                                      child: Text(
                                        s.noNotifications,
                                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: EdgeInsets.zero,
                                      itemCount: notifications.length,
                                      separatorBuilder: (_, _) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final item = notifications[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                margin: const EdgeInsets.only(top: 4, right: 8),
                                                decoration: BoxDecoration(
                                                  color: item.isRead ? AppColors.transparent : AppColors.primaryRed,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.title,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                                        color: AppColors.textPrimary(context),
                                                      ),
                                                    ),
                                                    if (item.body.isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        item.body,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors.textSecondary(context),
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 20,
                          color: isDark ? AppColors.white70 : AppColors.textPrimary(context),
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryRed,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Profile Avatar Menu
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyProfileScreen()),
                    );
                  } else if (value == 'settings') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  } else if (value == 'faq') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FaqScreen()),
                    );
                  } else if (value == 'logout') {
                    PreferencesService().clearSession();
                    context.read<AuthBloc>().add(LogoutRequestedEvent());
                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.navyHeader,
                              child: Text(
                                initialChar,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (userRoleLabel.isNotEmpty) ...[
                                  Text(
                                    userRoleLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentBlue(context),
                                    ),
                                  ),
                                ],
                                Text(
                                  userEmail,
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 18),
                        const SizedBox(width: 10),
                        Text(s.myProfile),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(Icons.settings_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(s.settings),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'faq',
                    child: Row(
                      children: [
                        const Icon(Icons.help_outline_rounded, size: 18),
                        const SizedBox(width: 10),
                        Text(s.faq),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded, size: 18, color: AppColors.red),
                        const SizedBox(width: 10),
                        Text(s.logout, style: const TextStyle(color: AppColors.red)),
                      ],
                    ),
                  ),
                ],
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.navyHeader,
                  child: Text(
                    initialChar,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}
