import 'package:flutter/material.dart';
import '../../models/vehicle.dart';
import '../../services/api_exception.dart';
import '../../services/vehicle_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/responsive_builder.dart';
import '../../widgets/status_badge.dart';

/// Screen for registering or editing a fleet vehicle connected to Spring Boot REST API.
///
/// Features strictly the 6 core vehicle fields:
/// 1. Vehicle Number
/// 2. Company
/// 3. Type
/// 4. Brand
/// 5. Model
/// 6. Status
class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicleToEdit;

  const VehicleFormScreen({
    super.key,
    this.vehicleToEdit,
  });

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleService = VehicleService();

  late TextEditingController _vehicleNumberController;
  late TextEditingController _companyController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;

  late VehicleType _selectedType;
  late VehicleStatus _selectedStatus;

  bool _isSubmitting = false;
  String? _backendError;

  bool get isEditing => widget.vehicleToEdit != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicleToEdit;

    _vehicleNumberController = TextEditingController(text: v?.vehicleNumber ?? '');
    _companyController = TextEditingController(text: v?.company ?? '');
    _brandController = TextEditingController(text: v?.brand ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');

    _selectedType = v?.type ?? VehicleType.truck;
    _selectedStatus = v?.status ?? VehicleStatus.active;
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _companyController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _backendError = null;
    });

    final vehicleNumber = _vehicleNumberController.text.trim().toUpperCase();
    final company = _companyController.text.trim();
    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();

    try {
      if (isEditing) {
        final updated = widget.vehicleToEdit!.copyWith(
          vehicleNumber: vehicleNumber,
          company: company,
          type: _selectedType,
          brand: brand,
          model: model,
          status: _selectedStatus,
        );
        await _vehicleService.updateVehicle(widget.vehicleToEdit!.id, updated);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle $vehicleNumber updated successfully.'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        final newVehicle = Vehicle(
          id: '',
          vehicleNumber: vehicleNumber,
          company: company,
          type: _selectedType,
          brand: brand,
          model: model,
          status: _selectedStatus,
        );
        await _vehicleService.registerVehicle(newVehicle);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle $vehicleNumber registered successfully.'),
            backgroundColor: AppColors.statusActiveText,
          ),
        );
      }

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _backendError = e.userMessage;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.userMessage),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backendError = 'Failed to save vehicle: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isEditing ? 'Edit Vehicle' : 'Register Vehicle';
    final subtitle = isEditing
        ? 'Update fleet record for ${widget.vehicleToEdit!.vehicleNumber} via Spring Boot API'
        : 'Enter required fleet specifications to register asset into VMS database';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAction,
                foregroundColor: Colors.white,
              ),
              onPressed: _isSubmitting ? null : _saveVehicle,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(
                _isSubmitting
                    ? 'Saving...'
                    : (isEditing ? 'Save Changes' : 'Register Vehicle'),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form Header Card
                  _buildHeaderCard(title, subtitle),
                  const SizedBox(height: 20),

                  // Backend Error Banner if any
                  if (_backendError != null) ...[
                    _buildErrorBanner(_backendError!),
                    const SizedBox(height: 20),
                  ],

                  // Group 1: Fleet Identification
                  _buildIdentificationGroup(context),
                  const SizedBox(height: 20),

                  // Group 2: Vehicle Classification
                  _buildClassificationGroup(context),
                  const SizedBox(height: 20),

                  // Group 3: Operational Status
                  _buildStatusGroup(context),
                  const SizedBox(height: 28),

                  // Bottom Action Buttons
                  _buildBottomActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Backend Validation / Request Error',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(String title, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryAction.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryAction.withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(
                Icons.directions_car,
                color: AppColors.primaryAction,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isEditing)
              StatusBadge(status: widget.vehicleToEdit!.status),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentificationGroup(BuildContext context) {
    final companies = _vehicleService.availableCompanies;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupHeader(
              icon: Icons.tag,
              title: '1. Fleet Identification',
              description: 'Primary registry number and operating company division',
            ),
            const SizedBox(height: 20),
            _buildResponsiveRow(
              context,
              child1: TextFormField(
                controller: _vehicleNumberController,
                textCapitalization: TextCapitalization.characters,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number *',
                  hintText: 'e.g. STK-1042',
                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  helperText: 'Must be unique across fleet (3 - 32 characters)',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a vehicle number (e.g. STK-1042)';
                  }
                  if (val.trim().length < 3 || val.trim().length > 32) {
                    return 'Vehicle number must be between 3 and 32 characters';
                  }
                  return null;
                },
              ),
              child2: Autocomplete<String>(
                initialValue: TextEditingValue(text: _companyController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return companies;
                  }
                  return companies.where((c) => c
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  _companyController.text = selection;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  controller.addListener(() {
                    _companyController.text = controller.text;
                  });

                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Company *',
                      hintText: 'e.g. Stark Logistics',
                      prefixIcon: Icon(Icons.business_outlined, size: 20),
                      helperText: 'Select or enter Stark operating unit (max 120 chars)',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter or select operating company';
                      }
                      if (val.trim().length > 120) {
                        return 'Company name cannot exceed 120 characters';
                      }
                      return null;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassificationGroup(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupHeader(
              icon: Icons.category_outlined,
              title: '2. Vehicle Classification',
              description: 'Body type, brand manufacturer, and specific model designation',
            ),
            const SizedBox(height: 20),
            // Type dropdown
            DropdownButtonFormField<VehicleType>(
              key: ValueKey(_selectedType),
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Vehicle Type *',
                prefixIcon: Icon(Icons.local_shipping_outlined, size: 20),
                helperText: 'Backend enum: TRUCK, VAN, HEAVY_HAULER, SEDAN, SUV, ELECTRIC',
              ),
              items: VehicleType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                );
              }).toList(),
              onChanged: _isSubmitting
                  ? null
                  : (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
            ),
            const SizedBox(height: 18),
            _buildResponsiveRow(
              context,
              child1: TextFormField(
                controller: _brandController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Brand / Manufacturer *',
                  hintText: 'e.g. Scania, Volvo, Mercedes-Benz, Ford',
                  prefixIcon: Icon(Icons.stars_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Brand / Manufacturer is required';
                  }
                  if (val.trim().length > 80) {
                    return 'Brand cannot exceed 80 characters';
                  }
                  return null;
                },
              ),
              child2: TextFormField(
                controller: _modelController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Model *',
                  hintText: 'e.g. R500 V8, FH16, Sprinter 319',
                  prefixIcon: Icon(Icons.directions_car_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Model name is required';
                  }
                  if (val.trim().length > 80) {
                    return 'Model cannot exceed 80 characters';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusGroup(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupHeader(
              icon: Icons.traffic_outlined,
              title: '3. Operational Status',
              description: 'Current readiness of the vehicle for dispatch and deployment',
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<VehicleStatus>(
              key: ValueKey(_selectedStatus),
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Operational Status *',
                prefixIcon: Icon(Icons.flag_outlined, size: 20),
                helperText: 'Backend enum: ACTIVE, MAINTENANCE, INACTIVE',
              ),
              items: VehicleStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      StatusBadge(status: status, showDescriptionTooltip: false),
                      const SizedBox(width: 12),
                      Text(
                        status.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _isSubmitting
                  ? null
                  : (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryAction),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildResponsiveRow(
    BuildContext context, {
    required Widget child1,
    required Widget child2,
  }) {
    if (Responsive.isMobile(context)) {
      return Column(
        children: [
          child1,
          const SizedBox(height: 18),
          child2,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: child1),
        const SizedBox(width: 18),
        Expanded(child: child2),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 14),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAction,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSubmitting ? null : _saveVehicle,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_outlined, size: 18),
          label: Text(
            _isSubmitting
                ? 'Saving...'
                : (isEditing ? 'Save Changes' : 'Register Vehicle'),
          ),
        ),
      ],
    );
  }
}
