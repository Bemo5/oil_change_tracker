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
    int defaultIntervalKm = 5000,
    int defaultIntervalMonths = 6,
  }) async {
    final t = MaintenanceType(
      id: _uuid.v4(),
      name: name,
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

  Future<void> seedDefaults() async {
    if (_box().isNotEmpty) return;

    // ── زيوت وسوائل / Oils & Fluids ──
    await add(name: 'زيت المحرك / Engine Oil', defaultIntervalKm: 7000, defaultIntervalMonths: 6);
    await add(name: 'زيت الفتيس مانيول / Manual Trans. Oil', defaultIntervalKm: 50000, defaultIntervalMonths: 36);
    await add(name: 'زيت الفتيس أوتوماتيك / Auto Trans. Oil', defaultIntervalKm: 80000, defaultIntervalMonths: 48);
    await add(name: 'زيت الفرامل / Brake Fluid', defaultIntervalKm: 40000, defaultIntervalMonths: 24);
    await add(name: 'سائل التبريد / Coolant', defaultIntervalKm: 50000, defaultIntervalMonths: 30);
    await add(name: 'زيت الباور / Power Steering Fluid', defaultIntervalKm: 60000, defaultIntervalMonths: 36);
    await add(name: 'زيت الدفرنس / Differential Oil', defaultIntervalKm: 80000, defaultIntervalMonths: 48);
    await add(name: 'سائل المساحات / Washer Fluid', defaultIntervalKm: 5000, defaultIntervalMonths: 1);

    // ── فلاتر / Filters ──
    await add(name: 'فلتر زيت / Oil Filter', defaultIntervalKm: 7000, defaultIntervalMonths: 6);
    await add(name: 'فلتر هواء / Air Filter', defaultIntervalKm: 15000, defaultIntervalMonths: 12);
    await add(name: 'فلتر بنزين / Fuel Filter', defaultIntervalKm: 30000, defaultIntervalMonths: 24);
    await add(name: 'فلتر تكييف / Cabin Filter', defaultIntervalKm: 15000, defaultIntervalMonths: 12);

    // ── نظام الاشتعال / Ignition ──
    await add(name: 'بوجيهات عادية / Spark Plugs', defaultIntervalKm: 25000, defaultIntervalMonths: 18);
    await add(name: 'بوجيهات إيريديوم / Iridium Plugs', defaultIntervalKm: 80000, defaultIntervalMonths: 48);
    await add(name: 'كويلات / Ignition Coils', defaultIntervalKm: 100000, defaultIntervalMonths: 60);
    await add(name: 'أسلاك بوجيهات / Plug Wires', defaultIntervalKm: 80000, defaultIntervalMonths: 48);

    // ── نظام الفرامل / Brakes ──
    await add(name: 'تيل فرامل أمامي / Front Brake Pads', defaultIntervalKm: 30000, defaultIntervalMonths: 24);
    await add(name: 'طنابير / Brake Discs', defaultIntervalKm: 70000, defaultIntervalMonths: 48);
    await add(name: 'تيل خلفي / Rear Drum Shoes', defaultIntervalKm: 50000, defaultIntervalMonths: 36);

    // ── الإطارات والعفشة / Tires & Suspension ──
    await add(name: 'كاوتش / Tires', defaultIntervalKm: 50000, defaultIntervalMonths: 42);
    await add(name: 'مساعدين / Shock Absorbers', defaultIntervalKm: 75000, defaultIntervalMonths: 48);
    await add(name: 'بلي عجل / Wheel Bearings', defaultIntervalKm: 120000, defaultIntervalMonths: 72);
    await add(name: 'جلب ومقصات / Bushings & Arms', defaultIntervalKm: 100000, defaultIntervalMonths: 60);
    await add(name: 'تيش ودراعات / Tie Rods', defaultIntervalKm: 80000, defaultIntervalMonths: 48);

    // ── الكهرباء / Electrical ──
    await add(name: 'بطارية / Battery', defaultIntervalKm: 50000, defaultIntervalMonths: 30);
    await add(name: 'لمبات / Bulbs', defaultIntervalKm: 30000, defaultIntervalMonths: 18);
    await add(name: 'سير الدينامو / Alternator Belt', defaultIntervalKm: 50000, defaultIntervalMonths: 36);

    // ── السيور / Belts ──
    await add(name: 'سير الكاتينة / Timing Belt', defaultIntervalKm: 80000, defaultIntervalMonths: 48);
    await add(name: 'سير المجموعة / Serpentine Belt', defaultIntervalKm: 50000, defaultIntervalMonths: 36);
    await add(name: 'شداد السير / Belt Tensioner', defaultIntervalKm: 80000, defaultIntervalMonths: 48);

    // ── نظام التبريد / Cooling System ──
    await add(name: 'خراطيم المياه / Coolant Hoses', defaultIntervalKm: 100000, defaultIntervalMonths: 54);
    await add(name: 'ترموستات / Thermostat', defaultIntervalKm: 90000, defaultIntervalMonths: 54);
    await add(name: 'طلمبة مياه / Water Pump', defaultIntervalKm: 120000, defaultIntervalMonths: 72);
    await add(name: 'مروحة الردياتير / Radiator Fan', defaultIntervalKm: 120000, defaultIntervalMonths: 72);

    // ── أخرى / Other ──
    await add(name: 'مساحات زجاج / Wiper Blades', defaultIntervalKm: 15000, defaultIntervalMonths: 9);
    await add(name: 'طقم دبرياج / Clutch Kit', defaultIntervalKm: 120000, defaultIntervalMonths: 72);
    await add(name: 'قواعد موتور وفتيس / Engine Mounts', defaultIntervalKm: 120000, defaultIntervalMonths: 72);
    await add(name: 'جوانات وأويل سيلات / Gaskets & Seals', defaultIntervalKm: 100000, defaultIntervalMonths: 60);
  }
}
