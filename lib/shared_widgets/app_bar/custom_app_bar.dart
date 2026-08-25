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
import '../../core/utils/preferences_service.dart';
import '../dialogs/create_task_dialog.dart';
import '../dialogs/create_todo_dialog.dart';
import '../dialogs/schedule_meeting_dialog.dart';
import '../dialogs/create_event_dialog.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = context.watch<AuthBloc>().state;
    String userName = 'Vamsi';
    String userEmail = 'vamsi@samskar.edu';
    bool isDirector = false;
    if (authState is AuthenticatedState) {
      userName = authState.userProfile.name;
      userEmail = authState.userProfile.email;
      final role = authState.userProfile.role.toLowerCase();
      final roleLabel = authState.userProfile.roleLabel.toLowerCase();
      if (role.contains('director') || roleLabel.contains('director') || userEmail.contains('vamsi')) {
        isDirector = true;
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
          if (!branches.any((b) => b.id == 0 || b.code == 'ALL')) {
            branches.insert(0, BranchModel(id: 0, code: 'ALL', name: 'All Branches', isAll: true));
          }
          selectedBranch = dashState.selectedBranch;
          if (isDirector && (selectedBranch == null || dashState.selectedBranch == null)) {
            selectedBranch = branches.first;
          } else if (selectedBranch != null) {
            final matchIndex = branches.indexWhere((b) => b.id == selectedBranch?.id || b.code == selectedBranch?.code);
            if (matchIndex != -1) {
              selectedBranch = branches[matchIndex];
            } else {
              selectedBranch = branches.first;
            }
          } else {
            selectedBranch = branches.first;
          }
          unreadCount = dashState.notifications.unread;
        } else {
          branches = [BranchModel(id: 0, code: 'ALL', name: 'All Branches', isAll: true)];
          selectedBranch = branches.first;
        }

        return AppBar(
          backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
          elevation: 1,
          titleSpacing: 0,
          title: Row(
            children: [
              // Expanded(
              //   child: Container(
              //     height: 38,
              //     decoration: BoxDecoration(
              //       color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     padding: const EdgeInsets.symmetric(horizontal: 12),
              //     child: Row(
              //       children: [
              //         Icon(
              //           Icons.search_rounded,
              //           size: 18,
              //           color: isDark ? Colors.white60 : Colors.black45,
              //         ),
              //         const SizedBox(width: 8),
              //         Expanded(
              //           child: TextField(
              //             decoration: InputDecoration(
              //               hintText: s.searchPlaceholder,
              //               hintStyle: TextStyle(
              //                 fontSize: 13,
              //                 color: isDark ? Colors.white54 : Colors.black45,
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

              // + New Popup Button
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
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'task',
                    child: Row(
                      children: [
                        const Icon(Icons.check_rounded, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(s.newTask),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'todo',
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_outlined, size: 18, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(s.newTodo),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'meeting',
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 18, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(s.newMeeting),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'event',
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(s.newEvent),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B132B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        s.newButton,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Dynamic Branch Selector Dropdown (Populated via /api/lookups/branches)
              Flexible(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<BranchModel>(
                      value: selectedBranch,
                      isDense: true,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded, size: 16),
                      items: branches.map((b) {
                        final displayName = b.isAll
                            ? 'All Branches'
                            : (b.code.isNotEmpty ? '${b.code} · ${b.name}' : b.name);
                        return DropdownMenuItem<BranchModel>(
                          value: b,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(b.isAll ? '🏛️ ' : '🏫 ', style: const TextStyle(fontSize: 11)),
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
                          context.read<DashboardBloc>().add(SelectBranchEvent(val));
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 1),
              //
              // // Dynamic Role Badge
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              //   decoration: BoxDecoration(
              //     color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              //     borderRadius: BorderRadius.circular(6),
              //   ),
              //   child: Text(
              //     roleLabel,
              //     style: TextStyle(
              //       fontSize: 10,
              //       fontWeight: FontWeight.bold,
              //       color: isDark ? Colors.white : const Color(0xFF334155),
              //     ),
              //   ),
              // ),

              // Theme Toggle Button
              const SizedBox(width: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 18,
                ),
                onPressed: () {
                  context.read<ThemeCubit>().toggleLightDark();
                },
              ),
              const SizedBox(width: 4),

              // Notifications Bell with Dynamic Badge & Scrollable Dropdown List
              PopupMenuButton<void>(
                offset: const Offset(0, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFB91C1C),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$unreadCount new',
                                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
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
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
                                                  color: item.isRead ? Colors.transparent : const Color(0xFFB91C1C),
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
                                                        color: isDark ? Colors.white : Colors.black87,
                                                      ),
                                                    ),
                                                    if (item.body.isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        item.body,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isDark ? Colors.white60 : Colors.black54,
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
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, size: 20),
                      onPressed: null, // PopupMenuButton handles tap
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFB91C1C),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
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
                              backgroundColor: const Color(0xFF0B132B),
                              child: Text(
                                initialChar,
                                style: const TextStyle(
                                  color: Colors.white,
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
                                Text(
                                  userEmail,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                        const Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                        const SizedBox(width: 10),
                        Text(s.logout, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF0B132B),
                  child: Text(
                    initialChar,
                    style: const TextStyle(
                      color: Colors.white,
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
