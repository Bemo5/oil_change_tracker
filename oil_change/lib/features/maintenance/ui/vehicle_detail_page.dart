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
import '../data/maintenance_type.dart';
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

  // Track which categories are expanded
  final Set<String> _expanded = {};

  static const _categoryOrder = [
    'زيوت وسوائل / Oils & Fluids',
    'فلاتر / Filters',
    'نظام الاشتعال / Ignition',
    'فرامل / Brakes',
    'إطارات وعفشة / Tires & Suspension',
    'كهرباء وسيور / Electrical & Belts',
    'نظام التبريد / Cooling',
    'أخرى / Other',
  ];

  static const _catIcons = <String, IconData>{
    'زيوت وسوائل / Oils & Fluids': Icons.water_drop,
    'فلاتر / Filters': Icons.filter_alt,
    'نظام الاشتعال / Ignition': Icons.bolt,
    'فرامل / Brakes': Icons.do_not_touch,
    'إطارات وعفشة / Tires & Suspension': Icons.tire_repair,
    'كهرباء وسيور / Electrical & Belts': Icons.electrical_services,
    'نظام التبريد / Cooling': Icons.ac_unit,
    'أخرى / Other': Icons.build,
  };

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

  // ── Add item ──

  Future<void> _addItem() async {
    final existingItems = _itemRepo.getForVehicle(_vehicle.id);
    final existingTypeIds = existingItems.map((i) => i.typeId).toSet();
    final allTypes = _typeRepo.getAllSync();
    final availableTypes = allTypes.where((t) => !existingTypeIds.contains(t.id)).toList();

    if (!mounted) return;

    final result = await showModalBottomSheet<_AddItemResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => _AddItemSheet(
          availableTypes: availableTypes,
          scrollController: scrollCtrl,
        ),
      ),
    );

    if (result == null) return;

    await _itemRepo.addForVehicle(
      vehicleId: _vehicle.id,
      typeId: result.typeId,
      typeName: result.name,
      category: result.category,
      intervalKm: result.intervalKm,
      intervalMonths: result.intervalMonths,
      savedOdometerKm: _vehicle.currentOdometerKm,
    );
    // Auto-expand the category of the newly added item
    _expanded.add(result.category.isEmpty ? 'أخرى / Other' : result.category);
    setState(() {});
  }

  // ── Remove item ──

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
        title: Text('${item.typeName}\n${S.editInterval}'),
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
          TextButton(onPressed: () => Navigator.pop(ctx, -1.0), child: Text(S.skip)),
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

  int _remainingKm(MaintenanceItem item) =>
      (item.savedOdometerKm + item.intervalKm) - _vehicle.currentOdometerKm;

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
      case _Status.ok: return Colors.green;
      case _Status.due: return Colors.amber;
      case _Status.overdue: return Colors.red;
    }
  }

  // ── Group items by category ──

  Map<String, List<MaintenanceItem>> _groupByCategory(List<MaintenanceItem> items) {
    final map = <String, List<MaintenanceItem>>{};
    for (final item in items) {
      final cat = item.category.isEmpty ? 'أخرى / Other' : item.category;
      map.putIfAbsent(cat, () => []).add(item);
    }
    // Sort items alphabetically within each category
    for (final list in map.values) {
      list.sort((a, b) => a.typeName.compareTo(b.typeName));
    }
    return map;
  }

  // Category summary: count overdue/due
  _CatSummary _catSummary(List<MaintenanceItem> items) {
    int overdue = 0, due = 0;
    for (final item in items) {
      final s = _status(item);
      if (s == _Status.overdue) overdue++;
      else if (s == _Status.due) due++;
    }
    return _CatSummary(overdue: overdue, due: due, total: items.length);
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemRepo.getForVehicle(_vehicle.id);
    final history = _recordRepo.getForVehicle(_vehicle.id);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final grouped = _groupByCategory(items);

    // Sort categories in defined order
    final sortedCats = _categoryOrder.where((c) => grouped.containsKey(c)).toList();
    // Add any categories not in the predefined order
    for (final c in grouped.keys) {
      if (!sortedCats.contains(c)) sortedCats.add(c);
    }

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

          const SizedBox(height: 20),
          Text(S.checklist, style: tt.titleMedium),
          const SizedBox(height: 8),

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
            ...sortedCats.map((cat) {
              final catItems = grouped[cat]!;
              final summary = _catSummary(catItems);
              final isOpen = _expanded.contains(cat);
              final icon = _catIcons[cat] ?? Icons.build;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF111A33),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.15)),
                ),
                child: Column(
                  children: [
                    // Category header — tap to expand/collapse
                    InkWell(
                      borderRadius: isOpen
                          ? const BorderRadius.vertical(top: Radius.circular(14))
                          : BorderRadius.circular(14),
                      onTap: () => setState(() {
                        if (isOpen) {
                          _expanded.remove(cat);
                        } else {
                          _expanded.add(cat);
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(icon, size: 20, color: cs.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                cat,
                                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            // Status badges
                            if (summary.overdue > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${summary.overdue}',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 11)),
                              ),
                              const SizedBox(width: 4),
                            ],
                            if (summary.due > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${summary.due}',
                                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w800, fontSize: 11)),
                              ),
                              const SizedBox(width: 4),
                            ],
                            if (summary.overdue == 0 && summary.due == 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('OK',
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 11)),
                              ),
                            const SizedBox(width: 4),
                            Icon(
                              isOpen ? Icons.expand_less : Icons.expand_more,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expanded items
                    if (isOpen) ...[
                      Divider(height: 1, color: cs.outlineVariant.withOpacity(0.15)),
                      ...catItems.map((item) => _buildCompactItem(item, cs, tt)),
                    ],
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),
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
                        Expanded(child: Text(r.typeName, style: tt.bodyMedium)),
                        if (r.priceEgp != null)
                          Text('${r.priceEgp!.toStringAsFixed(0)} EGP',
                              style: tt.bodySmall?.copyWith(color: cs.primary)),
                        if (r.priceEgp != null) const SizedBox(width: 10),
                        Text('${r.odometerKm} km',
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        const SizedBox(width: 10),
                        Text(DateFormat('d MMM yy').format(r.date),
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  // ── Compact item tile inside a category dropdown ──

  Widget _buildCompactItem(MaintenanceItem item, ColorScheme cs, TextTheme tt) {
    final remaining = _remainingKm(item);
    final s = _status(item);
    final sColor = _statusColor(s);
    final progress = _progressUsed(item);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + status + actions
          Row(
            children: [
              Expanded(
                child: Text(item.typeName,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: sColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(s.label,
                    style: TextStyle(color: sColor, fontWeight: FontWeight.w800, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: progress,
              color: sColor,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 4),

          // Info row
          Row(
            children: [
              Text(
                remaining >= 0 ? S.kmLeft(remaining) : S.kmOverdue(remaining.abs()),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
              ),
              const Spacer(),
              if (item.lastServiceDate != null)
                Text(DateFormat('d MMM yy').format(item.lastServiceDate!),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 30,
                  child: FilledButton(
                    onPressed: () => _markDone(item),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      textStyle: tt.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    child: Text(S.done),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 30, height: 30,
                child: IconButton(
                  onPressed: () => _editInterval(item),
                  icon: const Icon(Icons.tune, size: 16),
                  tooltip: S.editInterval,
                  padding: EdgeInsets.zero,
                ),
              ),
              SizedBox(
                width: 30, height: 30,
                child: IconButton(
                  onPressed: () => _removeItem(item),
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: S.delete,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),

          // Divider between items (not after last)
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

enum _Status {
  ok, due, overdue;

  String get label {
    switch (this) {
      case _Status.ok: return S.statusOk;
      case _Status.due: return S.statusDue;
      case _Status.overdue: return S.statusOverdue;
    }
  }
}

class _CatSummary {
  final int overdue, due, total;
  const _CatSummary({required this.overdue, required this.due, required this.total});
}

// ── Add item result ──

class _AddItemResult {
  final String typeId;
  final String name;
  final String category;
  final int intervalKm;
  final int intervalMonths;
  _AddItemResult({required this.typeId, required this.name, this.category = '', required this.intervalKm, required this.intervalMonths});
}

// ── Categorized + searchable bottom sheet ──

class _AddItemSheet extends StatefulWidget {
  final List<MaintenanceType> availableTypes;
  final ScrollController scrollController;
  const _AddItemSheet({required this.availableTypes, required this.scrollController});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  String _query = '';
  bool _showCustom = false;
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _kmCtrl = TextEditingController(text: '5000');
  final _monthsCtrl = TextEditingController(text: '6');

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _kmCtrl.dispose();
    _monthsCtrl.dispose();
    super.dispose();
  }

  List<MaintenanceType> get _filtered {
    if (_query.isEmpty) return widget.availableTypes;
    final q = _query.toLowerCase();
    return widget.availableTypes.where((t) =>
        t.name.toLowerCase().contains(q) ||
        t.category.toLowerCase().contains(q)).toList();
  }

  Map<String, List<MaintenanceType>> get _grouped {
    final map = <String, List<MaintenanceType>>{};
    for (final t in _filtered) {
      final cat = t.category.isEmpty ? 'أخرى / Other' : t.category;
      map.putIfAbsent(cat, () => []).add(t);
    }
    return map;
  }

  static const _catIcons = <String, IconData>{
    'زيوت وسوائل / Oils & Fluids': Icons.water_drop,
    'فلاتر / Filters': Icons.filter_alt,
    'نظام الاشتعال / Ignition': Icons.bolt,
    'فرامل / Brakes': Icons.do_not_touch,
    'إطارات وعفشة / Tires & Suspension': Icons.tire_repair,
    'كهرباء وسيور / Electrical & Belts': Icons.electrical_services,
    'نظام التبريد / Cooling': Icons.ac_unit,
    'أخرى / Other': Icons.build,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_showCustom) return _buildCustomForm(cs, tt);

    final grouped = _grouped;

    return Column(
      children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: cs.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 12),
        Text(S.addItem, style: tt.titleMedium),
        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: S.search,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            children: [
              ...grouped.entries.expand((entry) => [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                  child: Row(
                    children: [
                      Icon(_catIcons[entry.key] ?? Icons.build, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(entry.key, style: tt.labelLarge?.copyWith(
                          color: cs.primary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                ...entry.value.map((t) => ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(t.name, style: tt.bodyMedium),
                  subtitle: Text('${t.defaultIntervalKm} كم / ${t.defaultIntervalMonths} شهر',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  onTap: () => Navigator.pop(context, _AddItemResult(
                    typeId: t.id,
                    name: t.name,
                    category: t.category,
                    intervalKm: t.defaultIntervalKm,
                    intervalMonths: t.defaultIntervalMonths,
                  )),
                )),
              ]),

              const Divider(height: 24),
              ListTile(
                leading: Icon(Icons.add_circle_outline, color: cs.primary),
                title: Text(S.customItem, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                onTap: () => setState(() => _showCustom = true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomForm(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: cs.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showCustom = false),
              ),
              Text(S.customItem, style: tt.titleMedium),
            ],
          ),
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
        ],
      ),
    );
  }
}
