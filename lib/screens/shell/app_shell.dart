import 'package:flutter/material.dart';
import '../../routing/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/responsive_builder.dart';
import '../vehicles/vehicle_list_screen.dart';

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
  int _selectedIndex = 0;

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
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.starkOrange, size: 22),
            SizedBox(width: 10),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your Stark Group Fleet Admin session?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.logout();
              _vehicleService.clearSessionData();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.starkOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_shipping,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'STARK GROUP',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'VMS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.starkOrange,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Vehicle Management System',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
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
                      Text(
                        'Fleet Admin Online',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primary,
                  child: const Text(
                    'SG',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _authService.currentUser?.email.isNotEmpty == true
                            ? _authService.currentUser!.email
                            : 'admin@starkgroup.com',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Sign Out',
                  icon: const Icon(Icons.logout, size: 20),
                  onPressed: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(),
      body: Row(
        children: [
          // Desktop Navigation Rail
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) {
                setState(() => _selectedIndex = idx);
              },
              extended: true,
              minExtendedWidth: 230,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Row(
                  children: [
                    Icon(Icons.dashboard_customize_outlined, size: 16, color: AppColors.textMuted),
                    SizedBox(width: 8),
                    Text(
                      'FLEET MODULES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.local_shipping_outlined),
                  selectedIcon: Icon(Icons.local_shipping, color: AppColors.starkOrange),
                  label: Text('Vehicle Registry'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics, color: AppColors.starkOrange),
                  label: Text('System Architecture'),
                ),
              ],
            ),

          if (isDesktop) const VerticalDivider(thickness: 1, width: 1),

          // Primary View Screen
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                const VehicleListScreen(),
                _buildArchitectureTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
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
                    decoration: BoxDecoration(
                      color: AppColors.starkOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_shipping, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STARK GROUP',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      Text(
                        'VMS Admin Portal',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.local_shipping_outlined,
                color: _selectedIndex == 0 ? AppColors.starkOrange : null,
              ),
              title: const Text('Vehicle Registry', style: TextStyle(fontWeight: FontWeight.w600)),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.analytics_outlined,
                color: _selectedIndex == 1 ? AppColors.starkOrange : null,
              ),
              title: const Text('System Architecture', style: TextStyle(fontWeight: FontWeight.w600)),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Sign Out',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
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

  Widget _buildArchitectureTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stark Group VMS Architecture',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Decoupled system architecture specifications and mock data contracts.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.layers_outlined, color: AppColors.starkOrange, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Decoupled Subsystem Responsibilities',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '• Frontend Service (vms-frontend):\n'
                      '  - Built as a high-performance Flutter Web application.\n'
                      '  - Desktop-first responsive layout with Material 3.\n'
                      '  - Clean API data layer connected to Spring Boot REST endpoints.\n'
                      '  - 100% decoupling with configurable API Base URL.\n\n'
                      '• Backend Service (vms-backend):\n'
                      '  - Independent Java Spring Boot REST microservice.\n'
                      '  - Exposes /api/v1/vehicles for CRUD & metrics.\n'
                      '  - Zero frontend code or cross-dependencies.\n\n'
                      '• Strict 6-Field Vehicle Domain Model:\n'
                      '  1. Vehicle Number (Unique identification)\n'
                      '  2. Company (Operating unit)\n'
                      '  3. Type (Truck, Van, Heavy Hauler, etc.)\n'
                      '  4. Brand (Manufacturer)\n'
                      '  5. Model (Model designation)\n'
                      '  6. Status (Active, Maintenance, Inactive)',
                      style: TextStyle(
                        height: 1.6,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.starkOrange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() => _selectedIndex = 0);
                      },
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Return to Vehicle Registry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
