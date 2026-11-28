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

/// Professional Automotive + Hybrid Layered Shell for Stark Group VMS.
///
/// Features:
/// - Deep Navy (#172633) sidebar & mobile drawer for authoritative enterprise feel
/// - White app bar with subtle border separating from Off-White workspace
/// - Floating-style layered workspace view with crisp depth
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

  // Full navigation items with appropriate automotive icons
  static const List<_NavItem> _allNavItems = [
    _NavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.local_shipping_outlined, selectedIcon: Icons.local_shipping, label: 'Vehicles'),
    _NavItem(icon: Icons.badge_outlined, selectedIcon: Icons.badge, label: 'Drivers'),
    _NavItem(icon: Icons.verified_user_outlined, selectedIcon: Icons.verified_user, label: 'Compliance'),
    _NavItem(icon: Icons.admin_panel_settings_outlined, selectedIcon: Icons.admin_panel_settings, label: 'User Management'),
  ];

  /// Returns the visible navigation items based on the current user's role.
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
          'Are you sure you want to end your Stark Group Fleet session?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
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

    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.deepNavy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car_filled, color: AppColors.primaryAction, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('STARK GROUP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.6, color: AppColors.deepNavy)),
                    SizedBox(width: 6),
                    Text('VMS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryAction)),
                  ],
                ),
                Text('Automotive Fleet Management', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.statusActiveBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.statusActiveText.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 7, color: AppColors.statusActiveDot),
                      SizedBox(width: 6),
                      Text('Fleet Online',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.statusActiveText)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.steelBlue,
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
                            : 'Fleet Operations',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text(
                        _authService.currentUser?.email.isNotEmpty == true
                            ? _authService.currentUser!.email
                            : 'admin@starkgroup.com',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Sign Out',
                  icon: const Icon(Icons.logout, size: 20, color: AppColors.textSecondary),
                  onPressed: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(navItems),
      body: Row(
        children: [
          if (isDesktop) ...[
            Container(
              decoration: const BoxDecoration(
                color: AppColors.deepNavy,
                border: Border(right: BorderSide(color: AppColors.darkBorder, width: 1)),
              ),
              child: NavigationRail(
                backgroundColor: AppColors.deepNavy,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
                extended: true,
                minExtendedWidth: 220,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.tune, size: 14, color: AppColors.textLightSecondary),
                      SizedBox(width: 8),
                      Text('FLEET CONTROL',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: AppColors.textLightSecondary)),
                    ],
                  ),
                ),
                destinations: navItems.map((item) => NavigationRailDestination(
                  icon: Icon(item.icon, color: AppColors.textLightSecondary),
                  selectedIcon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAction,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(item.selectedIcon, color: Colors.white, size: 18),
                  ),
                  label: Text(item.label),
                )).toList(),
              ),
            ),
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
      backgroundColor: AppColors.deepNavy,
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
                    child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STARK GROUP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                      Text('Fleet Management', style: TextStyle(fontSize: 12, color: AppColors.textLightSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.darkBorder),
            ...navItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isSelected = _selectedIndex == idx;
              return ListTile(
                leading: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected ? AppColors.primaryAction : AppColors.textLightSecondary,
                ),
                title: Text(item.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textLightSecondary,
                  )),
                tileColor: isSelected ? AppColors.steelBlue : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                onTap: () {
                  setState(() => _selectedIndex = idx);
                  Navigator.pop(context);
                },
              );
            }),
            const Spacer(),
            const Divider(color: AppColors.darkBorder),
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
