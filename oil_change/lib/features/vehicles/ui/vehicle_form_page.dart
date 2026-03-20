import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../l10n.dart';
import '../../../platform_utils.dart' as pu;
import '../data/vehicle.dart';
import '../data/vehicle_repo.dart';
import '../../maintenance/data/maintenance_type_repo.dart';
import '../../maintenance/data/maintenance_item_repo.dart';

// Conditional import for file copy logic
import 'vehicle_form_io.dart' if (dart.library.html) 'vehicle_form_web.dart' as form_platform;

class VehicleFormPage extends StatefulWidget {
  final Vehicle? vehicle;
  const VehicleFormPage({super.key, this.vehicle});

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();

  String? _photoPath;
  final VehicleRepo _repo = VehicleRepo();

  bool get _isEdit => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    if (v != null) {
      _nameCtrl.text = v.name;
      _odometerCtrl.text = v.currentOdometerKm.toString();
      _photoPath = v.photoPath;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _odometerCtrl.dispose();
    super.dispose();
  }

  int _parseInt(String s, int fallback) => int.tryParse(s.trim()) ?? fallback;

  Future<void> _pickPhoto() async {
    if (kIsWeb) return; // Photos not supported on web

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final pickedPath = result.files.single.path;
    if (pickedPath == null) return;

    final copiedPath = await form_platform.copyPickedImage(pickedPath);

    if (!mounted) return;
    setState(() {
      _photoPath = copiedPath ?? pickedPath;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isEdit) {
      final updated = widget.vehicle!.copyWith(
        name: _nameCtrl.text.trim(),
        currentOdometerKm: _parseInt(_odometerCtrl.text, 0),
        photoPath: _photoPath,
      );
      await _repo.update(updated);
    } else {
      final odometer = _parseInt(_odometerCtrl.text, 0);
      final vehicle = await _repo.add(
        name: _nameCtrl.text.trim(),
        initialOdometerKm: odometer,
        photoPath: _photoPath,
      );

      final types = MaintenanceTypeRepo().getAllSync();
      await MaintenanceItemRepo().addAllTypesForVehicle(
        vehicle.id,
        odometer,
        types,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final hasPhoto = _photoPath != null && pu.fileExists(_photoPath!);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? S.editVehicle : S.addVehicle),
        leading: const Icon(Icons.directions_car),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (!kIsWeb)
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
                        child: hasPhoto
                            ? ClipRRect(
                                borderRadius: radius,
                                child: pu.fileImage(
                                  _photoPath!,
                                  fit: BoxFit.cover,
                                  fallback: () => const Icon(Icons.image_not_supported),
                                ),
                              )
                            : const Icon(Icons.add_a_photo, size: 30),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(S.photoOptional),
                    ),
                  ],
                ),

              if (!kIsWeb) const SizedBox(height: 18),

              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: S.vehicleName,
                  prefixIcon: const Icon(Icons.badge),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? S.enterName : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _odometerCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: S.currentMileageKm,
                  prefixIcon: const Icon(Icons.speed),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return S.enterMileage;
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0) return S.enterValidNumber;
                  return null;
                },
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(_isEdit ? S.updateVehicle : S.saveVehicle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
