import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../routes.dart';
import '../data/hive_boxes.dart';
import '../data/vehicle.dart';
import '../data/vehicle_repo.dart';

class VehiclesHomePage extends StatefulWidget {
  const VehiclesHomePage({super.key});

  @override
  State<VehiclesHomePage> createState() => _VehiclesHomePageState();
}

class _VehiclesHomePageState extends State<VehiclesHomePage> {
  final VehicleRepo _repo = VehicleRepo();

  int _remainingKm(Vehicle v) {
    final dueAt = v.savedOdometerKm + v.defaultIntervalKm;
    return dueAt - v.currentOdometerKm;
  }

  double _progressUsed(Vehicle v) {
    final interval = v.defaultIntervalKm <= 0 ? 1 : v.defaultIntervalKm;
    final used = (v.currentOdometerKm - v.savedOdometerKm) / interval;
    return used.clamp(0.0, 1.0);
  }

  Color _barColor(Vehicle v) {
    final interval = v.defaultIntervalKm <= 0 ? 1 : v.defaultIntervalKm;
    final remaining = _remainingKm(v);

    if (remaining <= 0) return Colors.red;

    final ratioLeft = remaining / interval;
    if (ratioLeft > 0.70) return Colors.green;
    if (ratioLeft > 0.30) return Colors.amber;
    return Colors.red;
  }

  Future<void> _oilChanged(Vehicle v) async {
    final updated = v.copyWith(
      savedOdometerKm: v.currentOdometerKm,
      currentOdometerKm: v.currentOdometerKm,
    );
    await _repo.update(updated);
  }

  Future<void> _confirmDelete(Vehicle v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete vehicle?'),
        content: Text('Delete "${v.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await _repo.delete(v.id);
  }

  @override
  Widget build(BuildContext context) {
    final Box<Map> box = HiveBoxes.vehiclesBox();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addVehicle),
        icon: const Icon(Icons.add),
        label: const Text('Add vehicle'),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<Map>>(
          valueListenable: box.listenable() as ValueListenable<Box<Map>>,
          builder: (context, _, __) {
            final vehicles = _repo.getAllSync();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    count: vehicles.length,
                    onAdd: () => context.push(AppRoutes.addVehicle),
                  ),
                ),

                if (vehicles.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                    sliver: SliverList.separated(
                      itemCount: vehicles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final v = vehicles[i];
                        final remaining = _remainingKm(v);
                        final used = _progressUsed(v);
                        final barColor = _barColor(v);

                        return _VehicleCard(
                          vehicle: v,
                          remainingKm: remaining,
                          used: used,
                          barColor: barColor,
                          onCheck: () => context.push(AppRoutes.checkVehicle, extra: v),
                          onOilChanged: () => _oilChanged(v),
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
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final VoidCallback onAdd;

  const _Header({required this.count, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(0.28),
            cs.tertiary.withOpacity(0.18),
            const Color(0xFF111A33).withOpacity(0.85),
          ],
        ),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 12),
            color: cs.primary.withOpacity(0.10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  cs.primary.withOpacity(0.95),
                  cs.tertiary.withOpacity(0.85),
                ],
              ),
            ),
            child: Icon(Icons.oil_barrel, color: cs.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Oil Change', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  count == 1 ? '1 vehicle tracked' : '$count vehicles tracked',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(colors: [
                cs.primary.withOpacity(0.9),
                cs.tertiary.withOpacity(0.75),
              ]),
            ),
            child: Icon(Icons.directions_car, size: 40, color: cs.onPrimary),
          ),
          const SizedBox(height: 14),
          Text(
            'No vehicles yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your car and track when your oil is due.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final int remainingKm;
  final double used;
  final Color barColor;

  final VoidCallback onCheck;
  final VoidCallback onOilChanged;
  final VoidCallback onDelete;

  const _VehicleCard({
    required this.vehicle,
    required this.remainingKm,
    required this.used,
    required this.barColor,
    required this.onCheck,
    required this.onOilChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final statusText = remainingKm >= 0 ? 'OK' : 'OVERDUE';
    final statusBg = remainingKm >= 0
        ? cs.secondaryContainer.withOpacity(0.25)
        : cs.errorContainer.withOpacity(0.35);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF111A33),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.35),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CarPhoto(photoPath: vehicle.photoPath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ FIXED: prevents "D\nD\nD" on phones
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vehicle.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
                        ),
                        child: Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _ChipText(icon: Icons.speed, text: '${vehicle.currentOdometerKm} km'),
                      _ChipText(icon: Icons.history, text: 'Last: ${vehicle.savedOdometerKm}'),
                      _ChipText(icon: Icons.route, text: 'Int: ${vehicle.defaultIntervalKm}'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: used,
                      color: barColor,
                      backgroundColor: const Color(0xFF0B1020),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    remainingKm >= 0
                        ? 'Due in: $remainingKm km'
                        : 'Overdue by: ${remainingKm.abs()} km',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.9),
                        ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ FIXED: buttons become vertical on narrow phones
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 330;

                      if (narrow) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: onCheck,
                                icon: const Icon(Icons.speed),
                                label: const Text('Check'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: onOilChanged,
                                icon: const Icon(Icons.oil_barrel),
                                label: const Text('Oil changed'),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                tooltip: 'Delete',
                                onPressed: onDelete,
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onCheck,
                              icon: const Icon(Icons.speed),
                              label: const Text('Check'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onOilChanged,
                              icon: const Icon(Icons.oil_barrel),
                              label: const Text('Oil changed'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      );
                    },
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

class _ChipText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ChipText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF0F1730),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant.withOpacity(0.9)),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CarPhoto extends StatelessWidget {
  final String? photoPath;
  const _CarPhoto({required this.photoPath});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final cs = Theme.of(context).colorScheme;
    final has = photoPath != null && photoPath!.isNotEmpty && File(photoPath!).existsSync();

    if (has) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.file(
          File(photoPath!),
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(cs, radius),
        ),
      );
    }
    return _fallback(cs, radius);
  }

  Widget _fallback(ColorScheme cs, BorderRadius radius) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(0.45),
            cs.tertiary.withOpacity(0.25),
          ],
        ),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
      ),
      child: Icon(Icons.directions_car, size: 36, color: cs.onPrimary),
    );
  }
}
