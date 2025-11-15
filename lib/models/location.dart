/// Location model representing a geographic location
class Location {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? type; // city, district, state, country
  final Map<String, double>? riskScores; // disaster type -> risk score (0-1)

  Location({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.type,
    this.riskScores,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      type: json['type'],
      riskScores: json['risk_scores'] != null
          ? Map<String, double>.from(json['risk_scores'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'risk_scores': riskScores,
    };
  }

  /// Get overall risk level (0-1)
  double get overallRisk {
    if (riskScores == null || riskScores!.isEmpty) return 0.0;
    
    final values = riskScores!.values;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Get risk level as string
  String get riskLevel {
    final risk = overallRisk;
    if (risk < 0.3) return 'Low';
    if (risk < 0.6) return 'Medium';
    if (risk < 0.8) return 'High';
    return 'Critical';
  }

  Location copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? type,
    Map<String, double>? riskScores,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      riskScores: riskScores ?? this.riskScores,
    );
  }
}
