import 'package:flutter/material.dart';
import '../../models/vehicle_document.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_builder.dart';

/// Executive fleet operations dashboard with floating KPI summary and compliance alerts.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dashboardService = DashboardService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dashboardService.loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _dashboardService,
      builder: (context, _) {
        if (_dashboardService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAction, strokeWidth: 3),
          );
        }

        if (_dashboardService.hasError) {
          return _buildErrorState(_dashboardService.errorMessage!);
        }

        return _buildDashboardContent(context);
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final summary = _dashboardService.summary;
    final isMobile = Responsive.isMobile(context);

    return RefreshIndicator(
      onRefresh: () => _dashboardService.loadDashboard(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Layered Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080F1D28),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.speed, size: 22, color: AppColors.primaryAction),
                          SizedBox(width: 8),
                          Text('Fleet Telemetry & Status',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.4)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text('Live operations, compliance tracking, and asset maintenance across all regional hubs.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepNavy,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _dashboardService.loadDashboard(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Vehicle KPI row - with automotive icons (car, check, wrench, route)
            _buildSection('Fleet Status & Assets', Icons.local_shipping_outlined),
            const SizedBox(height: 12),
            _buildKpiRow(isMobile, [
              MetricCard(
                title: 'Total Vehicles',
                value: '${summary.vehicles.totalVehicles}',
                icon: Icons.directions_car,
                accentColor: AppColors.primaryAction,
                subtitle: 'Registered fleet units',
              ),
              MetricCard(
                title: 'Active Operations',
                value: '${summary.vehicles.activeVehicles}',
                icon: Icons.alt_route,
                accentColor: AppColors.statusActiveText,
                subtitle: 'Ready & on-route',
              ),
              MetricCard(
                title: 'In Maintenance',
                value: '${summary.vehicles.maintenanceVehicles}',
                icon: Icons.build_circle_outlined,
                accentColor: AppColors.statusMaintenanceText,
                subtitle: 'In workshop service',
              ),
              MetricCard(
                title: 'Inactive / Idle',
                value: '${summary.vehicles.inactiveVehicles}',
                icon: Icons.pause_circle_outline,
                accentColor: AppColors.statusInactiveText,
                subtitle: 'Depot reserves',
              ),
            ]),
            const SizedBox(height: 24),

            // Document and Maintenance summary row - with fuel, wrench, shield
            _buildSection('Compliance & Maintenance', Icons.shield_outlined),
            const SizedBox(height: 12),
            _buildKpiRow(isMobile, [
              MetricCard(
                title: 'Compliance Documents',
                value: '${summary.documents.totalDocuments}',
                icon: Icons.description_outlined,
                accentColor: AppColors.deepNavy,
                subtitle: 'Regulatory files',
              ),
              MetricCard(
                title: 'Expired Documents',
                value: '${summary.documents.expiredDocuments}',
                icon: Icons.warning_amber_rounded,
                accentColor: AppColors.error,
                subtitle: 'Immediate renewal required',
              ),
              MetricCard(
                title: 'Expiring in 30 Days',
                value: '${summary.documents.expiringSoonDocuments}',
                icon: Icons.schedule,
                accentColor: AppColors.statusMaintenanceText,
                subtitle: 'Upcoming renewals',
              ),
              MetricCard(
                title: 'Service Records',
                value: '${summary.maintenance.totalRecords}',
                icon: Icons.build_outlined,
                accentColor: AppColors.steelBlue,
                subtitle: 'BDT ${summary.maintenance.totalCost.toStringAsFixed(0)} logged',
              ),
            ]),
            const SizedBox(height: 24),

            // Driver summary row - with driver badge, person icons
            _buildSection('Driver Personnel', Icons.badge_outlined),
            const SizedBox(height: 12),
            _buildKpiRow(isMobile, [
              MetricCard(
                title: 'Total Drivers',
                value: '${summary.drivers.totalDrivers}',
                icon: Icons.person_outline,
                accentColor: AppColors.deepNavy,
                subtitle: 'Licensed drivers',
              ),
              MetricCard(
                title: 'Active Assigned',
                value: '${summary.drivers.activeDrivers}',
                icon: Icons.verified_outlined,
                accentColor: AppColors.statusActiveText,
                subtitle: 'Assigned to routes',
              ),
              MetricCard(
                title: 'Available / Unassigned',
                value: '${summary.drivers.inactiveDrivers}',
                icon: Icons.person_off_outlined,
                accentColor: AppColors.statusInactiveText,
                subtitle: 'Standby personnel',
              ),
              MetricCard(
                title: 'Services (Last 30d)',
                value: '${summary.maintenance.recentRecordsLast30Days}',
                icon: Icons.car_repair_outlined,
                accentColor: AppColors.primaryAction,
                subtitle: 'Routine maintenance',
              ),
            ]),
            const SizedBox(height: 24),

            // Expiry alerts table
            if (_dashboardService.expiryAlerts.isNotEmpty) ...[
              _buildSection('Document Expiry Alerts', Icons.notification_important_outlined),
              const SizedBox(height: 12),
              _buildExpiryAlertsTable(_dashboardService.expiryAlerts),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildKpiRow(bool isMobile, List<MetricCard> cards) {
    if (isMobile) {
      return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList());
    }
    return Row(
      children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
    );
  }

  Widget _buildExpiryAlertsTable(List<VehicleDocumentExpiry> alerts) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F1D28),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 46,
          dataRowMinHeight: 50,
          dataRowMaxHeight: 58,
          columns: const [
            DataColumn(label: Text('VEHICLE')),
            DataColumn(label: Text('DOCUMENT TYPE')),
            DataColumn(label: Text('EXPIRY DATE')),
            DataColumn(label: Text('DAYS LEFT')),
            DataColumn(label: Text('STATUS')),
          ],
          rows: alerts.take(10).map((alert) {
            final isExpired = alert.expiryStatus == DocumentExpiryStatus.expired;
            return DataRow(cells: [
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_car, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(alert.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                ],
              )),
              DataCell(Text(alert.documentTypeLabel ?? alert.documentType.label)),
              DataCell(Text(alert.expiryDate != null
                  ? '${alert.expiryDate!.year}-${alert.expiryDate!.month.toString().padLeft(2, '0')}-${alert.expiryDate!.day.toString().padLeft(2, '0')}'
                  : '—')),
              DataCell(Text('${alert.daysUntilExpiry}', style: TextStyle(
                color: isExpired ? AppColors.error : AppColors.statusMaintenanceText,
                fontWeight: FontWeight.w700))),
              DataCell(_buildExpiryBadge(alert.expiryStatus)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildExpiryBadge(DocumentExpiryStatus status) {
    Color bg, text;
    switch (status) {
      case DocumentExpiryStatus.expired:
        bg = AppColors.errorBg;
        text = AppColors.error;
      case DocumentExpiryStatus.expiringSoon:
        bg = AppColors.statusMaintenanceBg;
        text = AppColors.statusMaintenanceText;
      case DocumentExpiryStatus.valid:
        bg = AppColors.statusActiveBg;
        text = AppColors.statusActiveText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: text.withValues(alpha: 0.25))),
      child: Text(status.label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _dashboardService.loadDashboard(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
