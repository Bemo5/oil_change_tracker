import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';
import 'theme.dart';
import 'features/vehicles/ui/vehicles_home_page.dart';
import 'features/vehicles/ui/vehicle_form_page.dart';
import 'features/vehicles/ui/vehicle_check_page.dart';
import 'features/vehicles/data/vehicle.dart';

class OilChangeApp extends StatelessWidget {
  OilChangeApp({super.key});

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
        path: AppRoutes.checkVehicle,
        builder: (context, state) {
          final v = state.extra as Vehicle;
          return VehicleCheckPage(vehicle: v);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Oil Change',
      theme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}
