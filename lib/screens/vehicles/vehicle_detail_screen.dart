import 'package:flutter/material.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_document.dart';
import '../../models/vehicle_maintenance.dart';
import '../../models/driver_assignment.dart';
import '../../services/vehicle_service.dart';
import '../../services/document_service.dart';
import '../../services/maintenance_service.dart';
import '../../services/driver_service.dart';
import '../../services/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import 'package:file_picker/file_picker.dart';

/// Comprehensive vehicle dossier screen with tabs for details, documents, maintenance, and assignments.
class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> with SingleTickerProviderStateMixin {
  final _vehicleService = VehicleService();
  final _documentService = DocumentService();
  final _maintenanceService = MaintenanceService();
  final _driverService = DriverService();

  late TabController _tabController;
  Vehicle? _vehicle;
  List<VehicleDocument> _documents = [];
  List<VehicleMaintenance> _maintenanceRecords = [];
  List<DriverAssignment> _assignments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final vehicle = await _vehicleService.getVehicleById(widget.vehicleId);
      final docs = await _documentService.getDocumentsForVehicle(widget.vehicleId);
      final maintenance = await _maintenanceService.getMaintenanceHistory(widget.vehicleId);
      final assignments = await _driverService.getVehicleAssignments(widget.vehicleId);
      if (mounted) {
        setState(() {
          _vehicle = vehicle;
          _documents = docs;
          _maintenanceRecords = maintenance;
          _assignments = assignments;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.userMessage; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load vehicle details: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vehicle != null ? 'Vehicle ${_vehicle!.vehicleNumber}' : 'Vehicle Details'),
        bottom: _vehicle != null ? TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primaryActionHover,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryAction,
          tabs: const [
            Tab(text: 'Specifications'),
            Tab(text: 'Documents'),
            Tab(text: 'Maintenance'),
            Tab(text: 'Assignments'),
          ],
        ) : null,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAction, strokeWidth: 3))
        : _error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh, size: 16), label: const Text('Retry')),
            ]))
          : TabBarView(controller: _tabController, children: [
              _buildSpecsTab(),
              _buildDocumentsTab(),
              _buildMaintenanceTab(),
              _buildAssignmentsTab(),
            ]),
    );
  }

  // --- Specifications Tab ---
  Widget _buildSpecsTab() {
    final v = _vehicle!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(_getVehicleTypeIcon(v.type), color: AppColors.primaryAction, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderStrong, width: 1.2)),
                      child: Text(v.vehicleNumber, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1)),
                    ),
                    const SizedBox(width: 16),
                    StatusBadge(status: v.status),
                  ],
                ),
                const SizedBox(height: 20),
                _specRow('Display Name', v.displayName),
                _specRow('Company', v.company),
                _specRow('Type', v.type.label),
                _specRow('Brand', v.brand),
                _specRow('Model', v.model),
                _specRow('Status', v.status.label),
                if (v.createdAt != null) _specRow('Registered', _formatDateTime(v.createdAt!)),
                if (v.updatedAt != null) _specRow('Last Updated', _formatDateTime(v.updatedAt!)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // --- Documents Tab ---
  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Documents (${_documents.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAction, foregroundColor: Colors.white),
                onPressed: _showUploadDialog,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload Document'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_documents.isEmpty)
            Card(child: Container(width: double.infinity, padding: const EdgeInsets.all(32),
              child: const Column(children: [
                Icon(Icons.folder_open, size: 40, color: AppColors.textMuted),
                SizedBox(height: 8),
                Text('No documents uploaded for this vehicle.', style: TextStyle(color: AppColors.textSecondary)),
              ])))
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 44,
                  columns: const [
                    DataColumn(label: Text('TYPE')),
                    DataColumn(label: Text('FILENAME')),
                    DataColumn(label: Text('SIZE')),
                    DataColumn(label: Text('EXPIRY')),
                    DataColumn(label: Text('UPLOADED')),
                    DataColumn(label: Text('ACTIONS'), numeric: true),
                  ],
                  rows: _documents.map((doc) => DataRow(cells: [
                    DataCell(Text(doc.documentTypeLabel ?? doc.documentType.label)),
                    DataCell(Text(doc.originalFilename, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(doc.formattedFileSize)),
                    DataCell(Text(doc.expiryDate != null ? _formatDate(doc.expiryDate!) : '—')),
                    DataCell(Text(doc.uploadDate != null ? _formatDate(doc.uploadDate!) : '—')),
                    DataCell(IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      onPressed: () => _confirmDeleteDoc(doc))),
                  ])).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    DocumentType selectedType = DocumentType.registrationCertificate;
    DateTime? expiryDate;
    PlatformFile? selectedFile;
    final formKey = GlobalKey<FormState>();
    bool uploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Upload Document', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<DocumentType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Document Type'),
                    items: DocumentType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                    onChanged: (v) { if (v != null) setDialogState(() => selectedType = v); },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Expiry Date (optional)', style: TextStyle(fontSize: 14)),
                    subtitle: Text(expiryDate != null ? _formatDate(expiryDate!) : 'Not set'),
                    trailing: IconButton(icon: const Icon(Icons.calendar_today, size: 20), onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime(2020), lastDate: DateTime(2050));
                      if (picked != null) setDialogState(() => expiryDate = picked);
                    }),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.pickFiles(withData: true);
                      if (result != null && result.files.isNotEmpty) {
                        setDialogState(() => selectedFile = result.files.first);
                      }
                    },
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: Text(selectedFile != null ? selectedFile!.name : 'Choose File'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAction, foregroundColor: Colors.white),
              onPressed: (uploading || selectedFile == null || selectedFile!.bytes == null) ? null : () async {
                setDialogState(() => uploading = true);
                try {
                  await _documentService.uploadDocument(
                    vehicleId: widget.vehicleId,
                    documentType: selectedType,
                    fileBytes: selectedFile!.bytes!.toList(),
                    filename: selectedFile!.name,
                    expiryDate: expiryDate,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
                } on ApiException catch (e) {
                  setDialogState(() => uploading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.userMessage), backgroundColor: AppColors.error));
                  }
                } catch (e) {
                  setDialogState(() => uploading = false);
                }
              },
              child: uploading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Upload'),
            ),
          ],
        );
      }),
    );
  }

  void _confirmDeleteDoc(VehicleDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Delete ${doc.originalFilename}?'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _documentService.deleteDocument(widget.vehicleId, doc.id);
                _loadData();
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

  // --- Maintenance Tab ---
  Widget _buildMaintenanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Maintenance History (${_maintenanceRecords.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAction, foregroundColor: Colors.white),
                onPressed: () => _showMaintenanceDialog(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Service'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_maintenanceRecords.isEmpty)
            Card(child: Container(width: double.infinity, padding: const EdgeInsets.all(32),
              child: const Column(children: [
                Icon(Icons.build_outlined, size: 40, color: AppColors.textMuted),
                SizedBox(height: 8),
                Text('No maintenance records for this vehicle.', style: TextStyle(color: AppColors.textSecondary)),
              ])))
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 44,
                  columns: const [
                    DataColumn(label: Text('DATE')),
                    DataColumn(label: Text('TYPE')),
                    DataColumn(label: Text('COST (BDT)')),
                    DataColumn(label: Text('VENDOR')),
                    DataColumn(label: Text('NOTES')),
                    DataColumn(label: Text('ACTIONS'), numeric: true),
                  ],
                  rows: _maintenanceRecords.map((m) => DataRow(cells: [
                    DataCell(Text(_formatDate(m.maintenanceDate))),
                    DataCell(Text(m.maintenanceTypeLabel ?? m.maintenanceType.label)),
                    DataCell(Text(m.cost.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w700))),
                    DataCell(Text(m.vendorName)),
                    DataCell(Text(m.notes ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showMaintenanceDialog(m)),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        onPressed: () => _confirmDeleteMaintenance(m)),
                    ])),
                  ])).toList(),
                ),
              ),
            ),
          if (_maintenanceRecords.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, size: 20, color: AppColors.statusActiveText),
                    const SizedBox(width: 8),
                    Text('Total Maintenance Cost: BDT ${_maintenanceRecords.fold<double>(0, (sum, m) => sum + m.cost).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showMaintenanceDialog(VehicleMaintenance? existing) {
    final dateCtl = ValueNotifier<DateTime>(existing?.maintenanceDate ?? DateTime.now());
    MaintenanceType selectedType = existing?.maintenanceType ?? MaintenanceType.routineService;
    final costCtl = TextEditingController(text: existing != null ? existing.cost.toStringAsFixed(2) : '');
    final vendorCtl = TextEditingController(text: existing?.vendorName ?? '');
    final notesCtl = TextEditingController(text: existing?.notes ?? '');
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(existing == null ? 'Log Maintenance' : 'Edit Maintenance', style: const TextStyle(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<DateTime>(
                      valueListenable: dateCtl,
                      builder: (_, date, _) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Service Date *', style: TextStyle(fontSize: 14)),
                        subtitle: Text(_formatDate(date)),
                        trailing: IconButton(icon: const Icon(Icons.calendar_today, size: 20), onPressed: () async {
                          final picked = await showDatePicker(context: context, initialDate: date,
                            firstDate: DateTime(2020), lastDate: DateTime.now());
                          if (picked != null) dateCtl.value = picked;
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MaintenanceType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Maintenance Type *'),
                      items: MaintenanceType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                      onChanged: (v) { if (v != null) setDialogState(() => selectedType = v); },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: costCtl, decoration: const InputDecoration(labelText: 'Cost (BDT) *', prefixText: 'BDT '),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Cost is required';
                        if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                        return null;
                      }),
                    const SizedBox(height: 12),
                    TextFormField(controller: vendorCtl, decoration: const InputDecoration(labelText: 'Vendor / Workshop *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Vendor name is required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: notesCtl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
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
                  final record = VehicleMaintenance(
                    id: existing?.id ?? '',
                    vehicleId: widget.vehicleId,
                    vehicleNumber: _vehicle?.vehicleNumber ?? '',
                    vehicleDisplayName: _vehicle?.displayName ?? '',
                    maintenanceDate: dateCtl.value,
                    maintenanceType: selectedType,
                    cost: double.parse(costCtl.text.trim()),
                    vendorName: vendorCtl.text.trim(),
                    notes: notesCtl.text.trim().isEmpty ? null : notesCtl.text.trim(),
                  );
                  if (existing == null) {
                    await _maintenanceService.createMaintenance(widget.vehicleId, record);
                  } else {
                    await _maintenanceService.updateMaintenance(widget.vehicleId, existing.id, record);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
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
                : Text(existing == null ? 'Log Service' : 'Save Changes'),
            ),
          ],
        );
      }),
    );
  }

  void _confirmDeleteMaintenance(VehicleMaintenance m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Delete ${m.maintenanceType.label} record from ${_formatDate(m.maintenanceDate)}?'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _maintenanceService.deleteMaintenance(widget.vehicleId, m.id);
                _loadData();
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

  // --- Assignments Tab ---
  Widget _buildAssignmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Driver Assignments (${_assignments.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (_assignments.isEmpty)
            Card(child: Container(width: double.infinity, padding: const EdgeInsets.all(32),
              child: const Column(children: [
                Icon(Icons.person_off, size: 40, color: AppColors.textMuted),
                SizedBox(height: 8),
                Text('No driver assignments for this vehicle.', style: TextStyle(color: AppColors.textSecondary)),
              ])))
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 44,
                  columns: const [
                    DataColumn(label: Text('DRIVER')),
                    DataColumn(label: Text('LICENCE')),
                    DataColumn(label: Text('ASSIGNED')),
                    DataColumn(label: Text('ENDED')),
                    DataColumn(label: Text('STATUS')),
                  ],
                  rows: _assignments.map((a) => DataRow(cells: [
                    DataCell(Text(a.driverName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(a.drivingLicenceNumber ?? '—', style: const TextStyle(fontFamily: 'monospace'))),
                    DataCell(Text(_formatDate(a.assignedDate))),
                    DataCell(Text(a.endDate != null ? _formatDate(a.endDate) : '—')),
                    DataCell(_buildAssignmentBadge(a.status)),
                  ])).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAssignmentBadge(AssignmentStatus status) {
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

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getVehicleTypeIcon(VehicleType type) {
    switch (type) {
      case VehicleType.truck:
        return Icons.local_shipping;
      case VehicleType.heavyHauler:
        return Icons.fire_truck;
      case VehicleType.van:
        return Icons.airport_shuttle;
      case VehicleType.sedan:
        return Icons.directions_car;
      case VehicleType.suv:
        return Icons.directions_car_filled;
      case VehicleType.electric:
        return Icons.electric_car;
    }
  }
}
