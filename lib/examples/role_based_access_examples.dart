import 'package:flutter/material.dart';
import 'package:real_galaxy/components/role_access_guard.dart';
import 'package:real_galaxy/services/role_permissions_service.dart';
import 'package:real_galaxy/models/role.dart';

/// This file demonstrates how to implement role-based access control
/// across different screens and features in the application.

class RoleBasedAccessExamples {
  
  /// Example 1: Protecting an entire screen
  static Widget protectedScreen(Role userRole, Widget child) {
    return Scaffold(
      appBar: AppBar(title: Text('Protected Screen')),
      body: RoleAccessGuard(
        userRole: userRole,
        requiredFeature: 'analytics',
        accessDeniedMessage: 'Analytics Access Denied',
        child: child,
      ),
    );
  }

  /// Example 2: Protecting specific features within a screen
  static Widget screenWithMixedAccess(Role userRole) {
    return Scaffold(
      appBar: AppBar(title: Text('Mixed Access Screen')),
      body: Column(
        children: [
          // Feature available to all users
          Container(
            padding: EdgeInsets.all(16),
            child: Text('Public Feature - Available to Everyone'),
          ),
          
          // Feature restricted to admin and above
          RoleAccessGuard(
            userRole: userRole,
            requiredFeature: 'analytics',
            child: Container(
              padding: EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Text('Admin Only Feature - Analytics Dashboard'),
            ),
          ),
          
          // Feature restricted to owner only
          RoleAccessGuard(
            userRole: userRole,
            requiredFeature: 'create_staff',
            child: Container(
              padding: EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Text('Owner Only Feature - Create Staff'),
            ),
          ),
        ],
      ),
    );
  }

  /// Example 3: Using RoleBasedWidget for simple role checks
  static Widget roleBasedWidgetExample(Role userRole) {
    return Scaffold(
      appBar: AppBar(title: Text('Role-Based Widget Example')),
      body: Column(
        children: [
          // Show only to owner and director
          RoleBasedWidget(
            userRole: userRole,
            allowedRoles: [Role.owner, Role.director],
            child: Container(
              padding: EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Text('Owner & Director Only'),
            ),
          ),
          
          // Show only to coach and admin
          RoleBasedWidget(
            userRole: userRole,
            allowedRoles: [Role.coach, Role.admin],
            child: Container(
              padding: EdgeInsets.all(16),
              color: Colors.orange.shade50,
              child: Text('Coach & Admin Only'),
            ),
          ),
        ],
      ),
    );
  }

  /// Example 4: Custom role-based navigation
  static List<NavigationItem> getNavigationItems(Role userRole) {
    final items = <NavigationItem>[];
    
    // Basic items for all roles
    items.addAll([
      NavigationItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        route: '/dashboard',
      ),
      NavigationItem(
        title: 'Profile',
        icon: Icons.person,
        route: '/profile',
      ),
    ]);

    // Role-specific items
    if (RolePermissionsService.canAccessFeature(userRole, 'create_staff')) {
      items.add(NavigationItem(
        title: 'Create Staff',
        icon: Icons.person_add,
        route: '/create-staff',
      ));
    }

    if (RolePermissionsService.canAccessFeature(userRole, 'analytics')) {
      items.add(NavigationItem(
        title: 'Analytics',
        icon: Icons.analytics,
        route: '/analytics',
      ));
    }

    if (RolePermissionsService.canAccessFeature(userRole, 'manage_teams')) {
      items.add(NavigationItem(
        title: 'Team Management',
        icon: Icons.groups,
        route: '/teams',
      ));
    }

    return items;
  }

  /// Example 5: Role-based action buttons
  static Widget roleBasedActions(Role userRole, VoidCallback? onCreateStaff) {
    return Row(
      children: [
        // Action available to all
        ElevatedButton(
          onPressed: () {},
          child: Text('View'),
        ),
        
        SizedBox(width: 8),
        
        // Action restricted to specific roles
        RoleBasedWidget(
          userRole: userRole,
          allowedRoles: [Role.owner, Role.director, Role.admin],
          child: ElevatedButton(
            onPressed: onCreateStaff,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Create Staff'),
          ),
        ),
        
        SizedBox(width: 8),
        
        // Action restricted to owner only
        RoleBasedWidget(
          userRole: userRole,
          allowedRoles: [Role.owner],
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('System Settings'),
          ),
        ),
      ],
    );
  }

  /// Example 6: Role-based form fields
  static Widget roleBasedForm(Role userRole) {
    return Form(
      child: Column(
        children: [
          // Field available to all
          TextFormField(
            decoration: InputDecoration(labelText: 'Name'),
          ),
          
          // Field restricted to admin and above
          RoleAccessGuard(
            userRole: userRole,
            requiredFeature: 'manage_users',
            child: TextFormField(
              decoration: InputDecoration(labelText: 'Admin Notes'),
            ),
          ),
          
          // Field restricted to owner only
          RoleAccessGuard(
            userRole: userRole,
            requiredFeature: 'payment_status',
            child: TextFormField(
              decoration: InputDecoration(labelText: 'Payment Information'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class for navigation items
class NavigationItem {
  final String title;
  final IconData icon;
  final String route;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

/// Example screen showing comprehensive role-based access
class ExampleProtectedScreen extends StatelessWidget {
  final Role userRole;

  const ExampleProtectedScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Role-Based Access Example'),
        actions: [
          UserRoleBadge(role: userRole, showDescription: true),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${RolePermissionsService.getRoleDisplayName(userRole)}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16),
            
            // User role information
            UserRoleBadge(role: userRole, showDescription: true),
            SizedBox(height: 24),
            
            // Features based on role
            Text(
              'Available Features:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            
            // Show different features based on role
            RoleConditionalBuilder(
              userRole: userRole,
              builder: (context, role) {
                switch (role) {
                  case Role.owner:
                    return _buildOwnerFeatures();
                  case Role.director:
                    return _buildDirectorFeatures();
                  case Role.admin:
                    return _buildAdminFeatures();
                  case Role.coach:
                    return _buildCoachFeatures();
                  case Role.parent:
                    return _buildParentFeatures();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerFeatures() {
    return Column(
      children: [
        _featureCard('Create Staff', Icons.person_add, Colors.red),
        _featureCard('Manage Users', Icons.people, Colors.red),
        _featureCard('Payment Status', Icons.payments, Colors.red),
        _featureCard('Analytics', Icons.analytics, Colors.blue),
        _featureCard('Team Management', Icons.groups, Colors.green),
      ],
    );
  }

  Widget _buildDirectorFeatures() {
    return Column(
      children: [
        _featureCard('Analytics', Icons.analytics, Colors.blue),
        _featureCard('Team Management', Icons.groups, Colors.green),
        _featureCard('Training Management', Icons.fitness_center, Colors.orange),
      ],
    );
  }

  Widget _buildAdminFeatures() {
    return Column(
      children: [
        _featureCard('Analytics', Icons.analytics, Colors.blue),
        _featureCard('Reports', Icons.description, Colors.purple),
        _featureCard('Medical Records', Icons.medical_services, Colors.teal),
      ],
    );
  }

  Widget _buildCoachFeatures() {
    return Column(
      children: [
        _featureCard('My Teams', Icons.groups, Colors.green),
        _featureCard('Training Sessions', Icons.fitness_center, Colors.orange),
        _featureCard('Performance', Icons.trending_up, Colors.blue),
      ],
    );
  }

  Widget _buildParentFeatures() {
    return Column(
      children: [
        _featureCard('My Children', Icons.family_restroom, Colors.blue),
        _featureCard('Training Schedule', Icons.calendar_today, Colors.orange),
        _featureCard('Performance', Icons.trending_up, Colors.green),
      ],
    );
  }

  Widget _featureCard(String title, IconData icon, Color color) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
