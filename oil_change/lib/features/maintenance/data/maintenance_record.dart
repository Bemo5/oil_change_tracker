class MaintenanceRecord {
  final String id;
  final String vehicleId;
  final String typeId;
  final String typeName;
  final int odometerKm;
  final DateTime date;
  final double? priceEgp;

  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.typeId,
    required this.typeName,
    required this.odometerKm,
    required this.date,
    this.priceEgp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicleId': vehicleId,
        'typeId': typeId,
        'typeName': typeName,
        'odometerKm': odometerKm,
        'date': date.toIso8601String(),
        'priceEgp': priceEgp,
      };

  static MaintenanceRecord fromMap(Map map) => MaintenanceRecord(
        id: (map['id'] ?? '') as String,
        vehicleId: (map['vehicleId'] ?? '') as String,
        typeId: (map['typeId'] ?? '') as String,
        typeName: (map['typeName'] ?? '') as String,
        odometerKm: (map['odometerKm'] ?? 0) as int,
        date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
        priceEgp: (map['priceEgp'] as num?)?.toDouble(),
      );
}
