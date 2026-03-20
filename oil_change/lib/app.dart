import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'l10n.dart';
import 'routes.dart';
import 'theme.dart';
import 'features/vehicles/ui/vehicles_home_page.dart';
import 'features/vehicles/ui/vehicle_form_page.dart';
import 'features/vehicles/data/vehicle.dart';
import 'features/maintenance/ui/vehicle_detail_page.dart';
import 'features/maintenance/ui/manage_types_page.dart';

class MaintenanceApp extends StatefulWidget {
  const MaintenanceApp({super.key});

  @override
  State<MaintenanceApp> createState() => _MaintenanceAppState();
}

class _MaintenanceAppState extends State<MaintenanceApp> {
  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.vehicles,
        builder: (context, state) => const VehiclesHomePage(),
      ),
      GoRoute(
        path: AppRoutes.addVehicle,
        builder: (context, state) => const VehicleFormPage(),
      ),
      GoRoute(
        path: AppRoutes.editVehicle,
        builder: (context, state) {
          final v = state.extra as Vehicle;
          return VehicleFormPage(vehicle: v);
        },
      ),
      GoRoute(
        path: AppRoutes.vehicleDetail,
        builder: (context, state) {
          final v = state.extra as Vehicle;
          return VehicleDetailPage(vehicle: v);
        },
      ),
      GoRoute(
        path: AppRoutes.manageTypes,
        builder: (context, state) => const ManageTypesPage(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: S.isArabic,
      builder: (context, isAr, _) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: MaterialApp.router(
            title: 'Maintenance',
            theme: AppTheme.dark(),
            routerConfig: _router,
          ),
        );
      },
    );
  }
}
