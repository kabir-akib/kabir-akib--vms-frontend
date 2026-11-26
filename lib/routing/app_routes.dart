import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../screens/auth/login_screen.dart';
import '../screens/shell/app_shell.dart';
import '../screens/vehicles/vehicle_form_screen.dart';
import '../services/auth_service.dart';

/// Application routing paths and generator.
class AppRoutes {
  static const String login = '/login';
  static const String shell = '/';
  static const String vehicleNew = '/vehicles/new';
  static const String vehicleEdit = '/vehicles/edit';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final isAuthenticated = AuthService().isAuthenticated;

    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case shell:
        return MaterialPageRoute(
          builder: (_) =>
              isAuthenticated ? const AppShell() : const LoginScreen(),
          settings: settings,
        );

      case vehicleNew:
        return MaterialPageRoute(
          builder: (_) => isAuthenticated
              ? const VehicleFormScreen()
              : const LoginScreen(),
          settings: settings,
        );

      case vehicleEdit:
        final vehicle = settings.arguments as Vehicle?;
        return MaterialPageRoute(
          builder: (_) => isAuthenticated
              ? VehicleFormScreen(vehicleToEdit: vehicle)
              : const LoginScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
          settings: settings,
        );
    }
  }
}

