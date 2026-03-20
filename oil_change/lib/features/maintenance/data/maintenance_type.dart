class MaintenanceType {
  final String id;
  final String name;
  final int defaultIntervalKm;
  final int defaultIntervalMonths;

  const MaintenanceType({
    required this.id,
    required this.name,
    this.defaultIntervalKm = 5000,
    this.defaultIntervalMonths = 6,
  });

  MaintenanceType copyWith({
    String? name,
    int? defaultIntervalKm,
    int? defaultIntervalMonths,
  }) {
    return MaintenanceType(
      id: id,
      name: name ?? this.name,
      defaultIntervalKm: defaultIntervalKm ?? this.defaultIntervalKm,
      defaultIntervalMonths: defaultIntervalMonths ?? this.defaultIntervalMonths,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'defaultIntervalKm': defaultIntervalKm,
        'defaultIntervalMonths': defaultIntervalMonths,
      };

  static MaintenanceType fromMap(Map map) => MaintenanceType(
        id: (map['id'] ?? '') as String,
        name: (map['name'] ?? '') as String,
        defaultIntervalKm: (map['defaultIntervalKm'] ?? 5000) as int,
        defaultIntervalMonths: (map['defaultIntervalMonths'] ?? 6) as int,
      );
}
