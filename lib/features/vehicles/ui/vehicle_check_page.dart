import 'package:flutter/material.dart';
import '../data/vehicle.dart';
import '../data/vehicle_repo.dart';

class VehicleCheckPage extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleCheckPage({super.key, required this.vehicle});

  @override
  State<VehicleCheckPage> createState() => _VehicleCheckPageState();
}

class _VehicleCheckPageState extends State<VehicleCheckPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final VehicleRepo _repo = VehicleRepo();

  int? _current;
  int? _remaining; // positive = remaining, negative = overdue

  @override
  void initState() {
    super.initState();
    _currentCtrl.text = widget.vehicle.currentOdometerKm.toString();
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    super.dispose();
  }

  int _parse(String s) => int.tryParse(s.trim()) ?? 0;

  void _calc() {
    final current = _parse(_currentCtrl.text);
    final v = widget.vehicle;

    final dueAt = v.savedOdometerKm + v.defaultIntervalKm;
    final remaining = dueAt - current;

    setState(() {
      _current = current;
      _remaining = remaining;
    });
  }

  double _progressValue(Vehicle v, int current) {
    final interval = v.defaultIntervalKm <= 0 ? 1 : v.defaultIntervalKm;
    final used = (current - v.savedOdometerKm) / interval;
    return used.clamp(0.0, 1.0);
  }

  Color _barColor(Vehicle v, int current) {
    final interval = v.defaultIntervalKm <= 0 ? 1 : v.defaultIntervalKm;
    final remaining = (v.savedOdometerKm + interval) - current;

    if (remaining <= 0) return Colors.red;

    final ratioLeft = remaining / interval;
    if (ratioLeft > 0.70) return Colors.green;
    if (ratioLeft > 0.30) return Colors.amber;
    return Colors.red;
  }

  Future<void> _saveCurrentMileage() async {
    if (_current == null) return;

    final updated = widget.vehicle.copyWith(currentOdometerKm: _current);
    await _repo.update(updated);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _oilChanged() async {
    if (_current == null) return;

    final updated = widget.vehicle.copyWith(
      savedOdometerKm: _current,
      currentOdometerKm: _current,
    );

    await _repo.update(updated);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;

    final current = _current;
    final remaining = _remaining;

    return Scaffold(
      appBar: AppBar(title: Text(v.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Interval: ${v.defaultIntervalKm} km',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('Last oil change: ${v.savedOdometerKm} km'),
                    Text('Saved current: ${v.currentOdometerKm} km'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: TextFormField(
                controller: _currentCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter current mileage (km)',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter a number';
                  final n = int.tryParse(val.trim());
                  if (n == null || n < 0) return 'Enter a valid number';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),

            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) _calc();
              },
              child: const Text('Check'),
            ),

            const SizedBox(height: 16),

            if (current != null && remaining != null) ...[
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        remaining >= 0
                            ? 'Due in: $remaining km'
                            : 'Overdue by: ${remaining.abs()} km',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: _progressValue(v, current),
                          color: _barColor(v, current),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saveCurrentMileage,
                      child: const Text('Save current'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _oilChanged,
                      icon: const Icon(Icons.oil_barrel),
                      label: const Text('Oil changed'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
