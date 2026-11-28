import 'package:flutter/material.dart';
import '../../routing/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/driver_service.dart';
import '../../services/document_service.dart';
import '../../services/user_service.dart';
import '../../services/vehicle_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/responsive_builder.dart';
import '../dashboard/dashboard_screen.dart';
import '../vehicles/vehicle_list_screen.dart';
import '../drivers/driver_list_screen.dart';
import '../compliance/compliance_screen.dart';
import '../users/user_management_screen.dart';

/// Desktop-first application shell for the Stark Group Vehicle Management System.
///
/// Provides responsive persistent navigation rail for desktop/tablet,
/// drawer navigation for mobile, global header, user identity, and session controls.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AuthService _authService = AuthService();
  final VehicleService _vehicleService = VehicleService();
  final DashboardService _dashboardService = DashboardService();
  final DriverService _driverService = DriverService();
  final DocumentService _documentService = DocumentService();
  final UserService _userService = UserService();
  int _selectedIndex = 0;

  // Full navigation items including admin-only User Management.
  static const List<_NavItem> _allNavItems = [
    _NavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.local_shipping_outlined, selectedIcon: Icons.local_shipping, label: 'Vehicles'),
    _NavItem(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Drivers'),
    _NavItem(icon: Icons.shield_outlined, selectedIcon: Icons.shield, label: 'Compliance'),
    _NavItem(icon: Icons.manage_accounts_outlined, selectedIcon: Icons.manage_accounts, label: 'User Management'),
  ];

  /// Returns the visible navigation items based on the current user's role.
  /// User Management is only shown to ADMIN users.
  List<_NavItem> get _navItems {
    final isAdmin = _authService.currentUser?.role == 'ADMIN';
    if (isAdmin) return _allNavItems;
    return _allNavItems.sublist(0, _allNavItems.length - 1);
  }

  /// Returns the screens matching the current navigation items.
  List<Widget> get _screens {
    final isAdmin = _authService.currentUser?.role == 'ADMIN';
    return [
      const DashboardScreen(),
      const VehicleListScreen(),
      const DriverListScreen(),
      const ComplianceScreen(),
      if (isAdmin) const UserManagementScreen(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!_authService.isAuthenticated && mounted) {
      _vehicleService.clearSessionData();
      _dashboardService.clearSessionData();
      _driverService.clearSessionData();
      _documentService.clearSessionData();
      _userService.clearSessionData();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.error, size: 22),
            SizedBox(width: 10),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your Stark Group Fleet Admin session?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAction, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.logout();
              _vehicleService.clearSessionData();
              _dashboardService.clearSessionData();
              _driverService.clearSessionData();
              _documentService.clearSessionData();
              _userService.clearSessionData();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final navItems = _navItems;
    final screens = _screens;

    // Clamp the selected index if the nav items changed (e.g. role change).
    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: AppColors.primaryAction, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.local_shipping, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('STARK GROUP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5, color: AppColors.textPrimary)),
                    SizedBox(width: 6),
                    Text('VMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryAction)),
                  ],
                ),
                Text('Vehicle Management System', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal)),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: AppColors.statusActiveDot),
                      SizedBox(width: 6),
                      Text('Fleet Admin Online',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primary,
                  child: const Text('SG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                if (!Responsive.isMobile(context)) ...[
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _authService.currentUser?.fullName.isNotEmpty == true
                            ? _authService.currentUser!.fullName
                            : 'Operations Director',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text(
                        _authService.currentUser?.email.isNotEmpty == true
                            ? _authService.currentUser!.email
                            : 'admin@starkgroup.com',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
                const SizedBox(width: 12),
                IconButton(tooltip: 'Sign Out', icon: const Icon(Icons.logout, size: 20), onPressed: _handleLogout),
              ],
            ),
          ),
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(navItems),
      body: Row(
        children: [
          if (isDesktop) ...[
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              extended: true,
              minExtendedWidth: 220,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Row(
                  children: [
                    Icon(Icons.dashboard_customize_outlined, size: 16, color: AppColors.textMuted),
                    SizedBox(width: 8),
                    Text('FLEET MODULES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.textMuted)),
                  ],
                ),
              ),
              destinations: navItems.map((item) => NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon, color: AppColors.primaryAction),
                label: Text(item.label),
              )).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
          ],
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(List<_NavItem> navItems) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primaryAction, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.local_shipping, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STARK GROUP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text('VMS Admin Portal', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            ...navItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return ListTile(
                leading: Icon(
                  _selectedIndex == idx ? item.selectedIcon : item.icon,
                  color: _selectedIndex == idx ? AppColors.primaryAction : null,
                ),
                title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                selected: _selectedIndex == idx,
                onTap: () {
                  setState(() => _selectedIndex = idx);
                  Navigator.pop(context);
                },
              );
            }),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
}
