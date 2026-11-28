import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/vehicle.dart';
import '../../routing/app_routes.dart';
import '../../services/api_exception.dart';
import '../../services/vehicle_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_builder.dart';
import '../../widgets/status_badge.dart';

/// Vehicle List & Fleet Inventory screen connected to Spring Boot REST API.
///
/// Handles all primary application states:
/// - Loading state: Server communication in progress
/// - Success state: Interactive data table and KPI cards
/// - Empty state: No records matching search/filters
/// - Error state: Connection failure with detailed message and retry action
class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final _searchController = TextEditingController();
  final _vehicleService = VehicleService();
  Timer? _debounceTimer;

  VehicleStatus? _statusFilter;
  String? _companyFilter;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Initial fetch from Spring Boot backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVehicles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _fetchVehicles() {
    _vehicleService.loadVehicles(
      query: _searchController.text.trim(),
      status: _statusFilter,
      company: _companyFilter,
    );
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _fetchVehicles();
    });
  }

  void _confirmDelete(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Remove Vehicle',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to remove vehicle ${vehicle.vehicleNumber} (${vehicle.displayName})?',
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Company: ${vehicle.company}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This action will call the backend API (DELETE /api/v1/vehicles/{id}) to permanently delete this asset.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            actions: [
              OutlinedButton(
                onPressed: _isDeleting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isDeleting
                    ? null
                    : () async {
                        setDialogState(() => _isDeleting = true);
                        try {
                          await _vehicleService.deleteVehicle(vehicle.id);
                          _isDeleting = false;
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Vehicle ${vehicle.vehicleNumber} deleted successfully.'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        } on ApiException catch (e) {
                          _isDeleting = false;
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Delete failed: ${e.userMessage}'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } catch (_) {
                          _isDeleting = false;
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Delete failed: Unable to reach server.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: _isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Confirm Remove'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vehicleService,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header with Register CTA
              _buildHeader(context),
              const SizedBox(height: 20),

              // KPI Metrics Row (Always displayed or synced)
              _buildMetricsRow(context),
              const SizedBox(height: 24),

              // Search, Filters & Controls Card
              _buildControlsCard(context),
              const SizedBox(height: 16),

              // Dynamic State Views: Loading, Error, Empty, or Success Table
              _buildStatefulContent(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatefulContent(BuildContext context) {
    // 1. Loading State
    if (_vehicleService.isLoading) {
      return _buildLoadingState();
    }

    // 2. Error State
    if (_vehicleService.hasError) {
      return _buildErrorState(_vehicleService.errorMessage!);
    }

    // 3. Empty State
    if (_vehicleService.isEmpty) {
      return _buildEmptyState();
    }

    // 4. Success State (Desktop Table or Mobile Cards)
    final vehicles = _vehicleService.vehicles;
    return ResponsiveLayout(
      mobile: _buildMobileCards(vehicles),
      desktop: _buildDesktopTable(vehicles),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Fleet Inventory',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.starkOrangeSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.starkOrange.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${_vehicleService.totalVehicles} Registered',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.starkOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Live fleet records integrated with Spring Boot REST service.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Refresh Fleet Data',
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _vehicleService.isLoading ? null : _fetchVehicles,
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.starkOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final result = await Navigator.pushNamed(context, AppRoutes.vehicleNew);
                if (result == true) {
                  _fetchVehicles();
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Register Vehicle'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final cards = [
      MetricCard(
        title: 'Total Vehicles',
        value: '${_vehicleService.totalVehicles}',
        icon: Icons.directions_car,
        accentColor: AppColors.primary,
        subtitle: 'All fleet units',
        onTap: () {
          setState(() => _statusFilter = null);
          _fetchVehicles();
        },
      ),
      MetricCard(
        title: 'Active Fleet',
        value: '${_vehicleService.activeVehicles}',
        icon: Icons.check_circle_outline,
        accentColor: AppColors.statusActiveText,
        subtitle: 'Ready for operations',
        onTap: () {
          setState(() => _statusFilter = VehicleStatus.active);
          _fetchVehicles();
        },
      ),
      MetricCard(
        title: 'Under Maintenance',
        value: '${_vehicleService.maintenanceVehicles}',
        icon: Icons.build_circle_outlined,
        accentColor: AppColors.statusMaintenanceText,
        subtitle: 'Workshop inspection',
        onTap: () {
          setState(() => _statusFilter = VehicleStatus.maintenance);
          _fetchVehicles();
        },
      ),
      MetricCard(
        title: 'Inactive / Idle',
        value: '${_vehicleService.inactiveVehicles}',
        icon: Icons.pause_circle_outline,
        accentColor: AppColors.statusInactiveText,
        subtitle: 'Unassigned or retired',
        onTap: () {
          setState(() => _statusFilter = VehicleStatus.inactive);
          _fetchVehicles();
        },
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: c,
                ))
            .toList(),
      );
    }

    return Row(
      children: cards.map((c) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: c,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildControlsCard(BuildContext context) {
    final companies = _vehicleService.availableCompanies;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            // Search Input
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380, minWidth: 260),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Number, Company, Brand, Model...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _fetchVehicles();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            // Filters
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Status Filter
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 190, minWidth: 160),
                  child: DropdownButtonFormField<VehicleStatus?>(
                    key: ValueKey(_statusFilter),
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Status Filter',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Statuses'),
                      ),
                      ...VehicleStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() => _statusFilter = val);
                      _fetchVehicles();
                    },
                  ),
                ),

                // Company Filter
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220, minWidth: 180),
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey(_companyFilter),
                    initialValue: _companyFilter,
                    decoration: const InputDecoration(
                      labelText: 'Company Filter',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Companies'),
                      ),
                      ...companies.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() => _companyFilter = val);
                      _fetchVehicles();
                    },
                  ),
                ),

                // Reset Filters
                if (_searchController.text.isNotEmpty ||
                    _statusFilter != null ||
                    _companyFilter != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _statusFilter = null;
                        _companyFilter = null;
                      });
                      _fetchVehicles();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.starkOrange,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            const Text(
              'Connecting to Spring Boot REST Service...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Querying ${AppConfig.baseUrl}${AppConfig.vehiclesEndpoint}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Backend Communication Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Target Backend Base URL: ${AppConfig.baseUrl}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _fetchVehicles,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Card(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Icon(Icons.directions_car_filled_outlined,
                      size: 32, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Vehicles Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No fleet records matched your query or filter criteria in the database. You can reset filters or register a new vehicle.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _statusFilter = null;
                        _companyFilter = null;
                      });
                      _fetchVehicles();
                    },
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                    label: const Text('Reset All Filters'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.starkOrange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final result = await Navigator.pushNamed(context, AppRoutes.vehicleNew);
                      if (result == true) {
                        _fetchVehicles();
                      }
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Register Vehicle'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<Vehicle> vehicles) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 58,
            dataRowMaxHeight: 64,
            columns: const [
              DataColumn(label: Text('VEHICLE NUMBER')),
              DataColumn(label: Text('COMPANY')),
              DataColumn(label: Text('TYPE')),
              DataColumn(label: Text('BRAND')),
              DataColumn(label: Text('MODEL')),
              DataColumn(label: Text('STATUS')),
              DataColumn(
                label: Text('ACTIONS'),
                numeric: true,
              ),
            ],
            rows: vehicles.map((v) {
              return DataRow(
                cells: [
                  // 1. Vehicle Number
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.borderStrong,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        v.vehicleNumber,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),

                  // 2. Company
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.apartment,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          v.company,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Type
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        v.type.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  // 4. Brand
                  DataCell(
                    Text(
                      v.brand,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  // 5. Model
                  DataCell(
                    Text(
                      v.model,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // 6. Status
                  DataCell(
                    StatusBadge(status: v.status),
                  ),

                  // Actions
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'View Details',
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(36, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              side: const BorderSide(color: AppColors.borderStrong),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.vehicleDetail, arguments: v.id);
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_outlined, size: 15),
                                SizedBox(width: 4),
                                Text('View', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Edit Vehicle',
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(36, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              side: const BorderSide(color: AppColors.borderStrong),
                            ),
                            onPressed: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                AppRoutes.vehicleEdit,
                                arguments: v,
                              );
                              if (result == true) {
                                _fetchVehicles();
                              }
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_outlined, size: 15),
                                SizedBox(width: 4),
                                Text('Edit', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Delete Vehicle',
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(36, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                              foregroundColor: AppColors.error,
                            ),
                            onPressed: () => _confirmDelete(context, v),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline, size: 15),
                                SizedBox(width: 4),
                                Text('Delete', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${vehicles.length} of ${_vehicleService.totalVehicles} registered fleet vehicles',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.link, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Connected to: ${AppConfig.baseUrl}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCards(List<Vehicle> vehicles) {
    return Column(
      children: vehicles.map((v) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderStrong),
                        ),
                        child: Text(
                          v.vehicleNumber,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      StatusBadge(status: v.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    v.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.business_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        v.company,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          v.type.label,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View', style: TextStyle(fontSize: 13)),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.vehicleDetail, arguments: v.id);
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit', style: TextStyle(fontSize: 13)),
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            AppRoutes.vehicleEdit,
                            arguments: v,
                          );
                          if (result == true) {
                            _fetchVehicles();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete', style: TextStyle(fontSize: 13)),
                        onPressed: () => _confirmDelete(context, v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
