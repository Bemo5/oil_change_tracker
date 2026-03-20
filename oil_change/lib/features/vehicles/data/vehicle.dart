class Vehicle {
  final String id;
  final String name;
  final int currentOdometerKm;
  final String? photoPath;

  const Vehicle({
    required this.id,
    required this.name,
    required this.currentOdometerKm,
    this.photoPath,
  });

  Vehicle copyWith({
    String? name,
    int? currentOdometerKm,
    String? photoPath,
  }) {
    return Vehicle(
      id: id,
      name: name ?? this.name,
      currentOdometerKm: currentOdometerKm ?? this.currentOdometerKm,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'currentOdometerKm': currentOdometerKm,
        'photoPath': photoPath,
      };

  /// Tolerant of old fields — ignores savedOdometerKm, defaultIntervalKm, etc.
  static Vehicle fromMap(Map map) {
    return Vehicle(
      id: (map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      currentOdometerKm: (map['currentOdometerKm'] ?? map['savedOdometerKm'] ?? 0) as int,
      photoPath: map['photoPath'] as String?,
    );
  }
}
