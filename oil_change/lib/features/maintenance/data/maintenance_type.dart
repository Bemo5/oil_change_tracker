class MaintenanceType {
  final String id;
  final String name;
  final String category;
  final int defaultIntervalKm;
  final int defaultIntervalMonths;

  const MaintenanceType({
    required this.id,
    required this.name,
    this.category = '',
    this.defaultIntervalKm = 5000,
    this.defaultIntervalMonths = 6,
  });

  MaintenanceType copyWith({
    String? name,
    String? category,
    int? defaultIntervalKm,
    int? defaultIntervalMonths,
  }) {
    return MaintenanceType(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      defaultIntervalKm: defaultIntervalKm ?? this.defaultIntervalKm,
      defaultIntervalMonths: defaultIntervalMonths ?? this.defaultIntervalMonths,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'defaultIntervalKm': defaultIntervalKm,
        'defaultIntervalMonths': defaultIntervalMonths,
      };

  static MaintenanceType fromMap(Map map) => MaintenanceType(
        id: (map['id'] ?? '') as String,
        name: (map['name'] ?? '') as String,
        category: (map['category'] ?? '') as String,
        defaultIntervalKm: (map['defaultIntervalKm'] ?? 5000) as int,
        defaultIntervalMonths: (map['defaultIntervalMonths'] ?? 6) as int,
      );
}
