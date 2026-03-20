import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/vehicle_repo.dart';

class VehicleFormPage extends StatefulWidget {
  const VehicleFormPage({super.key});

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  final _kmCtrl = TextEditingController(text: '5000');
  final _monthsCtrl = TextEditingController(text: '6');

  String? _photoPath;
  final VehicleRepo _repo = VehicleRepo();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _odometerCtrl.dispose();
    _kmCtrl.dispose();
    _monthsCtrl.dispose();
    super.dispose();
  }

  int _parseInt(String s, int fallback) => int.tryParse(s.trim()) ?? fallback;

  Future<String?> _copyPickedImageToAppFolder(String pickedPath) async {
    try {
      final src = File(pickedPath);
      if (!await src.exists()) return null;

      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(dir.path, 'oil_change', 'vehicle_photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final ext = p.extension(pickedPath).toLowerCase();
      final safeExt = (ext.isEmpty) ? '.jpg' : ext;

      final filename = 'car_${DateTime.now().millisecondsSinceEpoch}$safeExt';
      final destPath = p.join(photosDir.path, filename);

      final copied = await src.copy(destPath);
      return copied.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final pickedPath = result.files.single.path;
    if (pickedPath == null) return;

    final copiedPath = await _copyPickedImageToAppFolder(pickedPath);

    if (!mounted) return;
    setState(() {
      // if copy fails, still try original path (but copy is preferred)
      _photoPath = copiedPath ?? pickedPath;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await _repo.add(
      name: _nameCtrl.text.trim(),
      initialOdometerKm: _parseInt(_odometerCtrl.text, 0),
      defaultIntervalKm: _parseInt(_kmCtrl.text, 5000),
      timeSuggestionMonths: _parseInt(_monthsCtrl.text, 6),
      photoPath: _photoPath,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add vehicle'),
        leading: const Icon(Icons.directions_car),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Photo picker row (clean)
              Row(
                children: [
                  InkWell(
                    borderRadius: radius,
                    onTap: _pickPhoto,
                    child: Ink(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      child: _photoPath != null && File(_photoPath!).existsSync()
                          ? ClipRRect(
                              borderRadius: radius,
                              child: Image.file(
                                File(_photoPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                              ),
                            )
                          : const Icon(Icons.add_a_photo, size: 30),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Add a car photo (optional).\nThis helps the list look nicer.',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Vehicle name',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _odometerCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current mileage (km)',
                  prefixIcon: Icon(Icons.speed),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter mileage';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _kmCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Oil interval (km)',
                  prefixIcon: Icon(Icons.route),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _monthsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Time suggestion (months)',
                  prefixIcon: Icon(Icons.calendar_month),
                ),
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
