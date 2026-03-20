class Vehicle {
  final String id;
  final String name;

  /// Baseline for oil interval (odometer at LAST oil change)
  final int savedOdometerKm;

  /// Latest known odometer you saved
  final int currentOdometerKm;

  /// km-based interval (REAL due)
  final int defaultIntervalKm;

  /// time suggestion only (NOT due rule)
  final int timeSuggestionMonths;

  /// optional image path (local file)
  final String? photoPath;

  const Vehicle({
    required this.id,
    required this.name,
    required this.savedOdometerKm,
    required this.currentOdometerKm,
    this.defaultIntervalKm = 5000,
    this.timeSuggestionMonths = 6,
    this.photoPath,
  });

  Vehicle copyWith({
    String? name,
    int? savedOdometerKm,
    int? currentOdometerKm,
    int? defaultIntervalKm,
    int? timeSuggestionMonths,
    String? photoPath,
  }) {
    return Vehicle(
      id: id,
      name: name ?? this.name,
      savedOdometerKm: savedOdometerKm ?? this.savedOdometerKm,
      currentOdometerKm: currentOdometerKm ?? this.currentOdometerKm,
      defaultIntervalKm: defaultIntervalKm ?? this.defaultIntervalKm,
      timeSuggestionMonths: timeSuggestionMonths ?? this.timeSuggestionMonths,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'savedOdometerKm': savedOdometerKm,
        'currentOdometerKm': currentOdometerKm,
        'defaultIntervalKm': defaultIntervalKm,
        'timeSuggestionMonths': timeSuggestionMonths,
        'photoPath': photoPath,
      };

  static Vehicle fromMap(Map map) {
    final int lastOil = (map['savedOdometerKm'] ?? 0) as int;
    final int current = (map['currentOdometerKm'] ?? lastOil) as int;

    return Vehicle(
      id: (map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      savedOdometerKm: lastOil,
      currentOdometerKm: current,
      defaultIntervalKm: (map['defaultIntervalKm'] ?? 5000) as int,
      timeSuggestionMonths: (map['timeSuggestionMonths'] ?? 6) as int,
      photoPath: map['photoPath'] as String?,
    );
  }
}
