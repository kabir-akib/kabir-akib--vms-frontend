import 'package:flutter/material.dart';
import '../../models/driver.dart';
import '../../models/driver_assignment.dart';
import '../../services/api_exception.dart';
import '../../services/driver_service.dart';
import '../../services/vehicle_service.dart';
import '../../theme/app_colors.dart';

/// Driver directory with CRUD operations and vehicle assignment management.
class DriverListScreen extends StatefulWidget {
  const DriverListScreen({super.key});

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  final _driverService = DriverService();
  final _vehicleService = VehicleService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _driverService.loadDrivers();
      if (_vehicleService.vehicles.isEmpty) {
        _vehicleService.loadVehicles(showLoading: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _driverService,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              if (_driverService.isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primaryAction, strokeWidth: 3)))
              else if (_driverService.hasError)
                _buildError(_driverService.errorMessage!)
              else ...[
                _buildDriversTable(),
                const SizedBox(height: 24),
                _buildAssignmentsSection(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Drivers & Assignments',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text('${_driverService.totalDrivers} drivers · ${_driverService.activeAssignments} active assignments',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _driverService.loadDrivers()),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAction, foregroundColor: Colors.white),
              onPressed: () => _showDriverDialog(null),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Driver'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriversTable() {
    final drivers = _driverService.drivers;
    if (drivers.isEmpty) {
      return Card(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text('No Drivers Registered', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAction, foregroundColor: Colors.white),
                onPressed: () => _showDriverDialog(null),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add First Driver'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 60,
          columns: const [
            DataColumn(label: Text('NAME')),
            DataColumn(label: Text('PHONE')),
            DataColumn(label: Text('LICENCE NO.')),
            DataColumn(label: Text('LICENCE EXPIRY')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('ACTIONS'), numeric: true),
          ],
          rows: drivers.map((d) {
            return DataRow(cells: [
              DataCell(Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(Text(d.phoneNumber)),
              DataCell(Text(d.drivingLicenceNumber, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600))),
              DataCell(_buildLicenceExpiry(d)),
              DataCell(_buildDriverStatusBadge(d.status)),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18), tooltip: 'Edit',
                    onPressed: () => _showDriverDialog(d)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error), tooltip: 'Delete',
                    onPressed: () => _confirmDeleteDriver(d)),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLicenceExpiry(Driver d) {
    if (d.licenceExpiryDate == null) return const Text('—', style: TextStyle(color: AppColors.textMuted));
    final date = d.licenceExpiryDate!;
    final formatted = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (d.isLicenceExpired) {
      return Text(formatted, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700));
    }
    if (d.isLicenceExpiringSoon) {
      return Text(formatted, style: const TextStyle(color: AppColors.statusMaintenanceText, fontWeight: FontWeight.w600));
    }
    return Text(formatted);
  }

  Widget _buildDriverStatusBadge(DriverStatus status) {
    Color bg, text;
    switch (status) {
      case DriverStatus.active:
        bg = AppColors.statusActiveBg; text = AppColors.statusActiveText;
      case DriverStatus.inactive:
        bg = AppColors.statusInactiveBg; text = AppColors.statusInactiveText;
      case DriverStatus.suspended:
        bg = AppColors.errorBg; text = AppColors.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: text.withValues(alpha: 0.25))),
      child: Text(status.label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildAssignmentsSection() {
    final assignments = _driverService.assignments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.link, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text('Vehicle-Driver Assignments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () => _showAssignmentDialog(),
              icon: const Icon(Icons.add_link, size: 16),
              label: const Text('New Assignment'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (assignments.isEmpty)
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: const Column(
                children: [
                  Icon(Icons.link_off, size: 40, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text('No assignments yet.', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 44,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                columns: const [
                  DataColumn(label: Text('DRIVER')),
                  DataColumn(label: Text('VEHICLE')),
                  DataColumn(label: Text('ASSIGNED DATE')),
                  DataColumn(label: Text('END DATE')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTIONS'), numeric: true),
                ],
                rows: assignments.map((a) {
                  return DataRow(cells: [
                    DataCell(Text(a.driverName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(a.vehicleNumber, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700))),
                    DataCell(Text(_formatDate(a.assignedDate))),
                    DataCell(Text(a.endDate != null ? _formatDate(a.endDate) : '—')),
                    DataCell(_buildAssignmentStatusBadge(a.status)),
                    DataCell(a.isActive
                      ? TextButton(onPressed: () => _confirmEndAssignment(a), child: const Text('End', style: TextStyle(color: AppColors.error)))
                      : const SizedBox.shrink()),
                  ]);
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssignmentStatusBadge(AssignmentStatus status) {
    Color bg, text;
    switch (status) {
      case AssignmentStatus.active:
        bg = AppColors.statusActiveBg; text = AppColors.statusActiveText;
      case AssignmentStatus.completed:
        bg = AppColors.statusInactiveBg; text = AppColors.statusInactiveText;
      case AssignmentStatus.cancelled:
        bg = AppColors.errorBg; text = AppColors.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: text.withValues(alpha: 0.25))),
      child: Text(status.label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showDriverDialog(Driver? existing) {
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final phoneCtl = TextEditingController(text: existing?.phoneNumber ?? '');
    final licenceCtl = TextEditingController(text: existing?.drivingLicenceNumber ?? '');
    final addressCtl = TextEditingController(text: existing?.address ?? '');
    DateTime? licenceExpiry = existing?.licenceExpiryDate;
    DriverStatus selectedStatus = existing?.status ?? DriverStatus.active;
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Driver' : 'Edit Driver', style: const TextStyle(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Full Name *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: phoneCtl, decoration: const InputDecoration(labelText: 'Phone Number *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: licenceCtl, decoration: const InputDecoration(labelText: 'Driving Licence No. *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Licence number is required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: addressCtl, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Licence Expiry Date', style: TextStyle(fontSize: 14)),
                      subtitle: Text(licenceExpiry != null ? _formatDate(licenceExpiry) : 'Not set'),
                      trailing: IconButton(icon: const Icon(Icons.calendar_today, size: 20), onPressed: () async {
                        final picked = await showDatePicker(context: context, initialDate: licenceExpiry ?? DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime(2020), lastDate: DateTime(2050));
                        if (picked != null) setDialogState(() => licenceExpiry = picked);
                      }),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DriverStatus>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: DriverStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                      onChanged: (v) { if (v != null) setDialogState(() => selectedStatus = v); },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAction, foregroundColor: Colors.white),
              onPressed: submitting ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => submitting = true);
                try {
                  final driver = Driver(
                    id: existing?.id ?? '',
                    name: nameCtl.text.trim(),
                    phoneNumber: phoneCtl.text.trim(),
                    drivingLicenceNumber: licenceCtl.text.trim(),
                    licenceExpiryDate: licenceExpiry,
                    address: addressCtl.text.trim().isEmpty ? null : addressCtl.text.trim(),
                    status: selectedStatus,
                    statusLabel: selectedStatus.label,
                  );
                  if (existing == null) {
                    await _driverService.createDriver(driver);
                  } else {
                    await _driverService.updateDriver(existing.id, driver);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } on ApiException catch (e) {
                  setDialogState(() => submitting = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.userMessage), backgroundColor: AppColors.error));
                  }
                } catch (e) {
                  setDialogState(() => submitting = false);
                }
              },
              child: submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(existing == null ? 'Add Driver' : 'Save Changes'),
            ),
          ],
        );
      }),
    );
  }

  void _confirmDeleteDriver(Driver driver) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Driver', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to remove ${driver.name}?'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _driverService.deleteDriver(driver.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${driver.name} removed.'), backgroundColor: AppColors.primary));
                }
              } on ApiException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.userMessage), backgroundColor: AppColors.error));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAssignmentDialog() {
    final drivers = _driverService.drivers.where((d) => d.status == DriverStatus.active).toList();
    final vehicles = _vehicleService.vehicles;
    String? selectedDriverId;
    String? selectedVehicleId;
    DateTime assignedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Assign Driver to Vehicle', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedDriverId,
                    decoration: const InputDecoration(labelText: 'Driver *'),
                    items: drivers.map((d) => DropdownMenuItem(value: d.id, child: Text('${d.name} (${d.drivingLicenceNumber})'))).toList(),
                    onChanged: (v) => setDialogState(() => selectedDriverId = v),
                    validator: (v) => v == null ? 'Select a driver' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedVehicleId,
                    decoration: const InputDecoration(labelText: 'Vehicle *'),
                    items: vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text('${v.vehicleNumber} — ${v.displayName}'))).toList(),
                    onChanged: (v) => setDialogState(() => selectedVehicleId = v),
                    validator: (v) => v == null ? 'Select a vehicle' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Assigned Date', style: TextStyle(fontSize: 14)),
                    subtitle: Text(_formatDate(assignedDate)),
                    trailing: IconButton(icon: const Icon(Icons.calendar_today, size: 20), onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: assignedDate,
                        firstDate: DateTime(2020), lastDate: DateTime(2050));
                      if (picked != null) setDialogState(() => assignedDate = picked);
                    }),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAction, foregroundColor: Colors.white),
              onPressed: submitting ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => submitting = true);
                try {
                  await _driverService.assignDriver(driverId: selectedDriverId!, vehicleId: selectedVehicleId!, assignedDate: assignedDate);
                  if (ctx.mounted) Navigator.pop(ctx);
                } on ApiException catch (e) {
                  setDialogState(() => submitting = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.userMessage), backgroundColor: AppColors.error));
                  }
                } catch (e) {
                  setDialogState(() => submitting = false);
                }
              },
              child: submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Assign'),
            ),
          ],
        );
      }),
    );
  }

  void _confirmEndAssignment(DriverAssignment assignment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Assignment', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('End the assignment of ${assignment.driverName} to vehicle ${assignment.vehicleNumber}?'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _driverService.endAssignment(assignment.id);
              } on ApiException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.userMessage), backgroundColor: AppColors.error));
                }
              }
            },
            child: const Text('End Assignment'),
          ),
        ],
      ),
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
            ElevatedButton.icon(onPressed: () => _driverService.loadDrivers(),
              icon: const Icon(Icons.refresh, size: 16), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
