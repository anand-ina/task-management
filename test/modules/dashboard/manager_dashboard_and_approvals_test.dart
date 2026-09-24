import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samskar_taskmanager/modules/auth/bloc/auth_bloc.dart';
import 'package:samskar_taskmanager/modules/auth/bloc/auth_state.dart';
import 'package:samskar_taskmanager/modules/auth/models/user_profile.dart';
import 'package:samskar_taskmanager/modules/dashboard/models/dashboard_stats.dart';
import 'package:samskar_taskmanager/modules/tasks/models/task_model.dart';
import 'package:samskar_taskmanager/shared_widgets/dialogs/task_detail_dialog.dart';

class FakeAuthBloc extends AuthBloc {
  final AuthState _testState;
  FakeAuthBloc(this._testState);

  @override
  AuthState get state => _testState;

  @override
  Stream<AuthState> get stream => Stream.value(_testState);
}

void main() {
  group('Manager Login & Timeline Item Tests', () {
    test('UserProfile correctly identifies manager role and label', () {
      final json = {
        'id': 201,
        'name': 'Manager User',
        'email': 'manager@school.com',
        'role': 'manager',
        'role_label': 'Operations Manager',
        'branch_id': 4,
        'permissions': <String>[],
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.isManager, isTrue);
      expect(profile.isDirector, isFalse);
      expect(profile.isPrincipal, isFalse);
      expect(profile.isAdmin, isFalse);
      expect(profile.hasMultiBranchAccess, isFalse);
    });

    test('DashboardTimelineItem parses submitted field correctly', () {
      final jsonFalse = {
        'title': 'Daily Status Report (DSR)',
        'at': '2026-09-24T17:30:00',
        'location': 'Auto · 6 PM deadline',
        'kind': 'report',
        'submitted': false,
      };

      final itemFalse = DashboardTimelineItem.fromJson(jsonFalse);
      expect(itemFalse.title, equals('Daily Status Report (DSR)'));
      expect(itemFalse.submitted, isFalse);

      final jsonTrue = {
        'title': 'Daily Status Report (DSR)',
        'at': '2026-09-24T17:30:00',
        'location': 'Auto · 6 PM deadline',
        'kind': 'report',
        'submitted': true,
      };

      final itemTrue = DashboardTimelineItem.fromJson(jsonTrue);
      expect(itemTrue.submitted, isTrue);
    });
  });

  group('TaskDetailDialog with showOnlyCloneAndCancel Tests', () {
    testWidgets('shows Clone task and Cancel buttons and hides other action buttons', (tester) async {
      final dummyProfile = UserProfile.fromJson({
        'id': 1,
        'name': 'Test User',
        'email': 'test@school.com',
        'role': 'manager',
        'role_label': 'Manager',
        'permissions': <String>[],
      });
      final fakeAuthBloc = FakeAuthBloc(AuthenticatedState(userProfile: dummyProfile, token: 'fake_token'));

      final dummyTask = TaskItemModel(
        id: 999,
        taskNo: 'TSK-999',
        fy: '2026-27',
        title: 'Review Task',
        description: 'Test task description',
        category: 'General',
        priority: 'high',
        status: 'in_progress',
        progress: 30,
        entryDate: '2026-09-24',
        dueDate: '2026-09-25',
        isConfidential: false,
        assignedByText: 'Admin',
        assignedByUserId: 1,
        assignedByName: 'Admin',
        branchId: 1,
        branchCode: 'SS00',
        branchName: 'Head Office',
        assignees: const [],
      );

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: fakeAuthBloc,
          child: MaterialApp(
            home: Scaffold(
              body: TaskDetailDialog(
                taskId: 999,
                initialTask: dummyTask,
                showOnlyCloneAndCancel: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      // Verify Cancel and Clone buttons exist
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Clone Task'), findsOneWidget);

      // Verify other action buttons are hidden
      expect(find.text('✓ Mark Done'), findsNothing);
      expect(find.text('📈 Update / Move'), findsNothing);
      expect(find.text('⚑ Raise Request'), findsNothing);
      expect(find.text('Reassign'), findsNothing);
      expect(find.text('Review →'), findsNothing);
    });
  });
}
