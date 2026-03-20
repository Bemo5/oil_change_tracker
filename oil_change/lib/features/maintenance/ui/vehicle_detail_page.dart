import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n.dart';
import '../../vehicles/data/vehicle.dart';
import '../../vehicles/data/vehicle_repo.dart';
import '../data/maintenance_item.dart';
import '../data/maintenance_item_repo.dart';
import '../data/maintenance_record.dart';
import '../data/maintenance_record_repo.dart';
import '../data/maintenance_type_repo.dart';

class VehicleDetailPage extends StatefulWidget {
  final Vehicle vehicle;
  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final _vehicleRepo = VehicleRepo();
  final _itemRepo = MaintenanceItemRepo();
  final _recordRepo = MaintenanceRecordRepo();
  final _typeRepo = MaintenanceTypeRepo();
  final _odometerCtrl = TextEditingController();

  late Vehicle _vehicle;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _odometerCtrl.text = _vehicle.currentOdometerKm.toString();
  }

  @override
  void dispose() {
    _odometerCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateMileage() async {
    final km = int.tryParse(_odometerCtrl.text.trim());
    if (km == null || km < 0) return;
    _vehicle = _vehicle.copyWith(currentOdometerKm: km);
    await _vehicleRepo.update(_vehicle);
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  // ── Add item: pick from existing types or create custom ──

  Future<void> _addItem() async {
    final existingItems = _itemRepo.getForVehicle(_vehicle.id);
    final existingTypeIds = existingItems.map((i) => i.typeId).toSet();
    final allTypes = _typeRepo.getAllSync();
    final availableTypes = allTypes.where((t) => !existingTypeIds.contains(t.id)).toList();

    if (!mounted) return;

    final result = await showModalBottomSheet<_AddItemResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddItemSheet(availableTypes: availableTypes),
    );

    if (result == null) return;

    await _itemRepo.addForVehicle(
      vehicleId: _vehicle.id,
      typeId: result.typeId,
      typeName: result.name,
      intervalKm: result.intervalKm,
      intervalMonths: result.intervalMonths,
      savedOdometerKm: _vehicle.currentOdometerKm,
    );
    setState(() {});
  }

  // ── Remove item with confirmation ──

  Future<void> _removeItem(MaintenanceItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.removeItem),
        content: Text(S.removeItemMsg(item.typeName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(S.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await _itemRepo.delete(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.removed)));
    setState(() {});
  }

  // ── Edit interval ──

  Future<void> _editInterval(MaintenanceItem item) async {
    final kmCtrl = TextEditingController(text: item.intervalKm.toString());
    final monthsCtrl = TextEditingController(text: item.intervalMonths.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${item.typeName} — ${S.editInterval}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: kmCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: S.intervalKm,
                prefixIcon: const Icon(Icons.straighten),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: monthsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: S.intervalMonths,
                prefixIcon: const Icon(Icons.calendar_month),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(S.save)),
        ],
      ),
    );

    if (ok != true) return;

    final km = int.tryParse(kmCtrl.text.trim()) ?? item.intervalKm;
    final months = int.tryParse(monthsCtrl.text.trim()) ?? item.intervalMonths;

    await _itemRepo.update(item.copyWith(intervalKm: km, intervalMonths: months));
    setState(() {});
  }

  // ── Mark done ──

  Future<void> _markDone(MaintenanceItem item) async {
    final priceCtrl = TextEditingController();
    final price = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${item.typeName} ${S.done.toLowerCase()}'),
        content: TextField(
          controller: priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: S.priceEgpOptional,
            prefixText: 'EGP ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, -1.0),
            child: Text(S.skip),
          ),
          FilledButton(
            onPressed: () {
              final p = double.tryParse(priceCtrl.text.trim());
              Navigator.pop(ctx, p ?? -1.0);
            },
            child: Text(S.save),
          ),
        ],
      ),
    );

    if (price == null) return;

    final actualPrice = price < 0 ? null : price;

    await _itemRepo.markDone(item, _vehicle.currentOdometerKm, priceEgp: actualPrice);
    await _recordRepo.add(
      vehicleId: _vehicle.id,
      typeId: item.typeId,
      typeName: item.typeName,
      odometerKm: _vehicle.currentOdometerKm,
      priceEgp: actualPrice,
    );
    setState(() {});
  }

  // ── Delete history record ──

  Future<void> _deleteRecord(MaintenanceRecord record) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.deleteRecordQ),
        content: Text(S.deleteRecordMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(S.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await _recordRepo.delete(record.id);
    setState(() {});
  }

  // ── Status helpers ──

  int _remainingKm(MaintenanceItem item) {
    return (item.savedOdometerKm + item.intervalKm) - _vehicle.currentOdometerKm;
  }

  double _progressUsed(MaintenanceItem item) {
    final interval = item.intervalKm <= 0 ? 1 : item.intervalKm;
    return ((_vehicle.currentOdometerKm - item.savedOdometerKm) / interval).clamp(0.0, 1.0);
  }

  bool _isTimeDue(MaintenanceItem item) {
    if (item.lastServiceDate == null) return false;
    final deadline = DateTime(
      item.lastServiceDate!.year,
      item.lastServiceDate!.month + item.intervalMonths,
      item.lastServiceDate!.day,
    );
    return DateTime.now().isAfter(deadline);
  }

  _Status _status(MaintenanceItem item) {
    final remaining = _remainingKm(item);
    if (remaining <= 0) return _Status.overdue;
    final ratio = remaining / (item.intervalKm <= 0 ? 1 : item.intervalKm);
    if (ratio <= 0.20 || _isTimeDue(item)) return _Status.due;
    return _Status.ok;
  }

  Color _statusColor(_Status s) {
    switch (s) {
      case _Status.ok:
        return Colors.green;
      case _Status.due:
        return Colors.amber;
      case _Status.overdue:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemRepo.getForVehicle(_vehicle.id);
    final history = _recordRepo.getForVehicle(_vehicle.id);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(_vehicle.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          // Odometer
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _odometerCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: S.currentMileageKm,
                    prefixIcon: const Icon(Icons.speed),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _updateMileage(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(onPressed: _updateMileage, child: Text(S.update)),
            ],
          ),

          const SizedBox(height: 24),
          Text(S.checklist, style: tt.titleMedium),
          const SizedBox(height: 10),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.build_outlined, size: 40, color: cs.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(S.noItems, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(S.tapToAdd, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            ...items.map((item) => _buildItemTile(item, cs, tt)),

          const SizedBox(height: 28),
          Text(S.history, style: tt.titleMedium),
          const SizedBox(height: 10),

          if (history.isEmpty)
            Text(S.noHistory, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
          else
            ...history.map((r) => InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onLongPress: () => _deleteRecord(r),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 18, color: cs.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(r.typeName, style: tt.bodyMedium),
                        ),
                        if (r.priceEgp != null)
                          Text(
                            '${r.priceEgp!.toStringAsFixed(0)} EGP',
                            style: tt.bodySmall?.copyWith(color: cs.primary),
                          ),
                        if (r.priceEgp != null) const SizedBox(width: 10),
                        Text(
                          '${r.odometerKm} km',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('d MMM yy').format(r.date),
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildItemTile(MaintenanceItem item, ColorScheme cs, TextTheme tt) {
    final remaining = _remainingKm(item);
    final s = _status(item);
    final sColor = _statusColor(s);
    final progress = _progressUsed(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111A33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: s == _Status.ok
              ? cs.outlineVariant.withOpacity(0.2)
              : sColor.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.typeName, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(s.label, style: TextStyle(color: sColor, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progress,
              color: sColor,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                remaining >= 0 ? S.kmLeft(remaining) : S.kmOverdue(remaining.abs()),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              if (item.lastPriceEgp != null)
                Text(
                  '${item.lastPriceEgp!.toStringAsFixed(0)} EGP',
                  style: tt.bodySmall?.copyWith(color: cs.primary),
                ),
              if (item.lastPriceEgp != null) const SizedBox(width: 10),
              if (item.lastServiceDate != null)
                Text(
                  DateFormat('d MMM yy').format(item.lastServiceDate!),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: FilledButton(
                    onPressed: () => _markDone(item),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      textStyle: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    child: Text(S.done),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 34,
                height: 34,
                child: IconButton(
                  onPressed: () => _editInterval(item),
                  icon: const Icon(Icons.tune, size: 18),
                  tooltip: S.editInterval,
                  padding: EdgeInsets.zero,
                ),
              ),
              SizedBox(
                width: 34,
                height: 34,
                child: IconButton(
                  onPressed: () => _removeItem(item),
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: S.delete,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Status {
  ok,
  due,
  overdue;

  String get label {
    switch (this) {
      case _Status.ok:
        return S.statusOk;
      case _Status.due:
        return S.statusDue;
      case _Status.overdue:
        return S.statusOverdue;
    }
  }
}

// ── Bottom sheet for adding items ──

class _AddItemResult {
  final String typeId;
  final String name;
  final int intervalKm;
  final int intervalMonths;
  _AddItemResult({required this.typeId, required this.name, required this.intervalKm, required this.intervalMonths});
}

class _AddItemSheet extends StatefulWidget {
  final List availableTypes;
  const _AddItemSheet({required this.availableTypes});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  bool _showCustom = false;
  final _nameCtrl = TextEditingController();
  final _kmCtrl = TextEditingController(text: '5000');
  final _monthsCtrl = TextEditingController(text: '6');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _kmCtrl.dispose();
    _monthsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: _showCustom ? _buildCustomForm(cs, tt) : _buildTypeList(cs, tt),
      ),
    );
  }

  Widget _buildTypeList(ColorScheme cs, TextTheme tt) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.onSurfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text(S.addItem, style: tt.titleMedium),
        const SizedBox(height: 12),

        if (widget.availableTypes.isNotEmpty)
          ...widget.availableTypes.map((t) => ListTile(
                leading: const Icon(Icons.build_outlined),
                title: Text(t.name),
                subtitle: Text('${t.defaultIntervalKm} km / ${t.defaultIntervalMonths} mo'),
                onTap: () => Navigator.pop(context, _AddItemResult(
                  typeId: t.id,
                  name: t.name,
                  intervalKm: t.defaultIntervalKm,
                  intervalMonths: t.defaultIntervalMonths,
                )),
              )),

        const Divider(),
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: Text(S.customItem),
          onTap: () => setState(() => _showCustom = true),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCustomForm(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.onSurfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(S.customItem, style: tt.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: S.name_,
              prefixIcon: const Icon(Icons.label_outline),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _kmCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: S.intervalKm,
              prefixIcon: const Icon(Icons.straighten),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _monthsCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: S.intervalMonths,
              prefixIcon: const Icon(Icons.calendar_month),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context, _AddItemResult(
                typeId: const Uuid().v4(),
                name: name,
                intervalKm: int.tryParse(_kmCtrl.text.trim()) ?? 5000,
                intervalMonths: int.tryParse(_monthsCtrl.text.trim()) ?? 6,
              ));
            },
            child: Text(S.add),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
