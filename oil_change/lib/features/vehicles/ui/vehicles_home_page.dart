import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../l10n.dart';
import '../../../platform_utils.dart' as pu;
import '../../../routes.dart';
import '../data/hive_boxes.dart';
import '../data/vehicle.dart';
import '../data/vehicle_repo.dart';
import '../../maintenance/data/maintenance_item_repo.dart';
import '../../maintenance/data/maintenance_record_repo.dart';

class VehiclesHomePage extends StatefulWidget {
  const VehiclesHomePage({super.key});

  @override
  State<VehiclesHomePage> createState() => _VehiclesHomePageState();
}

class _VehiclesHomePageState extends State<VehiclesHomePage> {
  final _repo = VehicleRepo();
  final _itemRepo = MaintenanceItemRepo();
  final _recordRepo = MaintenanceRecordRepo();

  _Summary _summarize(Vehicle v) {
    final items = _itemRepo.getForVehicle(v.id);
    int due = 0, overdue = 0;

    for (final item in items) {
      final remaining = (item.savedOdometerKm + item.intervalKm) - v.currentOdometerKm;
      if (remaining <= 0) {
        overdue++;
      } else {
        final ratio = remaining / (item.intervalKm <= 0 ? 1 : item.intervalKm);
        final timeDue = item.lastServiceDate != null &&
            DateTime.now().isAfter(DateTime(
              item.lastServiceDate!.year,
              item.lastServiceDate!.month + item.intervalMonths,
              item.lastServiceDate!.day,
            ));
        if (ratio <= 0.20 || timeDue) due++;
      }
    }

    return _Summary(total: items.length, due: due, overdue: overdue);
  }

  Future<void> _confirmDelete(Vehicle v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.deleteVehicleQ),
        content: Text(S.deleteVehicleMsg(v.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(S.delete)),
        ],
      ),
    );
    if (ok == true) {
      await _repo.delete(v.id);
      await _itemRepo.deleteForVehicle(v.id);
      await _recordRepo.deleteForVehicle(v.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = HiveBoxes.vehiclesBox();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addVehicle),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: S.isArabic,
          builder: (context, _, __) => ValueListenableBuilder<Box<Map>>(
            valueListenable: box.listenable() as ValueListenable<Box<Map>>,
            builder: (context, _, __) {
              final vehicles = _repo.getAllSync();

              return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                    child: Row(
                      children: [
                        Icon(Icons.handyman, color: cs.primary, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(S.maintenance, style: tt.titleLarge),
                              Text(
                                S.vehicles(vehicles.length),
                                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: S.isArabic,
                          builder: (context, isAr, _) => SizedBox(
                            height: 30,
                            child: TextButton(
                              onPressed: () => S.toggle(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                isAr ? 'EN' : 'ع',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: S.settings,
                          onPressed: () => context.push(AppRoutes.manageTypes),
                          icon: const Icon(Icons.settings_outlined),
                        ),
                      ],
                    ),
                  ),
                ),

                if (vehicles.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_car, size: 48, color: cs.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(S.noVehiclesYet, style: tt.titleMedium),
                          const SizedBox(height: 4),
                          Text(S.tapToAdd, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    sliver: SliverList.separated(
                      itemCount: vehicles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final v = vehicles[i];
                        final s = _summarize(v);
                        return _VehicleCard(
                          vehicle: v,
                          summary: s,
                          onTap: () => context.push(AppRoutes.vehicleDetail, extra: v),
                          onEdit: () => context.push(AppRoutes.editVehicle, extra: v),
                          onDelete: () => _confirmDelete(v),
                        );
                      },
                    ),
                  ),
              ],
            );
            },
          ),
        ),
      ),
    );
  }
}

class _Summary {
  final int total, due, overdue;
  const _Summary({required this.total, required this.due, required this.overdue});
  bool get allOk => due == 0 && overdue == 0;
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final _Summary summary;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VehicleCard({
    required this.vehicle,
    required this.summary,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final Color badgeColor;
    final String badgeText;
    if (summary.overdue > 0) {
      badgeColor = Colors.red;
      badgeText = S.overdue(summary.overdue);
    } else if (summary.due > 0) {
      badgeColor = Colors.amber;
      badgeText = S.due(summary.due);
    } else {
      badgeColor = Colors.green;
      badgeText = S.allOk;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111A33),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            _Photo(photoPath: vehicle.photoPath),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vehicle.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(color: badgeColor, fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${vehicle.currentOdometerKm} km',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: FilledButton(
                            onPressed: onTap,
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              textStyle: tt.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            child: Text(S.details),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          padding: EdgeInsets.zero,
                          tooltip: S.edit,
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 16),
                          padding: EdgeInsets.zero,
                          tooltip: S.delete,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final String? photoPath;
  const _Photo({required this.photoPath});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(14);
    final has = photoPath != null && photoPath!.isNotEmpty && pu.fileExists(photoPath!);

    if (has) {
      return ClipRRect(
        borderRadius: radius,
        child: pu.fileImage(photoPath!, width: 72, height: 72, fit: BoxFit.cover,
            fallback: () => _fallback(cs, radius)),
      );
    }
    return _fallback(cs, radius);
  }

  Widget _fallback(ColorScheme cs, BorderRadius radius) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(colors: [cs.primary.withOpacity(0.35), cs.tertiary.withOpacity(0.2)]),
      ),
      child: Icon(Icons.directions_car, size: 28, color: cs.onPrimary),
    );
  }
}
