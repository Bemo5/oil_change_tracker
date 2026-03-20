import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n.dart';
import '../../vehicles/data/vehicle.dart';
import '../../vehicles/data/vehicle_repo.dart';
import '../data/maintenance_item.dart';
import '../data/maintenance_item_repo.dart';
import '../data/maintenance_record_repo.dart';

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

  Future<void> _markDone(MaintenanceItem item) async {
    final priceCtrl = TextEditingController();
    final price = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${item.typeName} done'),
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

    if (price == null) return; // dialog dismissed

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
                    prefixIcon: Icon(Icons.speed),
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
              child: Text(S.noItems, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            )
          else
            ...items.map((item) => _buildItemTile(item, cs, tt)),

          const SizedBox(height: 28),
          Text(S.history, style: tt.titleMedium),
          const SizedBox(height: 10),

          if (history.isEmpty)
            Text(S.noHistory, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
          else
            ...history.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
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
          SizedBox(
            width: double.infinity,
            height: 34,
            child: OutlinedButton(
              onPressed: () => _markDone(item),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                textStyle: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              child: Text(S.done),
            ),
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
