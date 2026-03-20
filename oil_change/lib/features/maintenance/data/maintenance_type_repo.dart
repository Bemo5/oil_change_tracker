import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../vehicles/data/hive_boxes.dart';
import 'maintenance_type.dart';

class MaintenanceTypeRepo {
  final Uuid _uuid = const Uuid();

  Box<Map> _box() => HiveBoxes.maintenanceTypesBox();

  List<MaintenanceType> getAllSync() {
    return _box()
        .values
        .map((m) => MaintenanceType.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<MaintenanceType> add({
    required String name,
    String category = '',
    int defaultIntervalKm = 5000,
    int defaultIntervalMonths = 6,
  }) async {
    final t = MaintenanceType(
      id: _uuid.v4(),
      name: name,
      category: category,
      defaultIntervalKm: defaultIntervalKm,
      defaultIntervalMonths: defaultIntervalMonths,
    );
    await _box().put(t.id, t.toMap());
    return t;
  }

  Future<void> update(MaintenanceType t) async {
    await _box().put(t.id, t.toMap());
  }

  Future<void> delete(String id) async {
    await _box().delete(id);
  }

  Future<void> clearAll() async => await _box().clear();

  Future<void> putAll(List<MaintenanceType> types) async {
    for (final t in types) {
      await _box().put(t.id, t.toMap());
    }
  }

  static const _catOils = 'زيوت وسوائل / Oils & Fluids';
  static const _catFilters = 'فلاتر / Filters';
  static const _catIgnition = 'نظام الاشتعال / Ignition';
  static const _catBrakes = 'فرامل / Brakes';
  static const _catSuspension = 'إطارات وعفشة / Tires & Suspension';
  static const _catElectrical = 'كهرباء وسيور / Electrical & Belts';
  static const _catCooling = 'نظام التبريد / Cooling';
  static const _catOther = 'أخرى / Other';

  Future<void> seedDefaults() async {
    if (_box().isNotEmpty) return;

    // ── زيوت وسوائل ──
    await add(name: 'زيت المحرك / Engine Oil', category: _catOils, defaultIntervalKm: 7000, defaultIntervalMonths: 6);
    await add(name: 'زيت الفتيس مانيول / Manual Trans.', category: _catOils, defaultIntervalKm: 50000, defaultIntervalMonths: 36);
    await add(name: 'زيت الفتيس أوتوماتيك / Auto Trans.', category: _catOils, defaultIntervalKm: 80000, defaultIntervalMonths: 48);
    await add(name: 'زيت الفرامل / Brake Fluid', category: _catOils, defaultIntervalKm: 40000, defaultIntervalMonths: 24);
    await add(name: 'سائل التبريد / Coolant', category: _catOils, defaultIntervalKm: 50000, defaultIntervalMonths: 30);
    await add(name: 'زيت الباور / Power Steering', category: _catOils, defaultIntervalKm: 60000, defaultIntervalMonths: 36);
    await add(name: 'زيت الدفرنس / Differential Oil', category: _catOils, defaultIntervalKm: 80000, defaultIntervalMonths: 48);
    await add(name: 'سائل المساحات / Washer Fluid', category: _catOils, defaultIntervalKm: 5000, defaultIntervalMonths: 1);

    // ── فلاتر ──
    await add(name: 'فلتر زيت / Oil Filter', category: _catFilters, defaultIntervalKm: 7000, defaultIntervalMonths: 6);
    await add(name: 'فلتر هواء / Air Filter', category: _catFilters, defaultIntervalKm: 15000, defaultIntervalMonths: 12);
    await add(name: 'فلتر بنزين / Fuel Filter', category: _catFilters, defaultIntervalKm: 30000, defaultIntervalMonths: 24);
    await add(name: 'فلتر تكييف / Cabin Filter', category: _catFilters, defaultIntervalKm: 15000, defaultIntervalMonths: 12);

    // ── نظام الاشتعال ──
    await add(name: 'بوجيهات عادية / Spark Plugs', category: _catIgnition, defaultIntervalKm: 25000, defaultIntervalMonths: 18);
    await add(name: 'بوجيهات إيريديوم / Iridium Plugs', category: _catIgnition, defaultIntervalKm: 80000, defaultIntervalMonths: 48);
    await add(name: 'كويلات / Ignition Coils', category: _catIgnition, defaultIntervalKm: 100000, defaultIntervalMonths: 60);
    await add(name: 'أسلاك بوجيهات / Plug Wires', category: _catIgnition, defaultIntervalKm: 80000, defaultIntervalMonths: 48);

    // ── فرامل ──
    await add(name: 'تيل فرامل أمامي / Front Brake Pads', category: _catBrakes, defaultIntervalKm: 30000, defaultIntervalMonths: 24);
    await add(name: 'طنابير / Brake Discs', category: _catBrakes, defaultIntervalKm: 70000, defaultIntervalMonths: 48);
    await add(name: 'تيل خلفي / Rear Drum Shoes', category: _catBrakes, defaultIntervalKm: 50000, defaultIntervalMonths: 36);

    // ── إطارات وعفشة ──
    await add(name: 'كاوتش / Tires', category: _catSuspension, defaultIntervalKm: 50000, defaultIntervalMonths: 42);
    await add(name: 'مساعدين / Shock Absorbers', category: _catSuspension, defaultIntervalKm: 75000, defaultIntervalMonths: 48);
    await add(name: 'بلي عجل / Wheel Bearings', category: _catSuspension, defaultIntervalKm: 120000, defaultIntervalMonths: 72);
    await add(name: 'جلب ومقصات / Bushings & Arms', category: _catSuspension, defaultIntervalKm: 100000, defaultIntervalMonths: 60);
    await add(name: 'تيش ودراعات / Tie Rods', category: _catSuspension, defaultIntervalKm: 80000, defaultIntervalMonths: 48);

    // ── كهرباء وسيور ──
    await add(name: 'بطارية / Battery', category: _catElectrical, defaultIntervalKm: 50000, defaultIntervalMonths: 30);
    await add(name: 'لمبات / Bulbs', category: _catElectrical, defaultIntervalKm: 30000, defaultIntervalMonths: 18);
    await add(name: 'سير الدينامو / Alternator Belt', category: _catElectrical, defaultIntervalKm: 50000, defaultIntervalMonths: 36);
    await add(name: 'سير الكاتينة / Timing Belt', category: _catElectrical, defaultIntervalKm: 80000, defaultIntervalMonths: 48);
    await add(name: 'سير المجموعة / Serpentine Belt', category: _catElectrical, defaultIntervalKm: 50000, defaultIntervalMonths: 36);
    await add(name: 'شداد السير / Belt Tensioner', category: _catElectrical, defaultIntervalKm: 80000, defaultIntervalMonths: 48);

    // ── نظام التبريد ──
    await add(name: 'خراطيم المياه / Coolant Hoses', category: _catCooling, defaultIntervalKm: 100000, defaultIntervalMonths: 54);
    await add(name: 'ترموستات / Thermostat', category: _catCooling, defaultIntervalKm: 90000, defaultIntervalMonths: 54);
    await add(name: 'طلمبة مياه / Water Pump', category: _catCooling, defaultIntervalKm: 120000, defaultIntervalMonths: 72);
    await add(name: 'مروحة الردياتير / Radiator Fan', category: _catCooling, defaultIntervalKm: 120000, defaultIntervalMonths: 72);

    // ── أخرى ──
    await add(name: 'مساحات زجاج / Wiper Blades', category: _catOther, defaultIntervalKm: 15000, defaultIntervalMonths: 9);
    await add(name: 'طقم دبرياج / Clutch Kit', category: _catOther, defaultIntervalKm: 120000, defaultIntervalMonths: 72);
    await add(name: 'قواعد موتور وفتيس / Engine Mounts', category: _catOther, defaultIntervalKm: 120000, defaultIntervalMonths: 72);
    await add(name: 'جوانات وأويل سيلات / Gaskets & Seals', category: _catOther, defaultIntervalKm: 100000, defaultIntervalMonths: 60);
  }
}
