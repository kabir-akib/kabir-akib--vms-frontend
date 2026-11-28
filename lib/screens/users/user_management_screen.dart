import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';

/// Admin‑only screen for managing users.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Load users once after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userService.loadUsers();
    });
  }

  void _showCreateUserDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String password = '';
    String role = 'EMPLOYEE';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New User'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  onSaved: (v) => name = v!.trim(),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  onSaved: (v) => email = v!.trim(),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 8) ? 'Min 8 chars' : null,
                  onSaved: (v) => password = v!,
                ),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                    DropdownMenuItem(value: 'EMPLOYEE', child: Text('EMPLOYEE')),
                  ],
                  onChanged: (v) => role = v ?? 'EMPLOYEE',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                Navigator.pop(ctx);
                try {
                  await _userService.createUser(
                    name: name,
                    email: email,
                    password: password,
                    role: role,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User created successfully')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create user: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _userService,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              if (_userService.isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primaryAction, strokeWidth: 3)))
              else if (_userService.hasError)
                _buildError(_userService.errorMessage!)
              else
                _buildUsersTable(),
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
              const Text('User Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text('${_userService.users.length} users registered',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _userService.loadUsers()),
            const SizedBox(width: 8),
            if (_authService.currentUser?.role == 'ADMIN')
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAction, foregroundColor: Colors.white),
                onPressed: _showCreateUserDialog,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Create User'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsersTable() {
    final users = _userService.users;
    if (users.isEmpty) {
      return Card(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          child: const Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text('No Users Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('No user accounts have been created yet.', style: TextStyle(color: AppColors.textSecondary)),
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
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
          columns: const [
            DataColumn(label: Text('NAME')),
            DataColumn(label: Text('EMAIL')),
            DataColumn(label: Text('ROLE')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('CREATED')),
          ],
          rows: users.map((u) {
            final created = u.createdAt != null
                ? '${u.createdAt!.year}-${u.createdAt!.month.toString().padLeft(2, '0')}-${u.createdAt!.day.toString().padLeft(2, '0')}'
                : '—';
            return DataRow(cells: [
              DataCell(Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(u.email)),
              DataCell(_buildRoleBadge(u.role)),
              DataCell(_buildStatusBadge(u.status)),
              DataCell(Text(created)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final isAdmin = role.toUpperCase() == 'ADMIN';
    final bg = isAdmin ? AppColors.primaryAction.withValues(alpha: 0.12) : AppColors.surfaceVariant;
    final text = isAdmin ? AppColors.primaryAction : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: text.withValues(alpha: 0.25))),
      child: Text(role, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status.toUpperCase() == 'ACTIVE';
    final bg = isActive ? AppColors.statusActiveBg : AppColors.statusInactiveBg;
    final text = isActive ? AppColors.statusActiveText : AppColors.statusInactiveText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: text.withValues(alpha: 0.25))),
      child: Text(status, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w700)),
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
            ElevatedButton.icon(onPressed: () => _userService.loadUsers(),
              icon: const Icon(Icons.refresh, size: 16), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
