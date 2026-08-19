import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/theme_cubit.dart';
import '../../modules/auth/bloc/auth_bloc.dart';
import '../../modules/auth/bloc/auth_event.dart';
import '../../modules/auth/bloc/auth_state.dart';
import '../../modules/dashboard/models/branch_model.dart';
import '../../modules/settings/screens/settings_screen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final int unreadNotifications;
  final List<BranchModel> branches;
  final String currentBranch;
  final ValueChanged<String>? onBranchChanged;

  const CustomAppBar({
    super.key,
    this.unreadNotifications = 10,
    this.branches = const [],
    this.currentBranch = 'All Branches',
    this.onBranchChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  late String _selectedBranch;

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.currentBranch;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = context.watch<AuthBloc>().state;
    String userName = 'Vamsi';
    String userEmail = 'vamsi@samskar.edu';
    String roleLabel = s.directorRole;

    if (authState is AuthenticatedState) {
      userName = authState.userProfile.name;
      userEmail = authState.userProfile.email;
      roleLabel = authState.userProfile.roleLabel.isNotEmpty
          ? authState.userProfile.roleLabel
          : authState.userProfile.role;
    }

    final initialChar = userName.isNotEmpty ? userName[0].toUpperCase() : 'V';

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
      elevation: 1,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 8),


          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: s.searchPlaceholder,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

           PopupMenuButton<String>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {},
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
              padding: const EdgeInsets.symmetric(horizontal: 4),
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
          const SizedBox(width: 1),

          // Branch Selector Dropdown
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBranch,
                icon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
                items: [
                  DropdownMenuItem(
                    value: 'All Branches',

                    child: Row(
                      children: [
                        const Text('🏛️ ', style: TextStyle(fontSize: 19)),
                        Text(
                          s.allBranches,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  ...widget.branches.map((b) => DropdownMenuItem(
                        value: b.name,
                        child: Text(b.name, style: const TextStyle(fontSize: 9)),
                      )),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedBranch = val);
                    if (widget.onBranchChanged != null) widget.onBranchChanged!(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 2),

          // Dynamic Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              roleLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 2),

          // Theme Toggle Icon Button
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 14,
            ),
            onPressed: () {
              context.read<ThemeCubit>().toggleLightDark();
            },
          ),
          const SizedBox(width: 1),

          // Notifications Bell Icon with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 17),
                onPressed: () {},
              ),
              if (widget.unreadNotifications > 0)
                Positioned(
                  right: -6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFB91C1C),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      'dxcvsg${widget.unreadNotifications}',


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
          const SizedBox(width: 1),

          // Profile Avatar Icon Dropdown

          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'setting') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              } else if (value == 'logout') {
                context.read<AuthBloc>().add(LogoutRequestedEvent());
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
          // const SizedBox(width: 16),
        ],
      ),
    );
  }
}
