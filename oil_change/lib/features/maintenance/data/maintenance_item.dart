class MaintenanceItem {
  final String id;
  final String vehicleId;
  final String typeId;
  final String typeName;
  final String category;
  final int intervalKm;
  final int intervalMonths;
  final int savedOdometerKm;
  final DateTime? lastServiceDate;
  final double? lastPriceEgp;

  const MaintenanceItem({
    required this.id,
    required this.vehicleId,
    required this.typeId,
    required this.typeName,
    this.category = '',
    this.intervalKm = 5000,
    this.intervalMonths = 6,
    this.savedOdometerKm = 0,
    this.lastServiceDate,
    this.lastPriceEgp,
  });

  MaintenanceItem copyWith({
    String? typeName,
    String? category,
    int? intervalKm,
    int? intervalMonths,
    int? savedOdometerKm,
    DateTime? lastServiceDate,
    double? lastPriceEgp,
  }) {
    return MaintenanceItem(
      id: id,
      vehicleId: vehicleId,
      typeId: typeId,
      typeName: typeName ?? this.typeName,
      category: category ?? this.category,
      intervalKm: intervalKm ?? this.intervalKm,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      savedOdometerKm: savedOdometerKm ?? this.savedOdometerKm,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      lastPriceEgp: lastPriceEgp ?? this.lastPriceEgp,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicleId': vehicleId,
        'typeId': typeId,
        'typeName': typeName,
        'category': category,
        'intervalKm': intervalKm,
        'intervalMonths': intervalMonths,
        'savedOdometerKm': savedOdometerKm,
        'lastServiceDate': lastServiceDate?.toIso8601String(),
        'lastPriceEgp': lastPriceEgp,
      };

  static MaintenanceItem fromMap(Map map) => MaintenanceItem(
        id: (map['id'] ?? '') as String,
        vehicleId: (map['vehicleId'] ?? '') as String,
        typeId: (map['typeId'] ?? '') as String,
        typeName: (map['typeName'] ?? '') as String,
        category: (map['category'] ?? '') as String,
        intervalKm: (map['intervalKm'] ?? 5000) as int,
        intervalMonths: (map['intervalMonths'] ?? 6) as int,
        savedOdometerKm: (map['savedOdometerKm'] ?? 0) as int,
        lastServiceDate: map['lastServiceDate'] != null
            ? DateTime.tryParse(map['lastServiceDate'] as String)
            : null,
        lastPriceEgp: (map['lastPriceEgp'] as num?)?.toDouble(),
      );
}
