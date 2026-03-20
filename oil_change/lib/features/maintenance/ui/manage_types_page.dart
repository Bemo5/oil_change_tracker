import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../l10n.dart';
import '../../vehicles/data/hive_boxes.dart';
import '../../vehicles/data/vehicle_repo.dart';
import '../data/maintenance_type.dart';
import '../data/maintenance_type_repo.dart';
import '../data/maintenance_item_repo.dart';
import '../data/maintenance_record_repo.dart';
import '../data/backup_service.dart';

// Conditional import for dart:io (not available on web)
import 'manage_types_io.dart' if (dart.library.html) 'manage_types_web.dart' as platform;

class ManageTypesPage extends StatefulWidget {
  const ManageTypesPage({super.key});

  @override
  State<ManageTypesPage> createState() => _ManageTypesPageState();
}

class _ManageTypesPageState extends State<ManageTypesPage> {
  final _typeRepo = MaintenanceTypeRepo();
  final _itemRepo = MaintenanceItemRepo();
  final _recordRepo = MaintenanceRecordRepo();
  final _vehicleRepo = VehicleRepo();
  final _backup = BackupService();

  Future<void> _addType() async {
    final nameCtrl = TextEditingController();
    final kmCtrl = TextEditingController(text: '5000');
    final monthsCtrl = TextEditingController(text: '6');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.newType),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: S.name_),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: kmCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: S.intervalKm),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: monthsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: S.intervalMonths),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(S.add)),
        ],
      ),
    );

    if (result != true) return;

    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    final km = int.tryParse(kmCtrl.text.trim()) ?? 5000;
    final months = int.tryParse(monthsCtrl.text.trim()) ?? 6;

    final newType = await _typeRepo.add(name: name, defaultIntervalKm: km, defaultIntervalMonths: months);

    final vehicles = _vehicleRepo.getAllSync();
    for (final v in vehicles) {
      await _itemRepo.addForVehicle(
        vehicleId: v.id,
        typeId: newType.id,
        typeName: newType.name,
        intervalKm: newType.defaultIntervalKm,
        intervalMonths: newType.defaultIntervalMonths,
        savedOdometerKm: v.currentOdometerKm,
      );
    }
  }

  Future<void> _confirmDelete(MaintenanceType t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.deleteTypeQ),
        content: Text(S.deleteTypeMsg(t.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(S.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await _typeRepo.delete(t.id);
    await _itemRepo.deleteByTypeId(t.id);
    await _recordRepo.deleteByTypeId(t.id);
  }

  Future<void> _export() async {
    try {
      final json = _backup.exportToJson();
      await platform.exportJson(json);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.exportedOk)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _import() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.importDataQ),
        content: Text(S.importDataMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(S.import_)),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final json = await platform.pickAndReadJson();
      if (json == null) return;

      await _backup.importFromJson(json);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.importedOk)));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = HiveBoxes.maintenanceTypesBox();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.settings),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addType,
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder<Box<Map>>(
        valueListenable: box.listenable() as ValueListenable<Box<Map>>,
        builder: (context, _, __) {
          final types = _typeRepo.getAllSync();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              // Import / Export
              Text(S.data, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _export,
                      icon: const Icon(Icons.upload_outlined, size: 18),
                      label: Text(S.export_),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _import,
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: Text(S.import_),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text(S.maintenanceTypes, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              if (types.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(S.noTypes, style: TextStyle(color: cs.onSurfaceVariant)),
                )
              else
                ...types.map((t) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111A33),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text(t.name),
                        subtitle: Text('${t.defaultIntervalKm} km / ${t.defaultIntervalMonths} mo'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _confirmDelete(t),
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
