import 'package:flutter_test/flutter_test.dart';
import 'package:samskar_taskmanager/modules/auth/models/user_profile.dart';

void main() {
  group('Principal Dynamic Branch ID Resolution Tests', () {
    test('UserProfile correctly resolves assignedBranchId from branch_id', () {
      final json = {
        'id': 101,
        'name': 'Principal User',
        'email': 'principal@school.com',
        'role': 'principal',
        'role_label': 'Campus Principal',
        'branch_id': 4,
        'permissions': <String>[],
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.isPrincipal, isTrue);
      expect(profile.assignedBranchId, equals(4));
      expect(profile.branch?.id, equals(4));
    });

    test('UserProfile correctly resolves assignedBranchId from branchId', () {
      final json = {
        'id': 102,
        'name': 'Campus Head User',
        'email': 'head@school.com',
        'role': 'campus_head',
        'role_label': 'Campus Head',
        'branchId': 4,
        'permissions': <String>[],
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.isPrincipal, isTrue);
      expect(profile.assignedBranchId, equals(4));
      expect(profile.branch?.id, equals(4));
    });

    test('UserProfile correctly resolves assignedBranchId from nested branch map', () {
      final json = {
        'id': 103,
        'name': 'Center Head User',
        'email': 'centerhead@school.com',
        'role': 'center_head',
        'role_label': 'Center Head',
        'branch': {
          'id': 4,
          'name': 'Campus Branch 4',
          'code': 'CB04',
        },
        'permissions': <String>[],
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.isPrincipal, isTrue);
      expect(profile.assignedBranchId, equals(4));
      expect(profile.branch?.name, equals('Campus Branch 4'));
    });

    test('UserProfile correctly resolves assignedBranchId from branches list', () {
      final json = {
        'id': 104,
        'name': 'Principal User',
        'email': 'principal@school.com',
        'role': 'principal',
        'role_label': 'Principal',
        'branches': [
          {
            'id': 4,
            'name': 'Campus Branch 4',
            'code': 'CB04',
          }
        ],
        'permissions': <String>[],
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.isPrincipal, isTrue);
      expect(profile.assignedBranchId, equals(4));
      expect(profile.branch?.id, equals(4));
    });
  });
}
