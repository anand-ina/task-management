import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../modules/auth/bloc/auth_bloc.dart';
import '../../modules/auth/bloc/auth_state.dart';
import '../../modules/dashboard/bloc/dashboard_bloc.dart';
import '../../modules/dashboard/bloc/dashboard_state.dart';
import '../dialogs/todo_today_dialog.dart';

class TodoFloatingActionButton extends StatelessWidget {
  const TodoFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    bool isAdmin = false;
    if (authState is AuthenticatedState) {
      final user = authState.userProfile;
      final role = user.role.toLowerCase();
      final roleLabel = user.roleLabel.toLowerCase();
      if (role.contains('admin') ||
          roleLabel.contains('admin') ||
          user.email.toLowerCase().contains('admin')) {
        isAdmin = true;
      }
    }

    if (isAdmin) {
      return const SizedBox.shrink();
    }

    final dashState = context.watch<DashboardBloc>().state;
    int openTodosCount = 0;
    if (dashState is DashboardLoadedState) {
      openTodosCount = dashState.todos.where((t) => !t.isCompleted).length;
    }

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingActionButton(
          backgroundColor: AppColors.button(context),
          foregroundColor: Colors.white,
          onPressed: () => TodoTodayDialog.show(context),
          child: const Icon(Icons.event_note_sharp),
        ),
        if (openTodosCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$openTodosCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
      ),
    );
  }
}
