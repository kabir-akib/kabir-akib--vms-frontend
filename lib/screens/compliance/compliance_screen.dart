import 'package:flutter/material.dart';
import '../../models/vehicle_document.dart';
import '../../services/document_service.dart';
import '../../theme/app_colors.dart';

/// Fleet-wide document compliance monitor showing expired and expiring-soon documents.
class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  final _documentService = DocumentService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _documentService.loadExpiryAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _documentService,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              if (_documentService.isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primaryAction, strokeWidth: 3)))
              else if (_documentService.errorMessage != null)
                _buildError(_documentService.errorMessage!)
              else
                _buildContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final alerts = _documentService.allExpiryAlerts;
    final expired = alerts.where((a) => a.expiryStatus == DocumentExpiryStatus.expired).length;
    final expiringSoon = alerts.where((a) => a.expiryStatus == DocumentExpiryStatus.expiringSoon).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Compliance Monitor',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text('$expired expired · $expiringSoon expiring soon',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh, size: 20),
          onPressed: () => _documentService.loadExpiryAlerts()),
      ],
    );
  }

  Widget _buildContent() {
    final alerts = _documentService.allExpiryAlerts;
    if (alerts.isEmpty) {
      return Card(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          child: const Column(
            children: [
              Icon(Icons.verified, size: 48, color: AppColors.statusActiveText),
              SizedBox(height: 12),
              Text('All Documents Compliant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.statusActiveText)),
              SizedBox(height: 4),
              Text('No expired or expiring documents found in the fleet.', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    final expired = alerts.where((a) => a.expiryStatus == DocumentExpiryStatus.expired).toList();
    final expiringSoon = alerts.where((a) => a.expiryStatus == DocumentExpiryStatus.expiringSoon).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (expired.isNotEmpty) ...[
          _sectionLabel('Expired Documents', Icons.error_outline, AppColors.error),
          const SizedBox(height: 8),
          _buildAlertTable(expired),
          const SizedBox(height: 20),
        ],
        if (expiringSoon.isNotEmpty) ...[
          _sectionLabel('Expiring Soon (30 days)', Icons.schedule, AppColors.statusMaintenanceText),
          const SizedBox(height: 8),
          _buildAlertTable(expiringSoon),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _buildAlertTable(List<VehicleDocumentExpiry> alerts) {
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
            DataColumn(label: Text('COMPANY')),
            DataColumn(label: Text('DOCUMENT TYPE')),
            DataColumn(label: Text('EXPIRY DATE')),
            DataColumn(label: Text('DAYS')),
            DataColumn(label: Text('STATUS')),
          ],
          rows: alerts.map((alert) {
            final isExpired = alert.expiryStatus == DocumentExpiryStatus.expired;
            return DataRow(cells: [
              DataCell(Text(alert.vehicleNumber, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700))),
              DataCell(Text(alert.company)),
              DataCell(Text(alert.documentTypeLabel ?? alert.documentType.label)),
              DataCell(Text(alert.expiryDate != null
                ? '${alert.expiryDate!.year}-${alert.expiryDate!.month.toString().padLeft(2, '0')}-${alert.expiryDate!.day.toString().padLeft(2, '0')}'
                : '—')),
              DataCell(Text('${alert.daysUntilExpiry}', style: TextStyle(
                color: isExpired ? AppColors.error : AppColors.statusMaintenanceText, fontWeight: FontWeight.w700))),
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
        bg = AppColors.errorBg; text = AppColors.error;
      case DocumentExpiryStatus.expiringSoon:
        bg = AppColors.statusMaintenanceBg; text = AppColors.statusMaintenanceText;
      case DocumentExpiryStatus.valid:
        bg = AppColors.statusActiveBg; text = AppColors.statusActiveText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: text.withValues(alpha: 0.25))),
      child: Text(status.label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildError(String message) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: () => _documentService.loadExpiryAlerts(),
              icon: const Icon(Icons.refresh, size: 16), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
