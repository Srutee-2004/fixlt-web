import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets/role_shell.dart';
import 'screens/user_screens.dart';
import 'screens/worker_screens.dart';
import 'screens/admin_screens.dart';

/// Builds the navigation shell (sidebar on desktop, bottom bar on mobile) for a role.
Widget shellFor(Role role) => switch (role) {
      Role.user => const RoleShell(role: Role.user, items: [
          NavItem(Icons.home_outlined, 'Home', UserHome()),
          NavItem(Icons.add_circle_outline, 'Post a job', PostJobScreen()),
          NavItem(Icons.work_outline, 'My jobs', MyJobsScreen()),
          NavItem(Icons.person_outline, 'Profile', UserProfile()),
        ]),
      Role.worker => const RoleShell(role: Role.worker, items: [
          NavItem(Icons.place_outlined, 'Nearby', WorkerNearby()),
          NavItem(Icons.work_outline, 'My jobs', WorkerMyJobs()),
          NavItem(Icons.person_outline, 'Profile', WorkerProfileScreen()),
        ]),
      Role.admin => const RoleShell(role: Role.admin, items: [
          NavItem(Icons.dashboard_outlined, 'Dashboard', AdminDashboard()),
          NavItem(Icons.verified_user_outlined, 'Workers', AdminWorkers()),
          NavItem(Icons.work_history_outlined, 'Jobs', AdminJobs()),
          NavItem(Icons.gavel_outlined, 'Disputes', AdminDisputes()),
          NavItem(Icons.category_outlined, 'Categories', AdminCategories()),
          NavItem(Icons.person_outline, 'Profile', AdminProfile()),
        ]),
    };
