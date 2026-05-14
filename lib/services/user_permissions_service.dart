import 'package:firebase_database/firebase_database.dart';
import '../models/user_permissions.dart';

class UserPermissionsService {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref(
    'user_permissions',
  );

  Future<UserPermissions?> getUserPermissions(String userId) async {
    try {
      final snapshot = await _ref.child(userId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(
          snapshot.value as Map<Object?, Object?>,
        );
        return UserPermissions.fromMap(userId, data);
      }
      return null;
    } catch (e) {
      print('Error getting user permissions: $e');
      return null;
    }
  }

  Future<List<UserPermissions>> getAllUserPermissions() async {
    try {
      final snapshot = await _ref.get();
      final permissions = <UserPermissions>[];

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        for (final entry in data.entries) {
          if (entry.value != null) {
            final userData = Map<String, dynamic>.from(entry.value as Map);
            permissions.add(UserPermissions.fromMap(entry.key, userData));
          }
        }
      }

      return permissions;
    } catch (e) {
      print('Error getting all user permissions: $e');
      return [];
    }
  }

  Future<void> createUserPermissions(UserPermissions permissions) async {
    try {
      await _ref.child(permissions.userId).set(permissions.toMap());
    } catch (e) {
      print('Error creating user permissions: $e');
    }
  }

  Future<void> updateUserPermissions(UserPermissions permissions) async {
    try {
      await _ref.child(permissions.userId).update({
        'permissions': permissions.permissions.map(
          (key, value) => MapEntry(key.name, value),
        ),
        'updated_at': DateTime.now().toIso8601String(),
        'granted_by': 'system',
      });
    } catch (e) {
      print('Error updating user permissions: $e');
    }
  }

  Future<void> grantPermission(String userId, DashboardFeature feature) async {
    try {
      final snapshot = await _ref.child(userId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final permissionsData = Map<String, dynamic>.from(
          data['permissions'] ?? {},
        );
        final currentPermissions = UserPermissions.fromMap(userId, data);

        permissionsData[feature.name] = true;

        await _ref.child(userId).update({
          'permissions': permissionsData,
          'updated_at': DateTime.now().toIso8601String(),
          'granted_by': currentPermissions.grantedBy ?? 'system',
        });
      }
    } catch (e) {
      print('Error granting permission: $e');
    }
  }

  Future<void> revokePermission(String userId, DashboardFeature feature) async {
    try {
      final snapshot = await _ref.child(userId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final permissionsData = Map<String, dynamic>.from(
          data['permissions'] ?? {},
        );
        final currentPermissions = UserPermissions.fromMap(userId, data);

        permissionsData[feature.name] = false;

        await _ref.child(userId).update({
          'permissions': permissionsData,
          'updated_at': DateTime.now().toIso8601String(),
          'granted_by': currentPermissions.grantedBy ?? 'system',
        });
      }
    } catch (e) {
      print('Error revoking permission: $e');
    }
  }

  Future<void> setDefaultPermissions(String userId) async {
    try {
      final defaultPermissions = {
        DashboardFeature.teams: true,
        DashboardFeature.training: true,
        DashboardFeature.matches: true,
        DashboardFeature.attendance: true,
        DashboardFeature.performance: true,
        DashboardFeature.videos: true,
        DashboardFeature.medicalRecords: true,
        DashboardFeature.payments: true,
      };

      await _ref.child(userId).set({
        'user_id': userId,
        'permissions': defaultPermissions.map(
          (key, value) => MapEntry(key.name, value),
        ),
        'created_at': DateTime.now().toIso8601String(),
        'granted_by': 'system',
      });
    } catch (e) {
      print('Error setting default permissions: $e');
    }
  }

  Future<void> setOwnerPermissions(String userId) async {
    try {
      final ownerPermissions = <DashboardFeature, bool>{};

      // Give owner access to ALL features
      for (final feature in DashboardFeature.values) {
        ownerPermissions[feature] = true;
      }

      await _ref.child(userId).set({
        'user_id': userId,
        'permissions': ownerPermissions.map(
          (key, value) => MapEntry(key.name, value),
        ),
        'created_at': DateTime.now().toIso8601String(),
        'granted_by': 'system',
      });
    } catch (e) {
      print('Error setting owner permissions: $e');
    }
  }

  Future<void> ensureOwnerPermissions(String userId) async {
    try {
      final existingPermissions = await getUserPermissions(userId);

      if (existingPermissions == null) {
        // No permissions exist, create full owner permissions
        await setOwnerPermissions(userId);
      } else {
        // Check if owner has all permissions, if not, grant missing ones
        final updatedPermissions = Map<DashboardFeature, bool>.from(
          existingPermissions.permissions,
        );
        bool needsUpdate = false;

        for (final feature in DashboardFeature.values) {
          if (updatedPermissions[feature] != true) {
            updatedPermissions[feature] = true;
            needsUpdate = true;
          }
        }

        if (needsUpdate) {
          await updateUserPermissions(
            UserPermissions(
              userId: userId,
              permissions: updatedPermissions,
              createdAt: existingPermissions.createdAt,
              updatedAt: DateTime.now(),
              grantedBy: 'system',
            ),
          );
        }
      }
    } catch (e) {
      print('Error ensuring owner permissions: $e');
    }
  }

  Future<void> deleteUserPermissions(String userId) async {
    try {
      await _ref.child(userId).remove();
    } catch (e) {
      print('Error deleting user permissions: $e');
    }
  }
}
