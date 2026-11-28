import 'package:flutter/material.dart';
import '../../models/vehicle_document.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_builder.dart';

/// Executive fleet operations dashboard with KPI summary and compliance alerts.
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
            child: CircularProgressIndicator(color: AppColors.starkOrange, strokeWidth: 3),
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fleet Overview',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.4)),
                    SizedBox(height: 4),
                    Text('Executive summary of fleet operations and compliance.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => _dashboardService.loadDashboard(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Vehicle KPI row
            _buildSection('Fleet Status', Icons.local_shipping_outlined),
            const SizedBox(height: 12),
            _buildKpiRow(isMobile, [
              MetricCard(title: 'Total Vehicles', value: '${summary.vehicles.totalVehicles}',
                icon: Icons.directions_car, accentColor: AppColors.primary, subtitle: 'Registered fleet'),
              MetricCard(title: 'Active', value: '${summary.vehicles.activeVehicles}',
                icon: Icons.check_circle_outline, accentColor: AppColors.statusActiveText, subtitle: 'Operational'),
              MetricCard(title: 'Maintenance', value: '${summary.vehicles.maintenanceVehicles}',
                icon: Icons.build_circle_outlined, accentColor: AppColors.statusMaintenanceText, subtitle: 'In workshop'),
              MetricCard(title: 'Inactive', value: '${summary.vehicles.inactiveVehicles}',
                icon: Icons.pause_circle_outline, accentColor: AppColors.statusInactiveText, subtitle: 'Idle'),
            ]),
            const SizedBox(height: 24),

            // Document and Maintenance summary row
            _buildSection('Compliance & Maintenance', Icons.shield_outlined),
            const SizedBox(height: 12),
            _buildKpiRow(isMobile, [
              MetricCard(title: 'Documents', value: '${summary.documents.totalDocuments}',
                icon: Icons.description_outlined, accentColor: AppColors.primary, subtitle: 'Total uploaded'),
              MetricCard(title: 'Expired', value: '${summary.documents.expiredDocuments}',
                icon: Icons.warning_amber_rounded, accentColor: AppColors.error,
                subtitle: 'Requires action'),
              MetricCard(title: 'Expiring Soon', value: '${summary.documents.expiringSoonDocuments}',
                icon: Icons.schedule, accentColor: AppColors.statusMaintenanceText,
                subtitle: 'Within 30 days'),
              MetricCard(title: 'Service Records', value: '${summary.maintenance.totalRecords}',
                icon: Icons.build_outlined, accentColor: AppColors.secondary,
                subtitle: 'BDT ${summary.maintenance.totalCost.toStringAsFixed(0)} total'),
            ]),
            const SizedBox(height: 24),

            // Driver summary row
            _buildSection('Driver Summary', Icons.people_outline),
            const SizedBox(height: 12),
            _buildKpiRow(isMobile, [
              MetricCard(title: 'Total Drivers', value: '${summary.drivers.totalDrivers}',
                icon: Icons.person, accentColor: AppColors.primary, subtitle: 'Registered drivers'),
              MetricCard(title: 'Active', value: '${summary.drivers.activeDrivers}',
                icon: Icons.person_pin, accentColor: AppColors.statusActiveText, subtitle: 'Available'),
              MetricCard(title: 'Inactive', value: '${summary.drivers.inactiveDrivers}',
                icon: Icons.person_off, accentColor: AppColors.statusInactiveText, subtitle: 'Unavailable'),
              MetricCard(title: 'Recent Services', value: '${summary.maintenance.recentRecordsLast30Days}',
                icon: Icons.event_note, accentColor: AppColors.starkOrange, subtitle: 'Last 30 days'),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
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
              DataCell(Text(alert.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
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
    );
  }
}
